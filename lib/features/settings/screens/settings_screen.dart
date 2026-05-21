import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusguard/core/theme/app_theme.dart';
import 'package:focusguard/core/theme/theme_provider.dart';
import 'package:focusguard/core/providers/app_state_provider.dart';
import 'package:focusguard/shared/widgets/fg_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final user       = ref.watch(appStateProvider.notifier).currentUser;
    final bg  = isDark ? FGColors.bg  : FGColorsLight.bg;
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final b   = isDark ? FGColors.border  : FGColorsLight.border;
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts  = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt  = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final p   = isDark ? FGColors.purple      : FGColorsLight.purple;
    final pL  = isDark ? FGColors.purpleLight : FGColorsLight.purpleLight;
    final red = isDark ? FGColors.red         : FGColorsLight.red;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
          physics: const BouncingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Settings', style: TextStyle(fontFamily: 'Syne', fontSize: 22,
              fontWeight: FontWeight.w700, color: tp)),
            const SizedBox(height: 20),

            // ── PROFILE ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: bg3, borderRadius: FGRadius.lg, border: Border.all(color: b)),
              child: Row(children: [
                Container(width: 50, height: 50,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [p, pL],
                      begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: Center(child: Text(
                    (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 22,
                      fontWeight: FontWeight.w800, color: Colors.white)))),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.name ?? 'User', style: TextStyle(fontFamily: 'Syne',
                    fontSize: 16, fontWeight: FontWeight.w700, color: tp)),
                  Text('Android · StayOff', style: TextStyle(fontFamily: 'DM Sans',
                    fontSize: 12, color: ts)),
                ]),
              ])),
            const SizedBox(height: 24),

            // ── APPEARANCE ──
            _Label('Appearance', tt),
            _Card(bg3: bg3, b: b, children: [
              _Row(child: Row(children: [
                Icon(isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 20, color: ts),
                const SizedBox(width: 12),
                Expanded(child: Text(isDarkMode ? 'Dark mode' : 'Light mode',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
                    fontWeight: FontWeight.w600, color: tp))),
                Switch(value: isDarkMode,
                  onChanged: (_) => ref.read(themeProvider.notifier).toggle()),
              ])),
            ]),
            const SizedBox(height: 20),

            // ── FEATURES ──
            _Label('Features', tt),
            _Card(bg3: bg3, b: b, children: [
              _NavRow(Icons.block_rounded, 'Blocklist', 'Block sites & URLs',
                isDark: isDark, onTap: () => context.go('/blocklist')),
              Divider(height: 1, color: b),
              _NavRow(Icons.apps_rounded, 'App Blocker', 'Block entire apps',
                isDark: isDark, onTap: () => context.go('/appblocker')),
              Divider(height: 1, color: b),
              _NavRow(Icons.shield_rounded, 'SafeGuard', 'Adult content protection',
                isDark: isDark, onTap: () => context.go('/safeguard')),
              Divider(height: 1, color: b),
              _NavRow(Icons.lock_clock_rounded, 'Commitment Lock', 'Lock blocklist for a period',
                isDark: isDark, isLast: true, onTap: () => context.go('/lock')),
            ]),
            const SizedBox(height: 20),

            // ── ABOUT ──
            _Label('About', tt),
            _Card(bg3: bg3, b: b, children: [
              _InfoRow('Version', '1.0.0', isDark: isDark),
              Divider(height: 1, color: b),
              _InfoRow('Platform', 'Android', isDark: isDark, isLast: true),
            ]),
            const SizedBox(height: 20),

            // ── LEGAL ──
            _Label('Legal', tt),
            _Card(bg3: bg3, b: b, children: [
              _NavRow(Icons.privacy_tip_outlined, 'Privacy Policy', 'How your data is handled',
                isDark: isDark, onTap: () => _showPolicy(context, isDark, tp, ts, b, bg3, _privacyPolicy)),
              Divider(height: 1, color: b),
              _NavRow(Icons.description_outlined, 'Terms of Use', 'App usage terms',
                isDark: isDark, isLast: true,
                onTap: () => _showPolicy(context, isDark, tp, ts, b, bg3, _termsOfUse)),
            ]),
            const SizedBox(height: 16),

            // Data transparency (required for Play Store VPN/A11y apps)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.withOpacity(0.06), borderRadius: FGRadius.md,
                border: Border.all(color: p.withOpacity(0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: pL),
                  const SizedBox(width: 8),
                  Text('Data & Privacy', style: TextStyle(fontFamily: 'Syne',
                    fontSize: 13, fontWeight: FontWeight.w700, color: tp)),
                ]),
                const SizedBox(height: 8),
                Text(
                  '• All data stored locally on your device\n'
                  '• VPN blocks domains — never logs your traffic\n'
                  '• Accessibility reads app names only — not passwords\n'
                  '• Nothing is ever sent to any server',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: ts, height: 1.6)),
              ])),
            const SizedBox(height: 24),

            // ── DANGER ZONE ──
            _Label('Danger zone', tt),
            Container(
              decoration: BoxDecoration(
                color: red.withOpacity(0.04), borderRadius: FGRadius.lg,
                border: Border.all(color: red.withOpacity(0.2))),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Reset StayOff', style: TextStyle(fontFamily: 'Syne',
                  fontSize: 14, fontWeight: FontWeight.w700, color: red)),
                const SizedBox(height: 6),
                Text('Clears your PIN, blocklist, and all settings. Cannot be undone.',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: ts, height: 1.4)),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _showReset(context, ref, red, isDark, b),
                  child: Container(
                    width: double.infinity, height: 44,
                    decoration: BoxDecoration(
                      color: red.withOpacity(0.1), borderRadius: FGRadius.md,
                      border: Border.all(color: red.withOpacity(0.35))),
                    child: Center(child: Text('Reset app', style: TextStyle(
                      fontFamily: 'Syne', fontSize: 13,
                      fontWeight: FontWeight.w700, color: red))))),
              ])),
          ]),
        ),
      ),
    );
  }

  // ── PRIVACY POLICY ──────────────────────────────────────────────
  static const _privacyPolicy = '''
PRIVACY POLICY
Last updated: January 2025

1. DATA WE COLLECT
StayOff does not collect or transmit any personal data.
All information — your name, PIN, blocklist, and settings — is stored
exclusively on your device using encrypted local storage.

2. VPN SERVICE
StayOff uses a local VPN tunnel to intercept DNS queries (port 53 only).
This VPN operates entirely on your device. We do not:
• Log your browsing activity or DNS queries
• Send any network data to our servers
• Share your data with third parties

3. ACCESSIBILITY SERVICE
StayOff uses Android's Accessibility Service to detect and block
Shorts, Reels, and other short-form video content.
This service:
• Reads only app names and UI element IDs
• Never reads messages, passwords, or personal data
• Stores nothing and transmits nothing

4. PERMISSIONS EXPLAINED
• Accessibility Service: Required to detect and close Shorts/Reels
• VPN Permission: Required to block websites at the network level
• Notifications: Used to confirm when content is blocked

5. THIRD-PARTY SERVICES
StayOff does not use any third-party analytics, advertising,
or data collection services.

6. CHANGES TO THIS POLICY
Any changes will be reflected in app updates.

7. CONTACT
For questions about this policy, contact the developer.
''';

  static const _termsOfUse = '''
TERMS OF USE
Last updated: May 2026

1. ACCEPTANCE
By using StayOff, you agree to these Terms of Use.

2. APP PURPOSE
StayOff is a personal productivity tool designed to help
users block distracting websites and apps.

3. PERMISSIONS
The app requires Accessibility and VPN permissions to function.
These permissions are used solely for the blocking functionality
described in this app. Granting these permissions is voluntary.

4. LIMITATIONS
StayOff blocks content on a best-effort basis:
• DNS-level blocking works in browsers but not in-app
• Accessibility blocking works for YouTube Shorts, Reels, TikTok
• App updates by YouTube/Instagram may affect detection

5. NO WARRANTY
StayOff is provided "as is" without warranty of any kind.
The developer makes no guarantee that all content will be blocked
in all circumstances.

6. ACCEPTABLE USE
You may not use StayOff to block access for others without
their knowledge or consent.

7. CHANGES
These terms may be updated. Continued use of the app means
acceptance of the updated terms.
''';

  void _showPolicy(BuildContext context, bool isDark, Color tp, Color ts,
      Color b, Color bg3, String content) {
    final bg2 = isDark ? FGColors.bg2 : FGColorsLight.bg2;
    final b2  = isDark ? FGColors.border2 : FGColorsLight.border2;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: bg2,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: b2))),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: b2, borderRadius: FGRadius.full))),
          const SizedBox(height: 4),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Text(content, style: TextStyle(fontFamily: 'DM Sans',
              fontSize: 13, color: ts, height: 1.7)))),
        ])));
  }

  // ── RESET — 3-step: PIN → type RESET → confirm ─────────────────────
  void _showReset(BuildContext context, WidgetRef ref, Color red, bool isDark, Color b) {
    final bg2  = isDark ? FGColors.bg2  : FGColorsLight.bg2;
    final bg4  = isDark ? FGColors.bg4  : FGColorsLight.bg4;
    final b2   = isDark ? FGColors.border2 : FGColorsLight.border2;
    final tp   = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts   = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt   = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final bg3  = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final bdr  = isDark ? FGColors.border : FGColorsLight.border;

    // Step 1 of 2: enter current PIN
    // Step 2 of 2: type RESET
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _ResetSheet(red: red, isDark: isDark)));
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────
Widget _Label(String t, Color c) => Padding(padding: const EdgeInsets.only(bottom: 10),
  child: Text(t.toUpperCase(), style: TextStyle(fontFamily: 'Syne', fontSize: 10,
    fontWeight: FontWeight.w700, color: c, letterSpacing: 0.1)));

