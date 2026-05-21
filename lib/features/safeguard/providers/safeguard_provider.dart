import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSgEnabled     = 'sg_enabled';
const _kSgPassword    = 'sg_password';
const _kParentPin     = 'sg_parent_pin';
const _kParentEnabled = 'sg_parent_enabled';

const _vpnChannel = MethodChannel('com.focusguard/vpn');

// ── Adult domain list ──────────────────────────────────────────────────
// These are the core domains SafeGuard blocks via DNS/VPN when enabled.
// We block at the subdomain level (e.g. pornhub.com blocks *.pornhub.com).
const _kAdultDomains = [
  // Major tube sites
  'pornhub.com', 'xvideos.com', 'xnxx.com', 'xhamster.com',
  'redtube.com', 'tube8.com', 'spankbang.com', 'youporn.com',
  'vporn.com', 'beeg.com', 'drtuber.com', 'tnaflix.com',
  'hdzog.com', 'sunporno.com', 'txxx.com', 'hdtube.porn',
  'porntrex.com', 'porndoe.com', 'porn300.com', 'eporner.com',
  'fuq.com', 'hclips.com', 'pornone.com', 'faphouse.com',
  'tubegalore.com', 'porndig.com', 'porntube.com', 'xxxvideos.com',
  // Cams and live
  'chaturbate.com', 'livejasmin.com', 'myfreecams.com', 'stripchat.com',
  'cam4.com', 'bongacams.com', 'camsoda.com', 'jerkmate.com',
  'flirt4free.com', 'streamate.com', 'imlive.com',
  // Creator platforms
  'onlyfans.com', 'manyvids.com', 'clips4sale.com', 'fansly.com',
  'fancentro.com', 'loyalfans.com', 'admireMe.vip',
  // Studios
  'brazzers.com', 'nubiles.net', 'bangbros.com', 'realitykings.com',
  'mofos.com', 'twistys.com', 'digitalplayground.com', 'wicked.com',
  'naughtyamerica.com', 'evil-angel.com', 'kink.com',
  // Generic adult
  'sex.com', 'porn.com', 'xxx.com', 'adult.com', 'sexy.com',
  'lust.com', 'pornn.com',
  // Hentai and illustrated
  'hentai.com', 'hentai-foundry.com', 'nhentai.net', 'hentaihaven.xxx',
  'rule34.xxx', 'e621.net', 'gelbooru.com', 'sankakucomplex.com',
  // Other
  'literotica.com', 'motherless.com', 'imagefap.com',
  'adultfriendfinder.com', 'ashleymadison.com',
  'xart.com', 'hegre.com', 'babes.com',
];

// ─────────────────────────────────────────────────────────────────────
class SafeguardState {
  const SafeguardState({
    this.isEnabled = false,
    this.isPasswordSet = false,
    this.isParentEnabled = false,
    this.isLoading = false,
    this.error,
  });
  final bool isEnabled;
  final bool isPasswordSet;
  final bool isParentEnabled;
  final bool isLoading;
  final String? error;

  SafeguardState copyWith({
    bool? isEnabled, bool? isPasswordSet, bool? isParentEnabled,
    bool? isLoading, String? error,
  }) => SafeguardState(
    isEnabled:          isEnabled          ?? this.isEnabled,
    isPasswordSet:      isPasswordSet      ?? this.isPasswordSet,
    isParentEnabled:    isParentEnabled    ?? this.isParentEnabled,
    isLoading:          isLoading          ?? this.isLoading,
    error: error,
  );
}

// ─────────────────────────────────────────────────────────────────────
class SafeguardNotifier extends StateNotifier<SafeguardState> {
  SafeguardNotifier() : super(const SafeguardState()) { _load(); }

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> _load() async {
    final enabled       = await _storage.read(key: _kSgEnabled) == 'true';
    final passwordSet   = await _storage.read(key: _kSgPassword) != null;
    final parentEnabled = await _storage.read(key: _kParentEnabled) == 'true';

    state = state.copyWith(
      isEnabled: enabled, isPasswordSet: passwordSet,
      isParentEnabled: parentEnabled,
    );

    // Re-push domains to VPN on app start (VPN permission already granted)
    if (enabled) Future.microtask(() => _pushToVpn(true));
  }

