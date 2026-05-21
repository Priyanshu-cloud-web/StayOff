import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusguard/core/theme/app_theme.dart';
import 'package:focusguard/core/providers/app_state_provider.dart';
import 'package:focusguard/features/appblocker/providers/appblocker_provider.dart';

const _kQ = [
  "What was your first pet's name?",
  'What city were you born in?',
  "What was your first school's name?",
  'What was your childhood nickname?',
  'Who was your best childhood friend?',
];

// Steps: 0=name  1=pin  2=permissions  3=recovery  4=done
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RS();
}

class _RS extends ConsumerState<RegisterScreen> with TickerProviderStateMixin {
  int    _step = 0;
  String _name = '', _pin = '', _cPin = '';
  bool   _cMode = false, _pinErr = false, _showRec = false, _loading = false;
  String? _err;
  String _selQ = _kQ[0];
  final _nameCtrl = TextEditingController();
  final _ansCtrl  = TextEditingController();
  final _nFocus   = FocusNode();

  late AnimationController _bgC, _stepC, _shakeC, _doneC;
  late Animation<double>   _bgA, _fadeA, _scaleA, _shakeA;
  late Animation<Offset>   _slideA;

  @override
  void initState() {
    super.initState();
    _bgC = AnimationController(vsync: this, duration: const Duration(seconds: 7))
      ..repeat(reverse: true);
    _bgA = CurvedAnimation(parent: _bgC, curve: Curves.easeInOut);
    _stepC = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _fadeA  = CurvedAnimation(parent: _stepC, curve: Curves.easeOut);
    _slideA = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _stepC, curve: Curves.easeOutCubic));
    _stepC.forward();
    _shakeC = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _shakeA = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -11.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -11.0, end: 11.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 11.0, end: -6.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0),   weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeC, curve: Curves.easeInOut));
    _doneC = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _scaleA = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _doneC, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _bgC.dispose(); _stepC.dispose(); _shakeC.dispose(); _doneC.dispose();
    _nameCtrl.dispose(); _ansCtrl.dispose(); _nFocus.dispose();
    super.dispose();
  }

  void _go(int next) {
    setState(() { _step = next; _err = null; });
    _stepC.forward(from: 0);
    if (next == 1) FocusScope.of(context).unfocus();
    if (next == 4) { _doneC.forward(from: 0); _register(); }
  }

  void _nextName() {
    if (_nameCtrl.text.trim().isEmpty) { setState(() => _err = 'Please enter your name.'); return; }
    _name = _nameCtrl.text.trim();
    _go(1);
  }

  void _key(String k) {
    HapticFeedback.lightImpact();
    setState(() {
      _pinErr = false; _err = null;
      if (k == '\u232b') {
        if (_cMode && _cPin.isNotEmpty) _cPin = _cPin.substring(0, _cPin.length - 1);
        else if (!_cMode && _pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
        return;
      }
      if (!_cMode && _pin.length < 4) {
        _pin += k;
        if (_pin.length == 4)
          Future.delayed(const Duration(milliseconds: 310),
              () { if (mounted) setState(() => _cMode = true); });
      } else if (_cMode && _cPin.length < 4) {
        _cPin += k;
        if (_cPin.length == 4)
          Future.delayed(const Duration(milliseconds: 100), _checkPin);
      }
    });
  }

  void _checkPin() {
    if (_pin == _cPin) { HapticFeedback.mediumImpact(); _go(2); }
    else {
      HapticFeedback.heavyImpact();
      _shakeC.forward(from: 0);
      setState(() { _pinErr = true; _cMode = false; _pin = ''; _cPin = ''; _err = "PINs didn't match \u2014 try again."; });
    }
  }

  Future<void> _register() async {
    setState(() { _loading = true; _err = null; });
    await ref.read(appStateProvider.notifier).register(
      name: _name, pin: _pin,
      securityQuestion: _showRec ? _selQ : null,
      securityAnswer:   _showRec ? _ansCtrl.text.trim() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final sz = MediaQuery.of(context).size;
    final p  = d ? FGColors.purple : FGColorsLight.purple;
    final pL = d ? FGColors.purpleLight : FGColorsLight.purpleLight;
    return Scaffold(
      backgroundColor: d ? FGColors.bg : FGColorsLight.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        _Bg(a: _bgA, sz: sz, p: p, dark: d),
        Positioned(top: 0, left: 0, right: 0,
          child: SafeArea(bottom: false,
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(children: [
                if (_step < 4)
                  _BackBtn(dark: d, onTap: () {
                    if (_step == 0) { ref.read(appStateProvider.notifier).goBackToOnboarding(); context.go('/onboarding'); }
                    else { if (_step == 1) setState(() { _pin = ''; _cPin = ''; _cMode = false; }); _go(_step - 1); }
                  })
                else const SizedBox(width: 38),
                const SizedBox(width: 10),
                Expanded(child: _Dots(step: _step, total: 4, p: p, dark: d)),
                const SizedBox(width: 48),
              ])))),
        SafeArea(child: Padding(
          padding: const EdgeInsets.only(top: 64),
          child: FadeTransition(opacity: _fadeA,
            child: SlideTransition(position: _slideA,
              child: _content(d, p, pL))))),
      ]),
    );
  }

  Widget _content(bool d, Color p, Color pL) {
    switch (_step) {
      case 0: return _NameStep(ctrl: _nameCtrl, focus: _nFocus, err: _err, dark: d, p: p, onNext: _nextName);
      case 1: return _PinStep(pin: _pin, cpin: _cPin, cm: _cMode, pe: _pinErr, msg: _err, shake: _shakeA, dark: d, p: p, onKey: _key);
      case 2: return _PermStep(dark: d, p: p, pL: pL, onNext: () => _go(3));
      case 3: return _RecStep(show: _showRec, selQ: _selQ, ctrl: _ansCtrl, dark: d, p: p, pL: pL,
          loading: _loading,
          onToggle: (v) => setState(() => _showRec = v),
          onQ: (q) => setState(() => _selQ = q),
          onDone: () => _go(4));
      default: return _DoneStep(name: _name, dark: d, p: p, pL: pL, scale: _scaleA, loading: _loading);
    }
  }
}

