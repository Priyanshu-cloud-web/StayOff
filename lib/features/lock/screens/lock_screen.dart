import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusguard/core/theme/app_theme.dart';
import 'package:focusguard/shared/widgets/fg_widgets.dart';
import 'package:focusguard/features/lock/providers/lock_provider.dart';

class LockScreen extends ConsumerWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(lockProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? FGColors.bg : FGColorsLight.bg;
    final tp     = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts     = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Lock', style: TextStyle(fontFamily: 'Syne',
                fontSize: 20, fontWeight: FontWeight.w700, color: tp)),
              Text('Commit to blocking. Make it count.',
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: ts)),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
              physics: const BouncingScrollPhysics(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Active lock status
                if (state.isLocked) ...[
                  _ActiveLockCard(state: state, isDark: isDark),
                  const SizedBox(height: 16),
                ],

                // Set new lock
                FGSectionLabel(state.isLocked ? 'Extend commitment period' : 'Set a commitment period', topPad: 4),
                _SetLockCard(isDark: isDark),
                const SizedBox(height: 16),

                // Why use this
                const FGSectionLabel('Why use Commitment Lock?'),
                _WhyCard(isDark: isDark),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ActiveLockCard extends ConsumerWidget {
  const _ActiveLockCard({required this.state, required this.isDark});
  final LockState state;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p   = isDark ? FGColors.purple      : FGColorsLight.purple;
    final pL  = isDark ? FGColors.purpleLight : FGColorsLight.purpleLight;
    final bg3 = isDark ? FGColors.bg3         : FGColorsLight.bg3;
    final b   = isDark ? FGColors.border      : FGColorsLight.border;
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts  = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt  = isDark ? FGColors.textThird   : FGColorsLight.textThird;

    final expiry = state.expiryDate!;
    final total = expiry.difference(DateTime.now());
    final progress = 1.0 - (total.inSeconds / (30 * 24 * 3600)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.withOpacity(0.06),
        borderRadius: FGRadius.xl,
        border: Border.all(color: p.withOpacity(0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42,
            decoration: BoxDecoration(color: p.withOpacity(0.12),
              borderRadius: FGRadius.md),
            child: const Center(child: Text('🔒', style: TextStyle(fontSize: 20)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Commitment lock active · ${state.remainingLabel} remaining',
              style: TextStyle(fontFamily: 'Syne', fontSize: 15,
                fontWeight: FontWeight.w700, color: pL)),
            const SizedBox(height: 3),
            Text('Expires ${_fmt(expiry)}',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: ts)),
          ])),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: FGRadius.full,
          child: LinearProgressIndicator(
            value: progress, minHeight: 6,
            backgroundColor: isDark ? FGColors.bg4 : FGColorsLight.bg4,
            valueColor: AlwaysStoppedAnimation(p))),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Started', style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, color: tt)),
          Text('Ends ${_fmt(expiry)}', style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, color: tt)),
        ]),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? FGColors.bg4 : FGColorsLight.bg4,
            borderRadius: FGRadius.sm),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, size: 14,
              color: isDark ? FGColors.textThird : FGColorsLight.textThird),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'You cannot remove blocked sites until the lock expires. You can still add new ones.',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 11,
                color: isDark ? FGColors.textThird : FGColorsLight.textThird, height: 1.4))),
          ])),
      ]));
  }

  String _fmt(DateTime d) =>
    '${d.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month-1]} ${d.year}';
}

class _SetLockCard extends ConsumerStatefulWidget {
  const _SetLockCard({required this.isDark});
  final bool isDark;
  @override
  ConsumerState<_SetLockCard> createState() => _SetLockCardState();
}

class _SetLockCardState extends ConsumerState<_SetLockCard> {
  int _days = 0, _months = 0, _years = 0;
  bool _loading = false;

  DateTime get _expiry {
    final now = DateTime.now();
    return DateTime(now.year + _years, now.month + _months, now.day + _days);
  }

  bool get _hasValue => _days > 0 || _months > 0 || _years > 0;

  String get _previewLabel {
    if (!_hasValue) return 'Set a duration first';
    final diff = _expiry.difference(DateTime.now());
    final d = diff.inDays;
    final e = _expiry;
    return 'Locks until ${e.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][e.month-1]} ${e.year}  ·  $d days';
  }

