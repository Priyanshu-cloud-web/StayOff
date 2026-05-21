import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusguard/core/theme/app_theme.dart';
import 'package:focusguard/shared/widgets/fg_widgets.dart';
import 'package:focusguard/features/safeguard/providers/safeguard_provider.dart';

class SafeguardScreen extends ConsumerWidget {
  const SafeguardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(safeguardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? FGColors.bg : FGColorsLight.bg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          // ── Top bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SafeGuard',
                    style: TextStyle(fontFamily: 'Syne', fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? FGColors.textPrimary : FGColorsLight.textPrimary)),
                  Text('Adult content & family protection',
                    style: TextStyle(fontFamily: 'DM Sans', fontSize: 12,
                      color: isDark ? FGColors.textSecond : FGColorsLight.textSecond)),
                ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: state.isEnabled
                    ? (isDark ? FGColors.tealGlow : const Color(0x1400A389))
                    : (isDark ? FGColors.bg4 : FGColorsLight.bg4),
                  borderRadius: FGRadius.full,
                  border: Border.all(
                    color: state.isEnabled
                      ? (isDark ? FGColors.teal : FGColorsLight.teal).withOpacity(0.4)
                      : (isDark ? FGColors.border2 : FGColorsLight.border2))),
                child: Text(state.isEnabled ? 'ON' : 'OFF',
                  style: TextStyle(fontFamily: 'Syne', fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: state.isEnabled
                      ? (isDark ? FGColors.teal : FGColorsLight.teal)
                      : (isDark ? FGColors.textThird : FGColorsLight.textThird)))),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusCard(state: state, isDark: isDark),
                  const SizedBox(height: 16),



                  // How it works
                  const FGSectionLabel('How SafeGuard works', topPad: 4),
                  _HowItWorksCard(isDark: isDark),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── STATUS CARD ───────────────────────────────────────────────────────
class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.state, required this.isDark});
  final SafeguardState state;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOn = state.isEnabled;
    final teal = isDark ? FGColors.teal        : FGColorsLight.teal;
    final red  = isDark ? FGColors.red         : FGColorsLight.red;
    final bg3  = isDark ? FGColors.bg3         : FGColorsLight.bg3;
    final b    = isDark ? FGColors.border      : FGColorsLight.border;
    final tp   = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts   = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isOn
          ? (isDark ? const Color(0x1400C9A7) : const Color(0x0A00A389))
          : bg3,
        borderRadius: FGRadius.xl,
        border: Border.all(color: isOn ? teal.withOpacity(0.3) : b)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: isOn ? teal.withOpacity(0.12) : (isDark ? FGColors.bg4 : FGColorsLight.bg4),
              borderRadius: FGRadius.md),
            child: Center(child: Text(isOn ? '🛡️' : '🔓',
              style: const TextStyle(fontSize: 22)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isOn ? 'SafeGuard is active' : 'SafeGuard is off',
              style: TextStyle(fontFamily: 'Syne', fontSize: 16,
                fontWeight: FontWeight.w700, color: tp)),
            const SizedBox(height: 3),
            Text(
              isOn
                ? 'Adult content is blocked across all browsers'
                : 'Tap below to enable protection',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: ts)),
          ])),
        ]),
        const SizedBox(height: 16),
        Text(
          isOn
            ? '🔒  Password required to disable. Protection works in every browser and app.'
            : 'Blocks adult sites at the network level.\nRequires a password to disable — no easy bypass.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: ts, height: 1.5)),
        const SizedBox(height: 16),

        if (!state.isPasswordSet) ...[
          FGButton(
            label: 'Set up SafeGuard',
            icon: Icons.shield_rounded,
            style: FGButtonStyle.teal,
            onTap: () => _showSetup(context)),
        ] else if (isOn) ...[
          FGButton(
            label: 'Disable SafeGuard',
            style: FGButtonStyle.outline,
            icon: Icons.lock_open_rounded,
            onTap: () => _showDisable(context)),
        ] else ...[
          FGButton(
            label: 'Enable SafeGuard',
            style: FGButtonStyle.teal,
            icon: Icons.shield_rounded,
            onTap: () => _showSetup(context)),
        ],
      ]),
    );
  }

  // After disabling, password is cleared → re-enable = fresh setup sheet
  void _showSetup(BuildContext context) =>
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(parent: ProviderScope.containerOf(context),
        child: const _SetupSheet()));

  void _showDisable(BuildContext context) =>
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(parent: ProviderScope.containerOf(context),
        child: const _PasswordSheet(mode: _PwMode.disable)));
}

