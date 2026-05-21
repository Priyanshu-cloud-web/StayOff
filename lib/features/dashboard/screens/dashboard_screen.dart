import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusguard/core/theme/app_theme.dart';
import 'package:focusguard/core/theme/theme_provider.dart';
import 'package:focusguard/core/providers/app_state_provider.dart';
import 'package:focusguard/features/dashboard/providers/dashboard_provider.dart';
import 'package:focusguard/features/appblocker/providers/appblocker_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash   = ref.watch(dashboardProvider);
    final user   = ref.watch(appStateProvider.notifier).currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? FGColors.bg : FGColorsLight.bg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          _TopBar(user: user, isDark: isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              physics: const BouncingScrollPhysics(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Accessibility permission nudge (if not granted)
                _A11yNudge(isDark: isDark),
                // Focus status hero card
                _HeroCard(data: dash, isDark: isDark),
                const SizedBox(height: 12),
                // 2x2 stat grid
                _StatGrid(data: dash, isDark: isDark),
                const SizedBox(height: 20),
                // Quick actions
                _SectionLabel('Quick actions', isDark: isDark),
                const SizedBox(height: 10),
                _ActionGrid(isDark: isDark),
                const SizedBox(height: 20),
                // Quote
                _QuoteCard(isDark: isDark, quote: dash.quote, ref: ref),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── TOP BAR ───────────────────────────────────
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.user, required this.isDark});
  final AppUser? user;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour  = DateTime.now().hour;
    final greet = hour < 5 ? 'Up late' : hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final first = user?.name.split(' ').first ?? 'there';
    final tp = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final tt = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final ts = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final b   = isDark ? FGColors.border : FGColorsLight.border;
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(greet, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12,
            fontWeight: FontWeight.w500, color: tt, letterSpacing: 0.3)),
          const SizedBox(height: 1),
          Text('$first 👋', style: TextStyle(fontFamily: 'Syne', fontSize: 24,
            fontWeight: FontWeight.w800, color: tp, height: 1.1)),
        ])),
        // Theme toggle
        _IconBtn(
          icon: isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          isDark: isDark, onTap: () => ref.read(themeProvider.notifier).toggle()),
        const SizedBox(width: 8),
        _IconBtn(icon: Icons.settings_outlined, isDark: isDark,
          onTap: () => context.go('/settings')),
      ]),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.isDark, required this.onTap});
  final IconData icon; final bool isDark; final VoidCallback onTap;
  @override Widget build(BuildContext _) {
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final b   = isDark ? FGColors.border : FGColorsLight.border;
    final ts  = isDark ? FGColors.textSecond : FGColorsLight.textSecond;
    return GestureDetector(onTap: onTap,
      child: Container(width: 38, height: 38,
        decoration: BoxDecoration(color: bg3, borderRadius: FGRadius.sm, border: Border.all(color: b)),
        child: Icon(icon, size: 18, color: ts)));
  }
}

// ── ACCESSIBILITY NUDGE ───────────────────────
class _A11yNudge extends ConsumerWidget {
  const _A11yNudge({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state   = ref.watch(appBlockerProvider);
    final granted = state.accessibilityPermission == PermissionStatus.granted;
    if (granted) return const SizedBox.shrink();
    final amber = isDark ? FGColors.amber : FGColorsLight.amber;
    return GestureDetector(
      onTap: () => ref.read(appBlockerProvider.notifier).openAccessibilitySettings(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: amber.withOpacity(0.08),
          borderRadius: FGRadius.md,
          border: Border.all(color: amber.withOpacity(0.3))),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: amber, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('Tap to enable Accessibility — required for Shorts blocking',
            style: TextStyle(fontFamily: 'DM Sans', fontSize: 12,
              fontWeight: FontWeight.w500, color: amber, height: 1.4))),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: amber),
        ])));
  }
}

// ── HERO CARD ─────────────────────────────────
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data, required this.isDark});
  final DashboardData data; final bool isDark;
  @override Widget build(BuildContext _) {
    final p   = isDark ? FGColors.purple : FGColorsLight.purple;
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final b   = isDark ? FGColors.border : FGColorsLight.border;
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts  = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt  = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: bg3, borderRadius: FGRadius.xl, border: Border.all(color: b)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FOCUS STATUS', style: TextStyle(fontFamily: 'Syne', fontSize: 10,
            fontWeight: FontWeight.w700, color: tt, letterSpacing: 0.12)),
          const SizedBox(height: 6),
          Text('All systems active', style: TextStyle(fontFamily: 'Syne', fontSize: 17,
            fontWeight: FontWeight.w800, color: tp)),
          const SizedBox(height: 4),
          Text('${data.distractionsBlockedToday} distractions blocked today',
            style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: ts)),
        ])),
        Container(width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.withOpacity(0.12),
            border: Border.all(color: p.withOpacity(0.3))),
          child: const Center(child: Text('🎯', style: TextStyle(fontSize: 24)))),
      ]));
  }
}