class _Card extends StatelessWidget {
  const _Card({required this.bg3, required this.b, required this.children});
  final Color bg3, b; final List<Widget> children;
  @override Widget build(BuildContext _) => Container(
    decoration: BoxDecoration(color: bg3, borderRadius: FGRadius.lg, border: Border.all(color: b)),
    child: Column(children: children));
}

class _Row extends StatelessWidget {
  const _Row({required this.child});
  final Widget child;
  @override Widget build(BuildContext _) =>
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: child);
}

Widget _NavRow(IconData icon, String label, String sub,
    {required bool isDark, required VoidCallback onTap, bool isLast = false}) {
  final tp = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
  final ts = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
  final tt = isDark ? FGColors.textThird   : FGColorsLight.textThird;
  return GestureDetector(onTap: onTap,
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Icon(icon, size: 20, color: ts), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
            fontWeight: FontWeight.w600, color: tp)),
          Text(sub, style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: tt)),
        ])),
        Icon(Icons.chevron_right_rounded, size: 18, color: tt),
      ])));
}

Widget _InfoRow(String label, String value, {required bool isDark, bool isLast = false}) {
  final tp = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
  final tt = isDark ? FGColors.textThird   : FGColorsLight.textThird;
  return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: tt))),
      Text(value, style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
        fontWeight: FontWeight.w600, color: tp)),
    ]));
}