// ── PARENT MODE CARD ──────────────────────────────────────────────────
class _ParentModeCard extends ConsumerWidget {
  const _ParentModeCard({required this.state, required this.isDark});
  final SafeguardState state;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final b   = isDark ? FGColors.border : FGColorsLight.border;
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts  = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;

    return Container(
      decoration: BoxDecoration(color: bg3, borderRadius: FGRadius.lg,
        border: Border.all(color: b)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Text('👨‍👩‍👧', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Parent PIN lock', style: TextStyle(fontFamily: 'DM Sans',
                fontSize: 13, fontWeight: FontWeight.w600, color: tp)),
              const SizedBox(height: 2),
              Text('Prevent children from changing any app setting with a 4-digit PIN.',
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: ts)),
            ])),
            Switch(
              value: state.isParentEnabled,
              onChanged: (v) => v
                ? _showSetup(context)
                : _showDisable(context)),
          ]),
        ),
        if (state.isParentEnabled) ...[
          Divider(height: 1, color: b),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: FGButton(
              label: 'Change parent PIN',
              style: FGButtonStyle.outline,
              icon: Icons.pin_outlined,
              onTap: () => _showSetup(context))),
        ],
      ]),
    );
  }

  void _showSetup(BuildContext context) =>
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(parent: ProviderScope.containerOf(context),
        child: const _PinSheet(mode: _PinMode.setup)));

  void _showDisable(BuildContext context) =>
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(parent: ProviderScope.containerOf(context),
        child: const _PinSheet(mode: _PinMode.disable)));
}

// ── HOW IT WORKS ──────────────────────────────────────────────────────
class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final b   = isDark ? FGColors.border : FGColorsLight.border;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg3, borderRadius: FGRadius.lg,
        border: Border.all(color: b)),
      child: Column(children: [
        _Row('🌐', 'Works in every browser and app',
          'A local VPN intercepts DNS queries. Adult sites return no IP address and simply cannot load — regardless of which browser the user opens.',
          isDark),
        const SizedBox(height: 14),
        _Row('🔐', 'Password-locked, no bypass',
          'Only the SafeGuard password can disable it. If a Commitment Lock is active, even the password cannot disable SafeGuard until the lock expires.',
          isDark),
        const SizedBox(height: 14),
        _Row('🚫', 'Covers 75+ adult platforms',
          'Tube sites, live cam platforms, creator subscription sites, and illustrated content — all blocked at the DNS level.',
          isDark),
        const SizedBox(height: 14),
        _Row('🛡️', 'Blocks DNS-over-HTTPS bypass',
          'Modern browsers try to switch to encrypted DNS to avoid blocks. StayOff intercepts those providers too.',
          isDark),
      ]),
    );
  }

  Widget _Row(String emoji, String title, String body, bool isDark) =>
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? FGColors.textPrimary : FGColorsLight.textPrimary)),
        const SizedBox(height: 3),
        Text(body, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12,
          color: isDark ? FGColors.textSecond : FGColorsLight.textSecond, height: 1.45)),
      ])),
    ]);
}