// ─────────────────────────────────────────────
//  STEP 2 — PERMISSIONS
// ─────────────────────────────────────────────
class _PermStep extends ConsumerStatefulWidget {
  const _PermStep({required this.dark, required this.p, required this.pL, required this.onNext});
  final bool dark; final Color p, pL; final VoidCallback onNext;
  @override ConsumerState<_PermStep> createState() => _PermStepState();
}

class _PermStepState extends ConsumerState<_PermStep>
    with WidgetsBindingObserver {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Fires when user returns from Android settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState st) {
    if (st == AppLifecycleState.resumed) {
      ref.read(appBlockerProvider.notifier).refreshA11y();
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openA11y() async {
    setState(() => _checking = true);
    // Open settings then the observer handles the result
    await ref.read(appBlockerProvider.notifier).openAccessibilitySettings();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(appBlockerProvider);
    final granted = state.accessibilityPermission == PermissionStatus.granted;
    final d  = widget.dark; final p = widget.p; final pL = widget.pL;
    final tp  = d ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts  = d ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt  = d ? FGColors.textThird   : FGColorsLight.textThird;
    final bg3 = d ? FGColors.bg3 : FGColorsLight.bg3;
    final b   = d ? FGColors.border : FGColorsLight.border;
    final teal= d ? FGColors.teal : FGColorsLight.teal;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 40),
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('\u26a1', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 14),
        Text('One permission\nto make it work', style: TextStyle(fontFamily: 'Syne',
          fontSize: 30, fontWeight: FontWeight.w800, color: tp, height: 1.08)),
        const SizedBox(height: 10),
        Text('StayOff needs Accessibility access to block YouTube Shorts, Instagram Reels, and TikTok in real time.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: ts, height: 1.55)),
        const SizedBox(height: 28),
        Container(
          decoration: BoxDecoration(color: bg3, borderRadius: FGRadius.lg, border: Border.all(color: b)),
          child: Column(children: [
            _PR('\u2705', 'Detects Shorts / Reels opening', 'Watches app UI names \u2014 nothing else', teal, d),
            Divider(height: 1, color: b),
            _PR('\u2705', 'Closes the content instantly', 'Automatically presses Back for you', teal, d),
            Divider(height: 1, color: b),
            _PR('\ud83d\udeab', 'Does NOT read your messages', 'Never reads texts, passwords, or personal data', tt, d),
            Divider(height: 1, color: b),
            _PR('\ud83d\udeab', 'Does NOT log anything', 'No data ever leaves your device', tt, d),
          ])),
        const SizedBox(height: 20),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: granted ? teal.withOpacity(0.08) : p.withOpacity(0.07),
            borderRadius: FGRadius.md,
            border: Border.all(color: granted ? teal.withOpacity(0.3) : p.withOpacity(0.25))),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(
                color: granted ? teal.withOpacity(0.15) : p.withOpacity(0.12),
                borderRadius: FGRadius.sm),
              child: Center(child: Icon(
                granted ? Icons.check_circle_rounded : Icons.accessibility_new_rounded,
                color: granted ? teal : pL, size: 22))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(granted ? 'Permission granted \u2713' : 'Not yet enabled',
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
                  fontWeight: FontWeight.w600, color: granted ? teal : tp)),
              const SizedBox(height: 2),
              Text(granted ? 'StayOff can now block Shorts & Reels'
                : 'Tap below \u2014 find StayOff and turn it ON',
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: tt)),
            ])),
          ])),
        const SizedBox(height: 20),
        if (!granted) ...[
          _RBtn(label: _checking ? 'Checking\u2026' : 'Enable Accessibility \u2192',
            p: p, loading: _checking, onTap: _openA11y),
          const SizedBox(height: 12),
          Center(child: GestureDetector(
            onTap: widget.onNext,
            child: Text('Skip for now \u2014 I\u2019ll do this later',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: tt,
                decoration: TextDecoration.underline, decorationColor: tt)))),
        ] else
          _RBtn(label: 'Continue \u2192', p: teal, onTap: widget.onNext),
      ]));
  }

  Widget _PR(String icon, String title, String sub, Color c, bool d) {
    final tp = d ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final tt = d ? FGColors.textThird   : FGColorsLight.textThird;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 18)), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
            fontWeight: FontWeight.w600, color: tp)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: tt)),
        ])),
      ]));
  }
}