// ═══════════════════════════════════════════════════════════
//  RESET SHEET — 2-step: enter PIN then type "RESET"
// ═══════════════════════════════════════════════════════════
class _ResetSheet extends ConsumerStatefulWidget {
  const _ResetSheet({required this.red, required this.isDark});
  final Color red; final bool isDark;
  @override ConsumerState<_ResetSheet> createState() => _ResetSheetState();
}

class _ResetSheetState extends ConsumerState<_ResetSheet> {
  int _step = 0; // 0=PIN, 1=type RESET
  String _pin = '';
  bool _pinErr = false;
  final _resetCtrl = TextEditingController();

  @override void dispose() { _resetCtrl.dispose(); super.dispose(); }

  void _onKey(String k) {
    setState(() {
      _pinErr = false;
      if (k == '⌫') { if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length-1); return; }
      if (_pin.length < 4) {
        _pin += k;
        if (_pin.length == 4) Future.delayed(const Duration(milliseconds: 80), _checkPin);
      }
    });
  }

  Future<void> _checkPin() async {
    final ok = await ref.read(appStateProvider.notifier).verifyPin(_pin);
    if (ok) setState(() => _step = 1);
    else setState(() { _pinErr = true; _pin = ''; });
  }

  @override
  Widget build(BuildContext context) {
    final red = widget.red; final isDark = widget.isDark;
    final bg2 = isDark ? FGColors.bg2 : FGColorsLight.bg2;
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final bg4 = isDark ? FGColors.bg4 : FGColorsLight.bg4;
    final b   = isDark ? FGColors.border  : FGColorsLight.border;
    final b2  = isDark ? FGColors.border2 : FGColorsLight.border2;
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts  = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt  = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final bot = MediaQuery.of(context).viewInsets.bottom;

    return StatefulBuilder(builder: (ctx, setSt) {
      final canReset = _resetCtrl.text.trim().toUpperCase() == 'RESET';
      return Container(
        decoration: BoxDecoration(color: bg2,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: b2))),
        padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bot),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: b2, borderRadius: FGRadius.full))),
          const SizedBox(height: 18),
          const Text('⚠️', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(_step == 0 ? 'Step 1 of 2 · Confirm your PIN'
              : 'Step 2 of 2 · Type RESET to confirm',
            style: TextStyle(fontFamily: 'Syne', fontSize: 17,
              fontWeight: FontWeight.w700, color: tp),
            textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(_step == 0
            ? 'Enter your app PIN to prove it\'s you.'
            : 'This will permanently delete all data. Cannot be undone.',
            style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: ts, height: 1.4),
            textAlign: TextAlign.center),
          const SizedBox(height: 20),

          if (_step == 0) ...[
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final f = i < _pin.length;
                return Container(margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: f ? 18 : 14, height: f ? 18 : 14,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: _pinErr ? red : f ? red : Colors.transparent,
                    border: Border.all(color: _pinErr ? red : f ? red : b2, width: 2)));
              })),
            if (_pinErr) ...[
              const SizedBox(height: 10),
              Text('Incorrect PIN', style: TextStyle(fontFamily: 'DM Sans',
                fontSize: 13, color: red)),
            ],
            const SizedBox(height: 16),
            GridView.count(crossAxisCount: 3, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.0,
              children: ['1','2','3','4','5','6','7','8','9','','0','⌫'].map((k) {
                if (k.isEmpty) return const SizedBox();
                final isDel = k == '⌫';
                return GestureDetector(onTap: () { _onKey(k); setSt(() {}); },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDel ? Colors.transparent : bg3,
                      borderRadius: FGRadius.sm,
                      border: Border.all(color: isDel ? Colors.transparent : b)),
                    child: Center(child: isDel
                      ? Icon(Icons.backspace_outlined, color: tt, size: 18)
                      : Text(k, style: TextStyle(fontFamily: 'Syne',
                          fontSize: 20, fontWeight: FontWeight.w700, color: tp)))));
              }).toList()),
          ] else ...[
            TextField(controller: _resetCtrl,
              onChanged: (_) => setSt(() {}),
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Syne', fontSize: 20,
                fontWeight: FontWeight.w700, color: red, letterSpacing: 3),
              decoration: InputDecoration(
                hintText: 'Type RESET here',
                hintStyle: TextStyle(color: tt, letterSpacing: 0,
                  fontFamily: 'DM Sans', fontSize: 13),
                filled: true, fillColor: bg4,
                border: OutlineInputBorder(borderRadius: FGRadius.md, borderSide: BorderSide(color: b2)),
                enabledBorder: OutlineInputBorder(borderRadius: FGRadius.md, borderSide: BorderSide(color: b2)),
                focusedBorder: OutlineInputBorder(borderRadius: FGRadius.md,
                  borderSide: BorderSide(color: red, width: 1.5)))),
            const SizedBox(height: 16),
            Opacity(opacity: canReset ? 1.0 : 0.35,
              child: GestureDetector(
                onTap: canReset ? () {
                  Navigator.pop(context);
                  ref.read(appStateProvider.notifier).resetApp();
                } : null,
                child: Container(width: double.infinity, height: 50,
                  decoration: BoxDecoration(color: red, borderRadius: FGRadius.md),
                  child: const Center(child: Text('Confirm reset',
                    style: TextStyle(fontFamily: 'Syne', fontSize: 14,
                      fontWeight: FontWeight.w700, color: Colors.white)))))),
          ],
          const SizedBox(height: 12),
          GestureDetector(onTap: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontFamily: 'DM Sans',
              fontSize: 13, color: tt, decoration: TextDecoration.underline,
              decorationColor: tt))),
        ]));
    });
  }
}