// ── SETUP SHEET ───────────────────────────────────────────────────────
class _SetupSheet extends ConsumerStatefulWidget {
  const _SetupSheet();
  @override ConsumerState<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends ConsumerState<_SetupSheet> {
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  @override void dispose() { _passCtrl.dispose(); _confCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_passCtrl.text.length < 4) {
      setState(() => _error = 'Password must be at least 4 characters.'); return;
    }
    if (_passCtrl.text != _confCtrl.text) {
      setState(() => _error = 'Passwords do not match.'); return;
    }
    setState(() { _loading = true; _error = null; });
    final ok = await ref.read(safeguardProvider.notifier).setupWithPassword(_passCtrl.text);
    setState(() => _loading = false);
    if (!ok) {
      setState(() => _error = 'VPN permission was denied. Please try again and tap OK.');
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final bg2 = isDark ? FGColors.bg2 : FGColorsLight.bg2;
    final b2  = isDark ? FGColors.border2 : FGColorsLight.border2;
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts  = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt  = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final p   = isDark ? FGColors.purple      : FGColorsLight.purple;
    final red = isDark ? FGColors.red         : FGColorsLight.red;

    return Container(
      decoration: BoxDecoration(color: bg2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: b2))),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: b2, borderRadius: FGRadius.full))),
        const SizedBox(height: 20),
        const Text('🛡️', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text('Set up SafeGuard', style: TextStyle(fontFamily: 'Syne',
          fontSize: 18, fontWeight: FontWeight.w700, color: tp)),
        const SizedBox(height: 6),
        Text('Create a password to protect this feature.\nOnly this password can ever disable SafeGuard.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: ts, height: 1.4),
          textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: red.withOpacity(0.08),
            borderRadius: FGRadius.sm,
            border: Border.all(color: red.withOpacity(0.3))),
          child: Row(children: [
            Icon(Icons.warning_amber_rounded, color: red, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'After tapping Enable, Android will ask for VPN permission — tap OK or blocking will not work.',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: red, height: 1.3))),
          ])),
        const SizedBox(height: 16),
        if (_error != null) ...[
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: red.withOpacity(0.08),
              borderRadius: FGRadius.sm, border: Border.all(color: red.withOpacity(0.3))),
            child: Text(_error!, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: red))),
          const SizedBox(height: 12),
        ],
        _PwField(ctrl: _passCtrl, hint: 'Create password (min 4 chars)',
          obscure: _obscure, isDark: isDark, p: p, tt: tt,
          onToggle: () => setState(() => _obscure = !_obscure)),
        const SizedBox(height: 10),
        _PwField(ctrl: _confCtrl, hint: 'Confirm password',
          obscure: _obscure, isDark: isDark, p: p, tt: tt,
          onToggle: () => setState(() => _obscure = !_obscure)),
        const SizedBox(height: 20),
        FGButton(label: 'Enable SafeGuard', icon: Icons.shield_rounded,
          style: FGButtonStyle.teal, loading: _loading, onTap: _submit),
      ]));
  }
}

// ── PASSWORD SHEET (disable / change) ────────────────────────────────
enum _PwMode { disable, change }