// ─────────────────────────────────────────────
//  BG / ORBS
// ─────────────────────────────────────────────
class _Bg extends StatelessWidget {
  const _Bg({required this.a, required this.sz, required this.p, required this.dark});
  final Animation<double> a; final Size sz; final Color p; final bool dark;
  @override Widget build(BuildContext _) =>
    AnimatedBuilder(animation: a, builder: (_, __) {
      final t = a.value;
      return Stack(children: [
        Positioned(top: -60 + t*44, right: -80 + t*22, child: _Orb(r: 280, c: p.withOpacity(dark ? 0.09 : 0.06))),
        Positioned(bottom: -80 + t*32, left: -60 + (1-t)*20, child: _Orb(r: 240, c: p.withOpacity(dark ? 0.06 : 0.04))),
        Positioned(top: sz.height*0.4 + t*50-25, right: -90 + t*14,
          child: _Orb(r: 160, c: const Color(0xFF00C9A7).withOpacity(dark ? 0.05 : 0.03))),
        if (dark) Positioned.fill(child: CustomPaint(painter: _Grain())),
      ]);
    });
}

class _Orb extends StatelessWidget {
  const _Orb({required this.r, required this.c});
  final double r; final Color c;
  @override Widget build(BuildContext _) => Container(width: r, height: r,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c,
      boxShadow: [BoxShadow(color: c, blurRadius: r*0.7)]));
}

