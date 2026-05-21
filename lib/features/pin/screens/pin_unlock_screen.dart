import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusguard/core/theme/app_theme.dart';
import 'package:focusguard/core/providers/app_state_provider.dart';

// Fingerprint REMOVED — unreliable across devices, per user feedback.
class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key});
  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen>
    with SingleTickerProviderStateMixin {
  String _pin      = '';
  bool   _error    = false;
  int    _attempts = 0;

  late AnimationController _shakeCtrl;
  late Animation<double>   _shake;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -6.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0),   weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override void dispose() { _shakeCtrl.dispose(); super.dispose(); }

  void _onKey(String k) {
    HapticFeedback.lightImpact();
    setState(() {
      _error = false;
      if (k == '⌫') { if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1); return; }
      if (_pin.length < 4) {
        _pin += k;
        if (_pin.length == 4) Future.delayed(const Duration(milliseconds: 80), _submit);
      }
    });
  }

  Future<void> _submit() async {
    final ok = await ref.read(appStateProvider.notifier).verifyPin(_pin);
    if (ok && mounted) { context.go('/dashboard'); return; }
    HapticFeedback.heavyImpact();
    _shakeCtrl.forward(from: 0);
    setState(() { _error = true; _attempts++; _pin = ''; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg  = isDark ? FGColors.bg  : FGColorsLight.bg;
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts  = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt  = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final p   = isDark ? FGColors.purple      : FGColorsLight.purple;
    final pL  = isDark ? FGColors.purpleLight : FGColorsLight.purpleLight;
    final err = isDark ? FGColors.red         : FGColorsLight.red;
    final b   = isDark ? FGColors.border      : FGColorsLight.border;
    final b2  = isDark ? FGColors.border2     : FGColorsLight.border2;
    final bg3 = isDark ? FGColors.bg3         : FGColorsLight.bg3;
    final user = ref.watch(appStateProvider.notifier).currentUser;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        Positioned(top: -60, left: -40, child: Container(width: 220, height: 220,
          decoration: BoxDecoration(shape: BoxShape.circle, color: p.withOpacity(0.06)))),
        Positioned(bottom: -80, right: -60, child: Container(width: 260, height: 260,
          decoration: BoxDecoration(shape: BoxShape.circle, color: p.withOpacity(0.04)))),
        SafeArea(child: Column(children: [
          const SizedBox(height: 52),
          // Logo
          Container(width: 80, height: 80,
            decoration: BoxDecoration(borderRadius: FGRadius.xl,
              gradient: LinearGradient(colors: [p, pL],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: p.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 34)),
          const SizedBox(height: 18),
          RichText(text: TextSpan(style: const TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w800),
            children: [TextSpan(text: 'Stay', style: TextStyle(color: p)),
                       TextSpan(text: 'Off', style: TextStyle(color: tp))])),
          const SizedBox(height: 8),
          Text(user != null ? 'Welcome back, ${user.name.split(' ').first}!' : 'Welcome back!',
            style: TextStyle(fontFamily: 'DM Sans', fontSize: 15, color: ts)),
          const SizedBox(height: 4),
          Text('Enter your PIN to continue',
            style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: tt)),
          const SizedBox(height: 40),
          // PIN dots
          AnimatedBuilder(animation: _shake, builder: (_, __) =>
            Transform.translate(offset: Offset(_shake.value, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return AnimatedScale(
                    scale: filled ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16, height: 16,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: _error ? err : filled ? p : Colors.transparent,
                        border: Border.all(color: _error ? err : filled ? p : b2, width: filled ? 0 : 2))));
                })))),
          AnimatedOpacity(opacity: _error ? 1.0 : 0.0, duration: const Duration(milliseconds: 200),
            child: Padding(padding: const EdgeInsets.only(top: 12),
              child: Text(_attempts >= 5 ? 'Too many attempts.' : 'Incorrect PIN.',
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: err)))),
          const Spacer(),
          // Numpad
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
            child: GridView.count(
              crossAxisCount: 3, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.65,
              children: ['1','2','3','4','5','6','7','8','9','','0','⌫'].map((k) {
                if (k.isEmpty) return const SizedBox();
                final isDel = k == '⌫';
                return GestureDetector(onTap: () => _onKey(k),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDel ? Colors.transparent : bg3,
                      borderRadius: FGRadius.md,
                      border: Border.all(color: isDel ? Colors.transparent : b)),
                    child: Center(child: isDel
                      ? Icon(Icons.backspace_outlined, color: tt, size: 20)
                      : Text(k, style: TextStyle(fontFamily: 'Syne', fontSize: 22,
                          fontWeight: FontWeight.w700, color: tp)))));
              }).toList())),
          const SizedBox(height: 18),
          GestureDetector(onTap: () => _showReset(context),
            child: Text('Forgot PIN?', style: TextStyle(fontFamily: 'DM Sans',
              fontSize: 13, color: tt, decoration: TextDecoration.underline, decorationColor: tt))),
          const SizedBox(height: 32),
        ])),
      ]),
    );
  }

  void _showReset(BuildContext context) =>
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(parent: ProviderScope.containerOf(context),
        child: const _ResetSheet()));
}

// ── RESET SHEET ───────────────────────────────────────────────────────
class _ResetSheet extends ConsumerStatefulWidget {
  const _ResetSheet();
  @override ConsumerState<_ResetSheet> createState() => _ResetSheetState();
}
class _ResetSheetState extends ConsumerState<_ResetSheet> {
  final _answerCtrl = TextEditingController();
  String _newPin = '', _confirmPin = '';
  bool _confirmMode = false;
  int _step = 0;
  String? _error;
  @override void dispose() { _answerCtrl.dispose(); super.dispose(); }