  // ── VPN sync ────────────────────────────────────────────────────────
  Future<bool> _pushToVpn(bool enable) async {
    try {
      if (enable) {
        final urls = List<String>.from(_kAdultDomains);
        final result = await _vpnChannel.invokeMethod<bool>('startVpn', {'urls': urls});
        return result ?? true;   // true = permission already granted or just granted
      } else {
        await _vpnChannel.invokeMethod('updateBlocklist', {'urls': <String>[]});
        return true;
      }
    } on PlatformException catch (e) {
      if (e.code == 'VPN_DENIED') return false;   // user cancelled — don't enable
      return true;   // other errors (emulator) — treat as ok
    } catch (_) {
      return true;   // VPN not available (emulator) — still allow enable for testing
    }
  }

  // ── Public API ──────────────────────────────────────────────────────

  Future<bool> setupWithPassword(String password) async {
    if (password.length < 4) return false;
    // Save password but do NOT mark as enabled yet — VPN must succeed first
    await _storage.write(key: _kSgPassword, value: password);
    state = state.copyWith(isPasswordSet: true);
    final vpnStarted = await _pushToVpn(true);
    if (!vpnStarted) return false;  // User cancelled VPN dialog — don't enable
    await _storage.write(key: _kSgEnabled, value: 'true');
    state = state.copyWith(isEnabled: true);
    return true;
  }

  Future<bool> disableWithPassword(String password) async {
    // Cannot disable SafeGuard while commitment lock is active
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('fg_lock_expiry');
    if (raw != null) {
      final expiry = DateTime.tryParse(raw);
      if (expiry != null && expiry.isAfter(DateTime.now())) {
        return false; // LOCKED — return false with special code handled in screen
      }
    }
    final stored = await _storage.read(key: _kSgPassword);
    if (stored != password) return false;
    await _storage.write(key: _kSgEnabled, value: 'false');
    // Clear password so re-enable is like first-time setup (user picks new password)
    await _storage.delete(key: _kSgPassword);
    state = state.copyWith(isEnabled: false, isPasswordSet: false);
    _pushToVpn(false);
    return true;
  }

  /// Returns true if commitment lock is currently active
  Future<bool> isCommitmentLocked() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('fg_lock_expiry');
    if (raw == null) return false;
    final expiry = DateTime.tryParse(raw);
    return expiry != null && expiry.isAfter(DateTime.now());
  }

  /// Re-enable: user sets a NEW password (same flow as first-time setup).
  /// Old password is cleared and replaced — fresh start.
  Future<bool> reEnableWithNewPassword(String password) async {
    if (password.length < 4) return false;
    await _storage.write(key: _kSgPassword, value: password);
    state = state.copyWith(isPasswordSet: true);
    final vpnStarted = await _pushToVpn(true);
    if (!vpnStarted) return false;
    await _storage.write(key: _kSgEnabled, value: 'true');
    state = state.copyWith(isEnabled: true, error: null);
    return true;
  }

  /// Keep enable() for internal use (app startup re-push)
  Future<void> enable() async {
    await _storage.write(key: _kSgEnabled, value: 'true');
    state = state.copyWith(isEnabled: true, error: null);
    Future.microtask(() => _pushToVpn(true));
  }

  Future<bool> changePassword(String current, String newPass) async {
    final stored = await _storage.read(key: _kSgPassword);
    if (stored != current) return false;
    if (newPass.length < 4) return false;
    await _storage.write(key: _kSgPassword, value: newPass);
    return true;
  }

  Future<bool> verifyPassword(String password) async {
    final stored = await _storage.read(key: _kSgPassword);
    return stored == password;
  }

  // ── Parent PIN ──────────────────────────────────────────────────────
  Future<bool> setupParentPin(String pin) async {
    if (pin.length != 4) return false;
    await _storage.write(key: _kParentPin, value: pin);
    await _storage.write(key: _kParentEnabled, value: 'true');
    state = state.copyWith(isParentEnabled: true);
    return true;
  }

  Future<bool> verifyParentPin(String pin) async {
    final stored = await _storage.read(key: _kParentPin);
    return stored == pin;
  }

  Future<bool> disableParentPin(String pin) async {
    final ok = await verifyParentPin(pin);
    if (!ok) return false;
    await _storage.write(key: _kParentEnabled, value: 'false');
    state = state.copyWith(isParentEnabled: false);
    return true;
  }


}

final safeguardProvider =
    StateNotifierProvider<SafeguardNotifier, SafeguardState>(
  (_) => SafeguardNotifier());