class _Grain extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final p = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 2600; i++) {
      p.color = Colors.white.withOpacity(rng.nextDouble() * 0.024);
      canvas.drawCircle(Offset(rng.nextDouble()*size.width, rng.nextDouble()*size.height), 0.55, p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────
//  CHROME
// ─────────────────────────────────────────────
class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.dark, required this.onTap});
  final bool dark; final VoidCallback onTap;
  @override Widget build(BuildContext _) => GestureDetector(onTap: onTap,
    child: Container(width: 38, height: 38,
      decoration: BoxDecoration(
        color: dark ? FGColors.bg3 : FGColorsLight.bg3,
        borderRadius: FGRadius.sm,
        border: Border.all(color: dark ? FGColors.border : FGColorsLight.border)),
      child: Icon(Icons.arrow_back_ios_new_rounded, size: 14,
        color: dark ? FGColors.textSecond : FGColorsLight.textSecond)));
}

class _Dots extends StatelessWidget {
  const _Dots({required this.step, required this.total, required this.p, required this.dark});
  final int step, total; final Color p; final bool dark;
  @override Widget build(BuildContext _) {
    final b2 = dark ? FGColors.border2 : FGColorsLight.border2;
    return Row(mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: i == step.clamp(0, total-1) ? 22 : 7, height: 7,
        decoration: BoxDecoration(borderRadius: FGRadius.full,
          color: i < step ? p.withOpacity(0.5) : i == step.clamp(0, total-1) ? p : b2))));
  }
}

class _Hdr extends StatelessWidget {
  const _Hdr({required this.emoji, required this.title, required this.sub, required this.dark});
  final String emoji, title, sub; final bool dark;
  @override Widget build(BuildContext _) {
    final tp = dark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts = dark ? FGColors.textSecond  : FGColorsLight.textSecond;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 44)),
      const SizedBox(height: 14),
      Text(title, style: TextStyle(fontFamily: 'Syne', fontSize: 30,
        fontWeight: FontWeight.w800, color: tp, height: 1.08)),
      const SizedBox(height: 10),
      Text(sub, style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: ts, height: 1.55)),
    ]);
  }
}

// ─────────────────────────────────────────────
//  STEP 0 — NAME
// ─────────────────────────────────────────────
class _NameStep extends StatefulWidget {
  const _NameStep({required this.ctrl, required this.focus, required this.err,
    required this.dark, required this.p, required this.onNext});
  final TextEditingController ctrl; final FocusNode focus;
  final String? err; final bool dark; final Color p; final VoidCallback onNext;
  @override State<_NameStep> createState() => _NSS();
}
class _NSS extends State<_NameStep> {
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
      Future.delayed(const Duration(milliseconds: 420), () { if (mounted) widget.focus.requestFocus(); }));
  }
  @override Widget build(BuildContext _) {
    final d=widget.dark; final p=widget.p;
    final tp=d ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final tt=d ? FGColors.textThird : FGColorsLight.textThird;
    final bg4=d ? FGColors.bg4 : FGColorsLight.bg4;
    final b2=d ? FGColors.border2 : FGColorsLight.border2;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 40),
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Hdr(emoji: '\ud83d\udc4b', title: 'What should\nwe call you?',
          sub: 'Your name appears on the dashboard.\nNo account needed \u2014 stored on device.', dark: d),
        const SizedBox(height: 34),
        Container(
          decoration: BoxDecoration(color: bg4, borderRadius: FGRadius.xl,
            border: Border.all(color: b2, width: 1.5),
            boxShadow: [BoxShadow(color: p.withOpacity(0.07), blurRadius: 24, offset: const Offset(0, 8))]),
          child: TextField(controller: widget.ctrl, focusNode: widget.focus,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => widget.onNext(),
            style: TextStyle(fontFamily: 'Syne', fontSize: 26, fontWeight: FontWeight.w700, color: tp),
            cursorColor: p, cursorWidth: 2.5, cursorRadius: const Radius.circular(2),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(fontFamily: 'Syne', fontSize: 26, fontWeight: FontWeight.w700, color: tt.withOpacity(0.4)),
              filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 22)))),
        if (widget.err != null) ...[const SizedBox(height: 12), _ErrW(widget.err!, dark: d)],
        const SizedBox(height: 30),
        _RBtn(label: 'Continue \u2192', p: p, onTap: widget.onNext),
        const SizedBox(height: 18),
        Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_outline_rounded, size: 11, color: tt), const SizedBox(width: 5),
          Text('No servers \u00b7 On-device only', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: tt)),
        ])),
      ]));
  }
}