class _PasswordSheet extends ConsumerStatefulWidget {
  const _PasswordSheet({required this.mode});
  final _PwMode mode;
  @override ConsumerState<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends ConsumerState<_PasswordSheet> {
  final _currCtrl = TextEditingController();
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  @override void dispose() { _currCtrl.dispose(); _newCtrl.dispose(); _confCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final notifier = ref.read(safeguardProvider.notifier);
    bool ok = false;
    if (widget.mode == _PwMode.disable) {
      final locked = await notifier.isCommitmentLocked();
      if (locked) {
        setState(() { _loading = false; _error = 'Commitment lock is active. You cannot disable SafeGuard until the lock period expires.'; });
        return;
      }
      ok = await notifier.disableWithPassword(_currCtrl.text);
      if (!ok) setState(() => _error = 'Incorrect password.');
    } else {
      if (_newCtrl.text.length < 4) {
        setState(() { _loading = false; _error = 'New password must be at least 4 characters.'; }); return;
      }
      if (_newCtrl.text != _confCtrl.text) {
        setState(() { _loading = false; _error = 'Passwords do not match.'; }); return;
      }
      ok = await notifier.changePassword(_currCtrl.text, _newCtrl.text);
      if (!ok) setState(() => _error = 'Incorrect current password.');
    }
    setState(() => _loading = false);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final bg2 = isDark ? FGColors.bg2 : FGColorsLight.bg2;
    final b2  = isDark ? FGColors.border2 : FGColorsLight.border2;
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts  = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt  = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final p   = isDark ? FGColors.purple      : FGColorsLight.purple;
    final red = isDark ? FGColors.red         : FGColorsLight.red;

    return Container(
      decoration: BoxDecoration(color: bg2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: b2))),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: b2, borderRadius: FGRadius.full))),
        const SizedBox(height: 20),
        const Text('🔐', style: TextStyle(fontSize: 32)),
        const SizedBox(height: 12),
        Text(widget.mode == _PwMode.disable ? 'Disable SafeGuard' : 'Change password',
          style: TextStyle(fontFamily: 'Syne', fontSize: 17, fontWeight: FontWeight.w700, color: tp)),
        const SizedBox(height: 6),
        Text(widget.mode == _PwMode.disable
          ? 'Enter your SafeGuard password to turn off protection.'
          : 'Enter your current password, then set a new one.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: ts),
          textAlign: TextAlign.center),
        const SizedBox(height: 16),
        if (_error != null) ...[
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: red.withOpacity(0.08),
              borderRadius: FGRadius.sm, border: Border.all(color: red.withOpacity(0.3))),
            child: Text(_error!, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: red))),
          const SizedBox(height: 12),
        ],
        _PwField(ctrl: _currCtrl,
          hint: widget.mode == _PwMode.disable ? 'SafeGuard password' : 'Current password',
          obscure: _obscure, isDark: isDark, p: p, tt: tt,
          onToggle: () => setState(() => _obscure = !_obscure)),
        if (widget.mode == _PwMode.change) ...[
          const SizedBox(height: 10),
          _PwField(ctrl: _newCtrl, hint: 'New password (min 4 chars)',
            obscure: _obscure, isDark: isDark, p: p, tt: tt,
            onToggle: () => setState(() => _obscure = !_obscure)),
          const SizedBox(height: 10),
          _PwField(ctrl: _confCtrl, hint: 'Confirm new password',
            obscure: _obscure, isDark: isDark, p: p, tt: tt,
            onToggle: () => setState(() => _obscure = !_obscure)),
        ],
        const SizedBox(height: 20),
        FGButton(
          label: widget.mode == _PwMode.disable ? 'Confirm disable' : 'Update password',
          style: widget.mode == _PwMode.disable ? FGButtonStyle.danger : FGButtonStyle.primary,
          loading: _loading, onTap: _submit),
        const SizedBox(height: 10),
        FGButton(label: 'Cancel', style: FGButtonStyle.outline,
          onTap: () => Navigator.pop(context)),
      ]));
  }
}

// ── PIN SHEET ─────────────────────────────────────────────────────────
enum _PinMode { setup, disable }