  Future<void> _verify() async {
    if (_answerCtrl.text.trim().isEmpty) { setState(() => _error = 'Please enter your answer.'); return; }
    final ok = await ref.read(appStateProvider.notifier).verifySecurityAnswer(_answerCtrl.text);
    setState(() { if (ok) { _step = 1; _error = null; } else { _error = 'Incorrect answer.'; }});
  }

  void _onKey(String k) {
    setState(() {
      _error = null;
      if (k == '⌫') {
        if (_confirmMode && _confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        else if (!_confirmMode && _newPin.isNotEmpty) _newPin = _newPin.substring(0, _newPin.length - 1);
        return;
      }
      if (!_confirmMode && _newPin.length < 4) {
        _newPin += k;
        if (_newPin.length == 4) Future.delayed(const Duration(milliseconds: 250),
          () { if (mounted) setState(() => _confirmMode = true); });
      } else if (_confirmMode && _confirmPin.length < 4) {
        _confirmPin += k;
        if (_confirmPin.length == 4) _savePin();
      }
    });
  }

  Future<void> _savePin() async {
    if (_newPin != _confirmPin) {
      setState(() { _error = 'PINs don\'t match.'; _confirmMode = false; _newPin = ''; _confirmPin = ''; }); return;
    }
    await ref.read(appStateProvider.notifier).resetPin(_newPin);
    await ref.read(appStateProvider.notifier).unlock();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg2 = isDark ? FGColors.bg2 : FGColorsLight.bg2;
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final bg4 = isDark ? FGColors.bg4 : FGColorsLight.bg4;
    final b   = isDark ? FGColors.border  : FGColorsLight.border;
    final b2  = isDark ? FGColors.border2 : FGColorsLight.border2;
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts  = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt  = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final p   = isDark ? FGColors.purple      : FGColorsLight.purple;
    final red = isDark ? FGColors.red         : FGColorsLight.red;
    final user = ref.watch(appStateProvider.notifier).currentUser;
    final cur  = _confirmMode ? _confirmPin : _newPin;
    final bot  = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(color: bg2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: b2))),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bot),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: b2, borderRadius: FGRadius.full))),
        const SizedBox(height: 20),
        Text(_step == 0 ? 'Reset your PIN' : 'Set new PIN',
          style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w700, color: tp)),
        const SizedBox(height: 8),
        if (_error != null)
          Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: red.withOpacity(0.1), borderRadius: FGRadius.sm,
              border: Border.all(color: red.withOpacity(0.35))),
            child: Text(_error!, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: red))),
        if (_step == 0) ...[
          if (user?.securityQuestion != null) ...[
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: p.withOpacity(0.07), borderRadius: FGRadius.md,
                border: Border.all(color: p.withOpacity(0.2))),
              child: Text(user!.securityQuestion!, style: TextStyle(fontFamily: 'DM Sans',
                fontSize: 14, color: ts, height: 1.4), textAlign: TextAlign.center)),
            const SizedBox(height: 14),
            TextField(controller: _answerCtrl,
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: tp),
              decoration: InputDecoration(hintText: 'Your answer', hintStyle: TextStyle(color: tt),
                filled: true, fillColor: bg4,
                border: OutlineInputBorder(borderRadius: FGRadius.md, borderSide: BorderSide(color: b2)),
                enabledBorder: OutlineInputBorder(borderRadius: FGRadius.md, borderSide: BorderSide(color: b2)),
                focusedBorder: OutlineInputBorder(borderRadius: FGRadius.md, borderSide: BorderSide(color: p)))),
            const SizedBox(height: 16),
            GestureDetector(onTap: _verify, child: Container(width: double.infinity, height: 50,
              decoration: BoxDecoration(color: p, borderRadius: FGRadius.md),
              child: const Center(child: Text('Verify answer',
                style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))))),
          ] else ...[
            Text('No security question was set.\nContact support or re-register.',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: ts, height: 1.5),
              textAlign: TextAlign.center),
          ],
        ] else ...[
          Text(_confirmMode ? 'Confirm new PIN' : 'Enter new 4-digit PIN',
            style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: ts)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final f = i < cur.length;
              return AnimatedScale(scale: f ? 1.2 : 1.0, duration: const Duration(milliseconds: 180),
                child: Container(margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16, height: 16,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: f ? p : Colors.transparent,
                    border: Border.all(color: f ? p : b2, width: f ? 0 : 2))));
            })),
          const SizedBox(height: 16),
          GridView.count(crossAxisCount: 3, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.0,
            children: ['1','2','3','4','5','6','7','8','9','','0','⌫'].map((k) {
              if (k.isEmpty) return const SizedBox();
              final isDel = k == '⌫';
              return GestureDetector(onTap: () => _onKey(k),
                child: Container(
                  decoration: BoxDecoration(color: isDel ? Colors.transparent : bg3,
                    borderRadius: FGRadius.sm, border: Border.all(color: isDel ? Colors.transparent : b)),
                  child: Center(child: isDel
                    ? Icon(Icons.backspace_outlined, color: tt, size: 20)
                    : Text(k, style: TextStyle(fontFamily: 'Syne', fontSize: 20,
                        fontWeight: FontWeight.w700, color: tp)))));
            }).toList()),
        ],
        const SizedBox(height: 12),
        GestureDetector(onTap: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: tt,
            decoration: TextDecoration.underline, decorationColor: tt))),
      ]));
  }
}