// ─────────────────────────────────────────────
//  STEP 1 — PIN
// ─────────────────────────────────────────────
class _PinStep extends StatelessWidget {
  const _PinStep({required this.pin, required this.cpin, required this.cm,
    required this.pe, required this.msg, required this.shake,
    required this.dark, required this.p, required this.onKey});
  final String pin, cpin; final bool cm, pe;
  final String? msg; final Animation<double> shake;
  final bool dark; final Color p;
  final void Function(String) onKey;
  @override Widget build(BuildContext context) {
    final cur = cm ? cpin : pin;
    final ec  = dark ? FGColors.red     : FGColorsLight.red;
    final b2  = dark ? FGColors.border2 : FGColorsLight.border2;

    return Column(children: [
      // ── Header (top) ──────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 0),
        child: _Hdr(
          emoji: cm ? '\ud83d\udd01' : '\ud83d\udd10',
          title: cm ? 'Confirm\nyour PIN' : 'Create your\nPIN',
          sub: cm ? 'Enter the same 4 digits again.'
              : 'This PIN unlocks the app every time.',
          dark: dark)),

      // ── Fixed gap below header ─────────────────────────────────
      const SizedBox(height: 44),

      // ── PIN dots ──────────────────────────────────────────────
      AnimatedBuilder(
        animation: shake,
        builder: (_, __) => Transform.translate(
          offset: Offset(shake.value, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final f = i < cur.length;
              return AnimatedScale(
                scale: f ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pe ? ec : f ? p : Colors.transparent,
                    border: Border.all(
                      color: pe ? ec : f ? p : b2,
                      width: f ? 0 : 2))));
            })))),

      // ── Error ──────────────────────────────────────────────────
      if (msg != null) ...[
        const SizedBox(height: 16),
        Center(child: _ErrW(msg!, dark: dark)),
      ],

      // ── Flexible space — pushes numpad to bottom ───────────────
      const Spacer(),

      // ── Numpad (bottom) ───────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(26, 0, 26, 36),
        child: _Numpad(onKey: onKey, dark: dark, p: p)),
    ]);
  }
}