  Future<void> _confirm() async {
    if (!_hasValue) return;
    // If lock already active, only allow extending (new expiry must be later)
    final lock = ref.read(lockProvider);
    if (lock.isLocked && lock.expiryDate != null) {
      if (_expiry.isBefore(lock.expiryDate!) || _expiry.isAtSameMomentAs(lock.expiryDate!)) {
        return; // Silently ignore — button is disabled in this case
      }
    }
    setState(() => _loading = true);
    await ref.read(lockProvider.notifier).setLock(_expiry);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final b   = isDark ? FGColors.border  : FGColorsLight.border;
    final b2  = isDark ? FGColors.border2 : FGColorsLight.border2;
    final bg4 = isDark ? FGColors.bg4 : FGColorsLight.bg4;
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts  = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt  = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final p   = isDark ? FGColors.purple      : FGColorsLight.purple;
    final pL  = isDark ? FGColors.purpleLight : FGColorsLight.purpleLight;
    final amber = isDark ? FGColors.amber : FGColorsLight.amber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg3, borderRadius: FGRadius.lg,
        border: Border.all(color: b)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          ref.watch(lockProvider).isLocked
            ? 'Lock is active. You can only extend, not shorten, the commitment period.'
            : 'Once locked, you cannot change your blocklist until the period ends. Think carefully before committing.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: ts, height: 1.5)),
        const SizedBox(height: 20),

        // Duration inputs
        Text('LOCK DURATION', style: TextStyle(fontFamily: 'Syne', fontSize: 10,
          fontWeight: FontWeight.w700, color: tt, letterSpacing: 0.1)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _DurationField(label: 'Days', value: _days,
            onChanged: (v) => setState(() => _days = v), isDark: isDark)),
          const SizedBox(width: 10),
          Expanded(child: _DurationField(label: 'Months', value: _months,
            onChanged: (v) => setState(() => _months = v), isDark: isDark)),
          const SizedBox(width: 10),
          Expanded(child: _DurationField(label: 'Years', value: _years,
            onChanged: (v) => setState(() => _years = v), isDark: isDark)),
        ]),
        const SizedBox(height: 14),

        // Quick presets
        Text('QUICK PRESETS', style: TextStyle(fontFamily: 'Syne', fontSize: 10,
          fontWeight: FontWeight.w700, color: tt, letterSpacing: 0.1)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Preset('7 days',   () => setState(() { _days=7;  _months=0; _years=0; }), isDark),
          _Preset('14 days',  () => setState(() { _days=14; _months=0; _years=0; }), isDark),
          _Preset('1 month',  () => setState(() { _days=0;  _months=1; _years=0; }), isDark),
          _Preset('3 months', () => setState(() { _days=0;  _months=3; _years=0; }), isDark),
          _Preset('6 months', () => setState(() { _days=0;  _months=6; _years=0; }), isDark),
          _Preset('1 year',   () => setState(() { _days=0;  _months=0; _years=1; }), isDark),
        ]),
        const SizedBox(height: 16),

        // Preview
        if (_hasValue) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.withOpacity(0.07),
              borderRadius: FGRadius.sm,
              border: Border.all(color: p.withOpacity(0.2))),
            child: Row(children: [
              Icon(Icons.schedule_rounded, size: 14, color: pL),
              const SizedBox(width: 8),
              Expanded(child: Text(_previewLabel,
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: pL))),
            ])),
          const SizedBox(height: 14),
        ],

        // Warning
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: amber.withOpacity(0.08),
            borderRadius: FGRadius.sm,
            border: Border.all(color: amber.withOpacity(0.3))),
          child: Row(children: [
            Icon(Icons.warning_amber_rounded, color: amber, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'The lock is permanent once set. You cannot undo it until the period expires.',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: amber, height: 1.4))),
          ])),
        const SizedBox(height: 16),

        () {
          final lockState = ref.watch(lockProvider);
          final isExtend = lockState.isLocked;
          final canExtend = !isExtend || (lockState.expiryDate != null && _expiry.isAfter(lockState.expiryDate!));
          final active = _hasValue && canExtend;
          return Opacity(
            opacity: active ? 1.0 : 0.4,
            child: FGButton(
              label: isExtend ? '🔒  Extend lock' : '🔒  Confirm & lock',
              loading: _loading,
              onTap: active ? _confirm : () {}));
        }(),
      ]));
  }

  Widget _Preset(String label, VoidCallback onTap, bool isDark) {
    final b2  = isDark ? FGColors.border2 : FGColorsLight.border2;
    final bg4 = isDark ? FGColors.bg4 : FGColorsLight.bg4;
    final ts  = isDark ? FGColors.textSecond : FGColorsLight.textSecond;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: bg4, borderRadius: FGRadius.full,
          border: Border.all(color: b2)),
        child: Text(label, style: TextStyle(fontFamily: 'DM Sans',
          fontSize: 12, fontWeight: FontWeight.w500, color: ts))));
  }
}

class _DurationField extends StatelessWidget {
  const _DurationField({required this.label, required this.value,
    required this.onChanged, required this.isDark});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg4 = isDark ? FGColors.bg4 : FGColorsLight.bg4;
    final b2  = isDark ? FGColors.border2 : FGColorsLight.border2;
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final tt  = isDark ? FGColors.textThird : FGColorsLight.textThird;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: tt)),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: value == 0 ? '' : '$value',
        keyboardType: TextInputType.number,
        style: TextStyle(fontFamily: 'Syne', fontSize: 16,
          fontWeight: FontWeight.w700, color: tp),
        onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: TextStyle(color: tt, fontFamily: 'Syne', fontSize: 16),
          filled: true, fillColor: bg4,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: FGRadius.sm, borderSide: BorderSide(color: b2)),
          enabledBorder: OutlineInputBorder(borderRadius: FGRadius.sm, borderSide: BorderSide(color: b2)),
          focusedBorder: OutlineInputBorder(borderRadius: FGRadius.sm,
            borderSide: BorderSide(color: isDark ? FGColors.purple : FGColorsLight.purple)))),
    ]);
  }
}

class _WhyCard extends StatelessWidget {
  const _WhyCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final b   = isDark ? FGColors.border : FGColorsLight.border;
    final ts  = isDark ? FGColors.textSecond : FGColorsLight.textSecond;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg3, borderRadius: FGRadius.lg, border: Border.all(color: b)),
      child: Column(children: [
        _WhyRow('🧠', 'Removes the option to quit', 'When you can\'t remove blocks, you stop trying. The urge passes in minutes.', isDark),
        const SizedBox(height: 12),
        _WhyRow('📚', 'Used in habit research', 'Commitment devices are proven to improve self-control in academic studies.', isDark),
        const SizedBox(height: 12),
        _WhyRow('🏆', 'Makes it real', '7-day focus streaks mean more when removing the blocklist wasn\'t an option.', isDark),
      ]));
  }

  Widget _WhyRow(String e, String t, String b, bool isDark) =>
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(e, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600,
          color: isDark ? FGColors.textPrimary : FGColorsLight.textPrimary)),
        const SizedBox(height: 2),
        Text(b, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12,
          color: isDark ? FGColors.textSecond : FGColorsLight.textSecond, height: 1.4)),
      ])),
    ]);
}