// ── STAT GRID ─────────────────────────────────
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.data, required this.isDark});
  final DashboardData data; final bool isDark;
  @override Widget build(BuildContext context) {
    final red   = isDark ? FGColors.red   : FGColorsLight.red;
    final amber = isDark ? FGColors.amber : FGColorsLight.amber;
    final pL    = isDark ? FGColors.purpleLight : FGColorsLight.purpleLight;
    final teal  = isDark ? FGColors.teal  : FGColorsLight.teal;
    return Column(children: [
      Row(children: [
        Expanded(child: _Stat(icon: '🚫', value: '${data.sitesBlocked}',
          label: 'Sites blocked', accent: red, isDark: isDark)),
        const SizedBox(width: 10),
        Expanded(child: _Stat(icon: '📱', value: '${data.appsBlocked}',
          label: 'Apps blocked', accent: amber, isDark: isDark)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _Stat(icon: '🔒', value: data.lockRemaining,
          label: 'Lock remaining', accent: pL, isDark: isDark, valueSize: 22)),
        const SizedBox(width: 10),
        Expanded(child: _Stat(icon: '🛡️',
          value: data.safeguardActive ? 'ON' : 'Off',
          label: 'SafeGuard',
          accent: data.safeguardActive ? teal : (isDark ? FGColors.textSecond : FGColorsLight.textSecond),
          isDark: isDark, valueSize: 18)),
      ]),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label,
    required this.accent, required this.isDark, this.valueSize = 28});
  final String icon, value, label; final Color accent; final bool isDark; final double valueSize;
  @override Widget build(BuildContext _) {
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final b   = isDark ? FGColors.border : FGColorsLight.border;
    final tt  = isDark ? FGColors.textThird : FGColorsLight.textThird;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg3, borderRadius: FGRadius.lg, border: Border.all(color: b)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: valueSize,
          fontWeight: FontWeight.w800, color: accent, height: 1.0)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: tt)),
      ]));
  }
}

// ── SECTION LABEL ─────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.isDark});
  final String text; final bool isDark;
  @override Widget build(BuildContext _) => Text(text.toUpperCase(),
    style: TextStyle(fontFamily: 'Syne', fontSize: 11, fontWeight: FontWeight.w700,
      color: isDark ? FGColors.textThird : FGColorsLight.textThird, letterSpacing: 0.12));
}

// ── ACTION GRID ───────────────────────────────
class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.isDark});
  final bool isDark;
  @override Widget build(BuildContext context) {
    final p = isDark ? FGColors.purple : FGColorsLight.purple;
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10,
      childAspectRatio: 1.65,
      children: [
        _Action(icon: '🚫', title: 'Blocklist', sub: 'Block sites & URLs',
          isPrimary: true, isDark: isDark, onTap: () => context.go('/blocklist')),
        _Action(icon: '📱', title: 'App Blocker', sub: 'Block entire apps',
          isDark: isDark, onTap: () => context.go('/appblocker')),
        _Action(icon: '🔞', title: 'SafeGuard', sub: 'Adult content lock',
          isDanger: true, isDark: isDark, onTap: () => context.go('/safeguard')),
        _Action(icon: '🔒', title: 'Commitment', sub: 'Lock your rules',
          isDark: isDark, onTap: () => context.go('/lock')),
      ]);
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.title, required this.sub,
    required this.isDark, required this.onTap,
    this.isPrimary = false, this.isDanger = false});
  final String icon, title, sub; final bool isDark, isPrimary, isDanger;
  final VoidCallback onTap;
  @override Widget build(BuildContext _) {
    final p  = isDark ? FGColors.purple : FGColorsLight.purple;
    final red= isDark ? FGColors.red    : FGColorsLight.red;
    final bg = isPrimary ? p.withOpacity(0.10) : isDanger ? red.withOpacity(0.08)
        : isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final bdr= isPrimary ? p.withOpacity(0.28) : isDanger ? red.withOpacity(0.22)
        : isDark ? FGColors.border : FGColorsLight.border;
    final tp = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final tt = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    return GestureDetector(onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: FGRadius.lg, border: Border.all(color: bdr)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontFamily: 'Syne', fontSize: 13,
            fontWeight: FontWeight.w700, color: tp)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: tt)),
        ])));
  }
}

// ── QUOTE CARD ────────────────────────────────
class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.isDark, required this.quote, required this.ref});
  final bool isDark; final String quote; final WidgetRef ref;
  @override Widget build(BuildContext _) {
    final p   = isDark ? FGColors.purple : FGColorsLight.purple;
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final b   = isDark ? FGColors.border : FGColorsLight.border;
    final ts  = isDark ? FGColors.textSecond : FGColorsLight.textSecond;
    final tt  = isDark ? FGColors.textThird  : FGColorsLight.textThird;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: bg3, borderRadius: FGRadius.lg, border: Border.all(color: b)),
      child: Row(children: [
        Container(width: 3, height: 48,
          decoration: BoxDecoration(color: p, borderRadius: FGRadius.full)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('"$quote"', style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
            fontStyle: FontStyle.italic, color: ts, height: 1.5)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => ref.read(dashboardProvider.notifier).refreshQuote(),
            child: Row(children: [
              Text('Daily quote', style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: tt)),
              const SizedBox(width: 5),
              Icon(Icons.refresh_rounded, size: 12, color: tt),
            ])),
        ])),
      ]));
  }
}