// ─────────────────────────────────────────────
//  STEP 3 — RECOVERY
// ─────────────────────────────────────────────
class _RecStep extends StatelessWidget {
  const _RecStep({required this.show, required this.selQ, required this.ctrl,
    required this.dark, required this.p, required this.pL,
    required this.loading, required this.onToggle, required this.onQ, required this.onDone});
  final bool show, loading; final String selQ;
  final TextEditingController ctrl; final bool dark; final Color p, pL;
  final ValueChanged<bool> onToggle; final ValueChanged<String> onQ; final VoidCallback onDone;
  @override Widget build(BuildContext _) {
    final tp=dark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts=dark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt=dark ? FGColors.textThird   : FGColorsLight.textThird;
    final bg3=dark ? FGColors.bg3 : FGColorsLight.bg3;
    final bg4=dark ? FGColors.bg4 : FGColorsLight.bg4;
    final b=dark ? FGColors.border : FGColorsLight.border;
    final b2=dark ? FGColors.border2 : FGColorsLight.border2;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 40),
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Hdr(emoji: '\ud83d\udee1\ufe0f', title: 'One last\nthing',
          sub: 'Add a security question to recover your PIN if you forget it. Optional but smart.', dark: dark),
        const SizedBox(height: 26),
        GestureDetector(onTap: () => onToggle(!show),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280), curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: show ? p.withOpacity(0.07) : bg3,
              borderRadius: FGRadius.lg,
              border: Border.all(color: show ? p.withOpacity(0.35) : b, width: show ? 1.5 : 1)),
            child: Row(children: [
              AnimatedContainer(duration: const Duration(milliseconds: 280),
                width: 42, height: 42,
                decoration: BoxDecoration(color: show ? p.withOpacity(0.12) : bg4, borderRadius: FGRadius.sm),
                child: Icon(show ? Icons.security_rounded : Icons.security_outlined,
                  color: show ? pL : tt, size: 20)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PIN recovery question', style: TextStyle(fontFamily: 'DM Sans',
                  fontSize: 13, fontWeight: FontWeight.w600, color: show ? pL : tp)),
                const SizedBox(height: 2),
                Text('Reset PIN without losing data', style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: tt)),
              ])),
              _SwW(v: show, p: p, onC: onToggle),
            ]))),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: show ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            _Lbl('Security question', tt),
            Container(padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: bg4, borderRadius: FGRadius.md, border: Border.all(color: b2)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(value: selQ, isExpanded: true, dropdownColor: bg3,
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: tp),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: tt),
                  onChanged: (v) { if (v != null) onQ(v); },
                  items: _kQ.map((q) => DropdownMenuItem(value: q,
                    child: Text(q, overflow: TextOverflow.ellipsis))).toList()))),
            const SizedBox(height: 12),
            _Lbl('Your answer', tt),
            TextField(controller: ctrl, cursorColor: p,
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: tp),
              decoration: InputDecoration(
                hintText: 'Type your answer', hintStyle: TextStyle(color: tt, fontSize: 13),
                filled: true, fillColor: bg4,
                border: OutlineInputBorder(borderRadius: FGRadius.md, borderSide: BorderSide(color: b2)),
                enabledBorder: OutlineInputBorder(borderRadius: FGRadius.md, borderSide: BorderSide(color: b2)),
                focusedBorder: OutlineInputBorder(borderRadius: FGRadius.md, borderSide: BorderSide(color: p, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14))),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.lock_outline_rounded, size: 11, color: tt), const SizedBox(width: 5),
              Text('Encrypted \u00b7 on device only', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: tt)),
            ]),
          ])),
        const SizedBox(height: 28),
        _RBtn(label: loading ? 'Setting up\u2026' : 'Finish setup \ud83c\udf89', p: p, loading: loading, onTap: loading ? () {} : onDone),
        const SizedBox(height: 14),
        Center(child: GestureDetector(onTap: loading ? null : onDone,
          child: Text('Skip for now', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
            color: tt, decoration: TextDecoration.underline, decorationColor: tt)))),
      ]));
  }
  Widget _Lbl(String t, Color c) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(t.toUpperCase(), style: TextStyle(fontFamily: 'Syne', fontSize: 10,
      fontWeight: FontWeight.w700, color: c, letterSpacing: 0.12)));
}

// ─────────────────────────────────────────────
//  STEP 4 — DONE
// ─────────────────────────────────────────────
class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.name, required this.dark, required this.p,
    required this.pL, required this.scale, required this.loading});
  final String name; final bool dark, loading; final Color p, pL;
  final Animation<double> scale;
  @override Widget build(BuildContext _) {
    final tp=dark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts=dark ? FGColors.textSecond  : FGColorsLight.textSecond;
    return Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ScaleTransition(scale: scale,
          child: Container(width: 112, height: 112,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: LinearGradient(colors: [p, pL], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(color: p.withOpacity(0.5), blurRadius: 40, spreadRadius: 4),
                BoxShadow(color: p.withOpacity(0.2), blurRadius: 72, spreadRadius: 16),
              ]),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 56))),
        const SizedBox(height: 30),
        Text("You're all set,", style: TextStyle(fontFamily: 'DM Sans', fontSize: 16, color: ts)),
        const SizedBox(height: 4),
        Text(name, style: TextStyle(fontFamily: 'Syne', fontSize: 36, fontWeight: FontWeight.w800, color: tp)),
        const SizedBox(height: 14),
        Text('Opening your dashboard\u2026', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: ts)),
        const SizedBox(height: 32),
        if (loading) SizedBox(width: 26, height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: p)),
      ])));
  }
}