class _PinSheet extends ConsumerStatefulWidget {
  const _PinSheet({required this.mode});
  final _PinMode mode;
  @override ConsumerState<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends ConsumerState<_PinSheet> {
  String _pin = '', _confirm = '';
  bool _confirming = false, _error = false;

  void _onKey(String k) {
    setState(() {
      _error = false;
      if (k == '⌫') {
        if (_confirming) {
          if (_confirm.isNotEmpty) _confirm = _confirm.substring(0, _confirm.length - 1);
        } else {
          if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
        }
        return;
      }
      if (!_confirming && _pin.length < 4) {
        _pin += k;
        if (_pin.length == 4) {
          if (widget.mode == _PinMode.setup) {
            Future.delayed(const Duration(milliseconds: 300),
              () { if (mounted) setState(() => _confirming = true); });
          } else {
            Future.delayed(const Duration(milliseconds: 100), _submit);
          }
        }
      } else if (_confirming && _confirm.length < 4) {
        _confirm += k;
        if (_confirm.length == 4) _submit();
      }
    });
  }

  Future<void> _submit() async {
    final notifier = ref.read(safeguardProvider.notifier);
    if (widget.mode == _PinMode.setup) {
      if (_pin != _confirm) {
        setState(() { _error = true; _confirming = false; _pin = ''; _confirm = ''; });
        return;
      }
      await notifier.setupParentPin(_pin);
    } else {
      final ok = await notifier.disableParentPin(_pin);
      if (!ok) {
        setState(() { _error = true; _pin = ''; });
        return;
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg2 = isDark ? FGColors.bg2 : FGColorsLight.bg2;
    final b2  = isDark ? FGColors.border2 : FGColorsLight.border2;
    final b   = isDark ? FGColors.border  : FGColorsLight.border;
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts  = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt  = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final p   = isDark ? FGColors.purple      : FGColorsLight.purple;
    final red = isDark ? FGColors.red         : FGColorsLight.red;
    final current = _confirming ? _confirm : _pin;

    return Container(
      decoration: BoxDecoration(color: bg2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: b2))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: b2, borderRadius: FGRadius.full))),
        const SizedBox(height: 20),
        const Text('🔢', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 12),
        Text(
          widget.mode == _PinMode.setup
            ? (_confirming ? 'Confirm your PIN' : 'Set parent PIN')
            : 'Enter parent PIN',
          style: TextStyle(fontFamily: 'Syne', fontSize: 17, fontWeight: FontWeight.w700, color: tp)),
        const SizedBox(height: 6),
        Text(
          _error
            ? (widget.mode == _PinMode.setup ? 'PINs do not match. Try again.' : 'Wrong PIN. Try again.')
            : widget.mode == _PinMode.setup
              ? (_confirming ? 'Enter the same 4 digits again to confirm.' : 'Choose a 4-digit PIN for parent lock.')
              : 'Enter your parent PIN to disable the lock.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: _error ? red : ts),
          textAlign: TextAlign.center),
        const SizedBox(height: 24),
        // PIN dots
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < current.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: filled ? 18 : 14, height: filled ? 18 : 14,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: _error ? red : filled ? p : Colors.transparent,
                border: Border.all(
                  color: _error ? red : filled ? p : b2, width: 2)));
          })),
        const SizedBox(height: 24),
        // Numpad
        GridView.count(
          crossAxisCount: 3, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.8,
          children: ['1','2','3','4','5','6','7','8','9','','0','⌫'].map((k) {
            if (k.isEmpty) return const SizedBox();
            final isDel = k == '⌫';
            return GestureDetector(
              onTap: () => _onKey(k),
              child: Container(
                decoration: BoxDecoration(
                  color: isDel ? Colors.transparent : bg3,
                  borderRadius: FGRadius.sm,
                  border: Border.all(color: isDel ? Colors.transparent : b)),
                child: Center(
                  child: isDel
                    ? Icon(Icons.backspace_outlined, color: tt, size: 18)
                    : Text(k, style: TextStyle(fontFamily: 'Syne',
                        fontSize: 20, fontWeight: FontWeight.w700, color: tp)))));
          }).toList()),
      ]));
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────────
class _PwField extends StatelessWidget {
  const _PwField({
    required this.ctrl, required this.hint, required this.obscure,
    required this.isDark, required this.p, required this.tt,
    required this.onToggle,
  });
  final TextEditingController ctrl;
  final String hint;
  final bool obscure, isDark;
  final Color p, tt;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final bg4 = isDark ? FGColors.bg4 : FGColorsLight.bg4;
    final b2  = isDark ? FGColors.border2 : FGColorsLight.border2;
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: tp),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: tt),
        filled: true, fillColor: bg4,
        prefixIcon: Icon(Icons.lock_outline_rounded, color: tt, size: 18),
        suffixIcon: GestureDetector(onTap: onToggle,
          child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: tt, size: 18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: FGRadius.md, borderSide: BorderSide(color: b2)),
        enabledBorder: OutlineInputBorder(borderRadius: FGRadius.md, borderSide: BorderSide(color: b2)),
        focusedBorder: OutlineInputBorder(borderRadius: FGRadius.md,
          borderSide: BorderSide(color: p, width: 1.5))));
  }
}