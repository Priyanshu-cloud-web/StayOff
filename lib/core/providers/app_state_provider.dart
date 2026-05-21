import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kOnboardingDone   = 'fg_onboarding_done';
const _kRegistered       = 'fg_registered';
const _kPin              = 'fg_pin';
const _kUserName         = 'fg_user_name';
const _kSecurityQuestion = 'fg_security_question';
const _kSecurityAnswer   = 'fg_security_answer';

enum AppStartRoute { loading, onboarding, register, pinUnlock, home }

class AppUser {
  const AppUser({required this.name, this.securityQuestion});
  final String name;
  final String? securityQuestion;
}

class AppStateNotifier extends StateNotifier<AppStartRoute> {
  AppStateNotifier() : super(AppStartRoute.loading) { _init(); }

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  AppUser? currentUser;
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> _init() async {
    try {
      final prefs          = await _prefs;
      final onboardingDone = prefs.getBool(_kOnboardingDone) ?? false;
      final registered     = prefs.getBool(_kRegistered) ?? false;
      final pin            = await _storage.read(key: _kPin);

      if (!onboardingDone) {
        state = AppStartRoute.onboarding;
      } else if (!registered || pin == null) {
        state = AppStartRoute.register;
      } else {
        await _loadUser();
        state = AppStartRoute.pinUnlock;
      }
    } catch (_) {
      state = AppStartRoute.onboarding;
    }
  }

  Future<void> _loadUser() async {
    final prefs = await _prefs;
    currentUser = AppUser(
      name:             prefs.getString(_kUserName) ?? '',
      securityQuestion: prefs.getString(_kSecurityQuestion),
    );
  }

  Future<void> completeOnboarding() async {
    final prefs = await _prefs;
    await prefs.setBool(_kOnboardingDone, true);
    state = AppStartRoute.register;
  }

  Future<void> goBackToOnboarding() async => state = AppStartRoute.onboarding;

  /// Register — no email, security question only
  Future<void> register({
    required String name,
    required String pin,
    String? securityQuestion,
    String? securityAnswer,
    // Keep these for backwards compat but ignore recoveryEmail
    String? recoveryEmail,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_kUserName, name.trim());
    await _storage.write(key: _kPin, value: pin);
    if (securityQuestion != null && securityAnswer != null && securityAnswer.isNotEmpty) {
      await prefs.setString(_kSecurityQuestion, securityQuestion);
      await _storage.write(key: _kSecurityAnswer, value: securityAnswer.toLowerCase().trim());
    }
    await prefs.setBool(_kRegistered, true);
    currentUser = AppUser(name: name.trim(), securityQuestion: securityQuestion);
    state = AppStartRoute.home;
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _kPin);
    if (stored == pin) { state = AppStartRoute.home; return true; }
    return false;
  }

  Future<void> unlock() async => state = AppStartRoute.home;
  Future<void> lock()   async => state = AppStartRoute.pinUnlock;

  Future<bool> verifySecurityAnswer(String answer) async {
    final stored = await _storage.read(key: _kSecurityAnswer);
    return stored != null && stored == answer.toLowerCase().trim();
  }

  Future<void> resetPin(String newPin) async =>
      _storage.write(key: _kPin, value: newPin);

  Future<void> resetApp() async {
    final prefs = await _prefs;
    await prefs.clear();
    await _storage.deleteAll();
    currentUser = null;
    state = AppStartRoute.onboarding;
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppStartRoute>(
  (_) => AppStateNotifier());