// ─────────────────────────────────────────────
//  NUMPAD
// ─────────────────────────────────────────────
class _Numpad extends StatefulWidget {
  const _Numpad({required this.onKey, required this.dark, required this.p});
  final void Function(String) onKey; final bool dark; final Color p;
  @override State<_Numpad> createState() => _NpS();
}
class _NpS extends State<_Numpad> {
  String? _hit;
  void _tap(String k) {
    setState(() => _hit = k);
    widget.onKey(k);
    Future.delayed(const Duration(milliseconds: 110), () { if (mounted) setState(() => _hit = null); });
  }
  @override Widget build(BuildContext _) {
    final bg3=widget.dark ? FGColors.bg3 : FGColorsLight.bg3;
    final b=widget.dark ? FGColors.border : FGColorsLight.border;
    final tp=widget.dark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts=widget.dark ? FGColors.textSecond : FGColorsLight.textSecond;
    final p=widget.p;
    const keys = ['1','2','3','4','5','6','7','8','9','','0','\u232b'];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 310),
      child: GridView.count(
        crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.65,
        children: keys.map((k) {
          if (k.isEmpty) return const SizedBox();
          final isDel=k=='\u232b'; final hit=_hit==k;
          return GestureDetector(onTap: () => _tap(k),
            child: AnimatedContainer(duration: const Duration(milliseconds: 80),
              decoration: BoxDecoration(
                color: hit ? p.withOpacity(0.18) : isDel ? Colors.transparent : bg3,
                borderRadius: FGRadius.md,
                border: Border.all(color: hit ? p.withOpacity(0.5) : isDel ? Colors.transparent : b),
                boxShadow: hit ? [BoxShadow(color: p.withOpacity(0.22), blurRadius: 10)] : []),
              child: Center(child: isDel
                ? Icon(Icons.backspace_outlined, color: hit ? p : ts, size: 20)
                : Text(k, style: TextStyle(fontFamily: 'Syne', fontSize: 22,
                    fontWeight: FontWeight.w700, color: hit ? p : tp)))));
        }).toList()));
  }
}

// ─────────────────────────────────────────────
//  SHARED
// ─────────────────────────────────────────────
class _RBtn extends StatefulWidget {
  const _RBtn({required this.label, required this.p, required this.onTap, this.loading=false});
  final String label; final Color p; final VoidCallback onTap; final bool loading;
  @override State<_RBtn> createState() => _RBS();
}
class _RBS extends State<_RBtn> {
  bool _dn=false;
  @override Widget build(BuildContext _) => GestureDetector(
    onTapDown: (_) => setState(() => _dn=true),
    onTapUp: (_) { setState(() => _dn=false); if (!widget.loading) widget.onTap(); },
    onTapCancel: () => setState(() => _dn=false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      transform: Matrix4.identity()..scale(_dn ? 0.97 : 1.0),
      transformAlignment: Alignment.center,
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.p, Color.lerp(widget.p, const Color(0xFF18005A), 0.38)!],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: FGRadius.lg,
        boxShadow: _dn ? [] : [
          BoxShadow(color: widget.p.withOpacity(0.40), blurRadius: 22, offset: const Offset(0, 7)),
          BoxShadow(color: widget.p.withOpacity(0.16), blurRadius: 48, offset: const Offset(0, 16)),
        ]),
      child: widget.loading
        ? const Center(child: SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
        : Center(child: Text(widget.label, style: const TextStyle(fontFamily: 'Syne',
            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2)))));
}

class _SwW extends StatelessWidget {
  const _SwW({required this.v, required this.p, required this.onC});
  final bool v; final Color p; final ValueChanged<bool> onC;
  @override Widget build(BuildContext _) => GestureDetector(
    onTap: () => onC(!v),
    child: AnimatedContainer(duration: const Duration(milliseconds: 240),
      width: 46, height: 26, padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: v ? p : Colors.grey.withOpacity(0.28), borderRadius: FGRadius.full),
      child: AnimatedAlign(duration: const Duration(milliseconds: 240), curve: Curves.easeInOut,
        alignment: v ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(width: 20, height: 20,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,1))])))));
}

class _ErrW extends StatelessWidget {
  const _ErrW(this.msg, {required this.dark});
  final String msg; final bool dark;
  @override Widget build(BuildContext _) {
    final red=dark ? FGColors.red : FGColorsLight.red;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline_rounded, color: red, size: 14), const SizedBox(width: 6),
      Flexible(child: Text(msg, style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: red, height: 1.4))),
    ]);
  }
}