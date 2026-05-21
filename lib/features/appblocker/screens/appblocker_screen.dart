import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusguard/core/theme/app_theme.dart';
import 'package:focusguard/shared/widgets/fg_widgets.dart';
import 'package:focusguard/features/appblocker/models/blocked_app.dart';
import 'package:focusguard/features/appblocker/providers/appblocker_provider.dart';

class AppBlockerScreen extends ConsumerWidget {
  const AppBlockerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(appBlockerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? FGColors.bg : FGColorsLight.bg,
      body: SafeArea(
        child: Column(children: [
          // ── TOP BAR ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('App Blocker',
                    style: Theme.of(context).textTheme.titleLarge),
                  Text('${state.totalBlocked} app${state.totalBlocked == 1 ? '' : 's'} blocked',
                    style: Theme.of(context).textTheme.bodySmall),
                ],
              )),
              // Add app button
              GestureDetector(
                onTap: () => _showAddSheet(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? FGColors.bg3 : FGColorsLight.bg3,
                    borderRadius: FGRadius.sm,
                    border: Border.all(color: isDark ? FGColors.border : FGColorsLight.border)),
                  child: Icon(Icons.add_rounded,
                    color: isDark ? FGColors.purple : FGColorsLight.purple, size: 20))),
              const SizedBox(width: 8),
              FGIconBtn(
                icon: Icons.info_outline_rounded,
                onTap: () => _showHowItWorks(context),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: state.isLoading
                ? const _AppBlockerSkeleton()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── PERMISSION BANNERS ──
                        if (!state.a11yGranted)
                          _PermissionBanners(state: state),

                        // ── BLOCKED APPS ──
                        if (state.blockedApps.isNotEmpty) ...[
                          const FGSectionLabel('Blocked apps', topPad: 4),
                          ...state.blockedApps.map(
                            (app) => _AppRow(app: app)),
                        ] else
                          const _EmptyBlockedState(),

                        // ── HOW IT WORKS ──
                        const FGSectionLabel('How it works', topPad: 4),
                        _HowItWorksCard(),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _AddAppSheet()));
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _HowItWorksSheet(),
    );
  }
}

// ── PERMISSION BANNERS ────────────────────────
class _PermissionBanners extends ConsumerWidget {
  const _PermissionBanners({required this.state});
  final AppBlockerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appBlockerProvider.notifier);
    return Column(children: [
      if (!state.a11yGranted)
        _PermissionBanner(
          icon: Icons.accessibility_new_rounded,
          title: 'Accessibility service required',
          subtitle: 'Required to block apps and Shorts/Reels.',
          actionLabel: 'Enable →',
          onTap: notifier.openAccessibilitySettings,
          color: FGColors.purple,
        ),
    ]);
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    required this.color,
  });
  final IconData icon;
  final String title, subtitle, actionLabel;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: FGRadius.md,
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: TextStyle(
                  fontFamily: 'DM Sans', fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                )),
              const SizedBox(height: 2),
              Text(subtitle,
                style: const TextStyle(
                  fontFamily: 'DM Sans', fontSize: 11,
                  color: FGColors.textThird,
                )),
            ],
          )),
          Text(actionLabel,
            style: TextStyle(
              fontFamily: 'Syne', fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            )),
        ]),
      ),
    );
  }
}

// ── APP ROW ───────────────────────────────────
class _AppRow extends ConsumerWidget {
  const _AppRow({required this.app});
  final BlockedApp app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appBlockerProvider.notifier);

    return Dismissible(
      key: ValueKey(app.packageName),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: FGColors.redGlow,
          borderRadius: FGRadius.md,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: FGColors.red, size: 22),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: FGColors.bg3,
            shape: RoundedRectangleBorder(borderRadius: FGRadius.lg),
            title: const Text('Remove app?',
              style: TextStyle(fontFamily: 'Syne', fontSize: 16,
                  fontWeight: FontWeight.w700, color: FGColors.textPrimary)),
            content: Text('Stop blocking ${app.displayName}?',
              style: const TextStyle(fontFamily: 'DM Sans',
                  fontSize: 13, color: FGColors.textSecond)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(color: FGColors.textThird))),
              TextButton(onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove',
                    style: TextStyle(color: FGColors.red,
                        fontWeight: FontWeight.w600))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => notifier.removeApp(app.packageName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: FGColors.bg3,
          borderRadius: FGRadius.md,
          border: Border.all(color: FGColors.border),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(children: [
              // App icon circle
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (app.iconColor ?? FGColors.bg4).withOpacity(0.15),
                  borderRadius: FGRadius.md,
                  border: Border.all(
                    color: (app.iconColor ?? FGColors.border).withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(app.iconEmoji,
                    style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.displayName,
                    style: const TextStyle(
                      fontFamily: 'DM Sans', fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: FGColors.textPrimary,
                    )),
                  const SizedBox(height: 4),
                  Row(children: [
                    FGBadge(app.category.label, style: _badgeStyle(app.category)),
                    const SizedBox(width: 6),
                    if (app.isAlwaysBlocked)
                      const Text('Always blocked',
                        style: TextStyle(fontFamily: 'DM Sans', fontSize: 11,
                            color: FGColors.textThird))
                    else
                      GestureDetector(
                        onTap: () => _showBudgetSheet(context, ref),
                        child: Text('${app.dailyBudgetMinutes} min/day',
                          style: const TextStyle(
                            fontFamily: 'DM Sans', fontSize: 11,
                            color: FGColors.teal,
                            decoration: TextDecoration.underline,
                            decorationColor: FGColors.teal,
                          )),
                      ),
                  ]),
                ],
              )),

              // Toggle
              Switch(
                value: app.isActive,
                onChanged: (_) => notifier.toggleApp(app.packageName),
              ),
            ]),
          ),

          // Budget progress (only when time-limited)
          if (!app.isAlwaysBlocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${app.minutesUsedToday} min used today',
                      style: const TextStyle(fontFamily: 'DM Sans',
                          fontSize: 10, color: FGColors.textThird)),
                    Text('${app.minutesRemaining} min left',
                      style: const TextStyle(fontFamily: 'DM Sans',
                          fontSize: 10, color: FGColors.teal)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: FGRadius.full,
                  child: LinearProgressIndicator(
                    value: app.budgetProgress,
                    minHeight: 4,
                    backgroundColor: FGColors.bg4,
                    valueColor: AlwaysStoppedAnimation(
                      app.budgetProgress > 0.8 ? FGColors.red : FGColors.teal),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  void _showBudgetSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetSheet(app: app, ref: ref),
    );
  }

  FGBadgeStyle _badgeStyle(AppCategory cat) => switch (cat) {
        AppCategory.social        => FGBadgeStyle.gray,
        AppCategory.shortsReels   => FGBadgeStyle.red,
        AppCategory.gaming        => FGBadgeStyle.amber,
        AppCategory.entertainment => FGBadgeStyle.purple,
        AppCategory.messaging     => FGBadgeStyle.teal,
        AppCategory.other         => FGBadgeStyle.gray,
      };
}

// ── ADD APP SHEET ────────────────────────────
// User types an app name — we search our lookup table.
// If not found, we show a "not found" message with a note to contact support.

// Comprehensive name → package lookup (case-insensitive)
const _kAppLookup = {
  // Social
  'instagram':       ('com.instagram.android',            'Instagram',        '📸'),
  'facebook':        ('com.facebook.katana',              'Facebook',         '📘'),
  'x':               ('com.twitter.android',              'Twitter / X',      '𝕏'),
  'snapchat':        ('com.snapchat.android',             'Snapchat',         '👻'),
  'reddit':          ('com.reddit.frontpage',             'Reddit',           '🟠'),
  'pinterest':       ('com.pinterest',                    'Pinterest',         '📌'),
  'linkedin':        ('com.linkedin.android',             'LinkedIn',         '💼'),
  'sharechat':       ('com.sharechat.sharechat',          'ShareChat',        '📱'),
  // Short-form video
  'tiktok':          ('com.zhiliaoapp.musically',         'TikTok',           '🎵'),
  'youtube':         ('com.google.android.youtube',       'YouTube',          '▶️'),
  'josh':            ('com.joshapp.android',              'Josh',             '🎬'),
  'moj':             ('com.moj.app',                      'Moj',              '🎭'),
  'mx takatak':      ('com.mxtakatak',                    'MX TakaTak',       '🎵'),
  'youtube shorts':  ('com.google.android.youtube',       'YouTube',          '▶️'),
  'shorts':          ('com.google.android.youtube',       'YouTube',          '▶️'),
  // Messaging
  'whatsapp':        ('com.whatsapp',                     'WhatsApp',         '💬'),
  'telegram':        ('com.telegram.messenger',           'Telegram',         '✈️'),
  'discord':         ('com.discord',                      'Discord',          '💬'),
  'signal':          ('org.thoughtcrime.securesms',       'Signal',           '🔒'),
  'messenger':       ('com.facebook.orca',                'Messenger',        '💬'),
  // Entertainment / streaming
  'netflix':         ('com.netflix.mediaclient',          'Netflix',          '🎬'),
  'hotstar':         ('com.jiohotstar',                      'JioHotstar',          '⭐'),
  'prime video':     ('com.amazon.avod.thirdpartyclient', 'Prime Video',      '🎥'),
  'amazon prime':    ('com.amazon.avod.thirdpartyclient', 'Prime Video',      '🎥'),
  'prime':           ('com.amazon.avod.thirdpartyclient', 'Prime Video',      '🎥'),
  'zee5':            ('com.zee5.android',                 'ZEE5',             '📺'),
  'jiocinema':       ('com.jio.media.jioplay',            'JioCinema',        '🎞️'),
  'spotify':         ('com.spotify.music',                'Spotify',          '🎵'),
  'mx player':       ('com.mxtech.videoplayer.ad',        'MX Player',        '▶️'),
  'mx':              ('com.mxtech.videoplayer.ad',        'MX Player',        '▶️'),
  // Gaming
  'bgmi':            ('com.pubg.imobile',                 'BGMI',             '🎮'),
  'pubg':            ('com.pubg.imobile',                 'BGMI',             '🎮'),
  'free fire':       ('com.dts.freefireth',               'Free Fire',        '🔥'),
  'freefire':        ('com.dts.freefireth',               'Free Fire',        '🔥'),
  'clash of clans':  ('com.supercell.clashofclans',       'Clash of Clans',   '⚔️'),
  'coc':             ('com.supercell.clashofclans',       'Clash of Clans',   '⚔️'),
  'clash royale':    ('com.supercell.clashroyale',        'Clash Royale',     '🃏'),
  'roblox':          ('com.roblox.client',                'Roblox',           '🎮'),
  'minecraft':       ('com.mojang.minecraftpe',           'Minecraft',        '⛏️'),
  'cod':             ('com.activision.callofduty.shooter','COD Mobile',       '🔫'),
  'call of duty':    ('com.activision.callofduty.shooter','COD Mobile',       '🔫'),
  'genshin':         ('com.miHoYo.GenshinImpact',        'Genshin Impact',   '🌟'),
};

class _AddAppSheet extends ConsumerStatefulWidget {
  const _AddAppSheet();
  @override ConsumerState<_AddAppSheet> createState() => _AddAppSheetState();
}

class _AddAppSheetState extends ConsumerState<_AddAppSheet> {
  final _searchCtrl = TextEditingController();
  (String, String, String)? _found;   // (packageName, displayName, emoji)
  bool _notFound  = false;
  bool _adding    = false;

  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _onChanged(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) { setState(() { _found = null; _notFound = false; }); return; }
    final match = _kAppLookup[q];
    setState(() {
      _found    = match;
      _notFound = match == null && q.length >= 3;
    });
  }

  Future<void> _add() async {
    if (_found == null) return;
    final (pkg, name, emoji) = _found!;
    final already = ref.read(appBlockerProvider).blockedApps.any((a) => a.packageName == pkg);
    if (already) { Navigator.pop(context); return; }
    setState(() => _adding = true);
    await ref.read(appBlockerProvider.notifier).addApp(SuggestedApp(
      packageName: pkg, displayName: name, iconEmoji: emoji,
      iconColor: const Color(0xFF7C6FED), category: AppCategory.other,
    ));
    setState(() => _adding = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final bg2  = isDark ? FGColors.bg2  : FGColorsLight.bg2;
    final bg3  = isDark ? FGColors.bg3  : FGColorsLight.bg3;
    final bg4  = isDark ? FGColors.bg4  : FGColorsLight.bg4;
    final b2   = isDark ? FGColors.border2 : FGColorsLight.border2;
    final b    = isDark ? FGColors.border  : FGColorsLight.border;
    final tp   = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts   = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt   = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final p    = isDark ? FGColors.purple      : FGColorsLight.purple;
    final teal = isDark ? FGColors.teal        : FGColorsLight.teal;
    final red  = isDark ? FGColors.red         : FGColorsLight.red;
    final blocked = ref.watch(appBlockerProvider).blockedApps.map((a) => a.packageName).toSet();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Container(
      decoration: BoxDecoration(
        color: bg2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: b2))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottom),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: b2, borderRadius: FGRadius.full))),
        const SizedBox(height: 20),
        Text('Block an app', style: TextStyle(fontFamily: 'Syne',
          fontSize: 18, fontWeight: FontWeight.w700, color: tp)),
        const SizedBox(height: 4),
        Text('Type the app name to find and block it.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: ts)),
        const SizedBox(height: 18),

        // Search field
        TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: _onChanged,
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: tp),
          cursorColor: p,
          decoration: InputDecoration(
            hintText: 'e.g.  Netflix  or  Free Fire  or  Hotstar',
            hintStyle: TextStyle(color: tt, fontSize: 13),
            filled: true, fillColor: bg4,
            prefixIcon: Icon(Icons.search_rounded, color: tt, size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () { _searchCtrl.clear(); setState(() { _found = null; _notFound = false; }); },
                  child: Icon(Icons.clear_rounded, color: tt, size: 18))
              : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: FGRadius.md, borderSide: BorderSide(color: b2)),
            enabledBorder: OutlineInputBorder(borderRadius: FGRadius.md, borderSide: BorderSide(color: b2)),
            focusedBorder: OutlineInputBorder(borderRadius: FGRadius.md, borderSide: BorderSide(color: p, width: 1.5)))),
        const SizedBox(height: 12),

        // Result
        if (_found != null) ...[
          () {
            final (pkg, name, emoji) = _found!;
            final alreadyBlocked = blocked.contains(pkg);
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: alreadyBlocked ? bg3 : teal.withOpacity(0.08),
                borderRadius: FGRadius.md,
                border: Border.all(color: alreadyBlocked ? b : teal.withOpacity(0.3))),
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: TextStyle(fontFamily: 'DM Sans',
                    fontSize: 14, fontWeight: FontWeight.w600, color: tp)),
                  Text(alreadyBlocked ? 'Already blocked' : 'Found — tap to block',
                    style: TextStyle(fontFamily: 'DM Sans', fontSize: 11,
                      color: alreadyBlocked ? tt : teal)),
                ])),
                if (!alreadyBlocked)
                  Icon(Icons.check_circle_outline_rounded, color: teal, size: 20),
              ]));
          }(),
          const SizedBox(height: 12),
          if (!blocked.contains(_found!.$1))
            FGButton(label: 'Block ${_found!.$2}', icon: Icons.block_rounded,
              loading: _adding, onTap: _add),
        ] else if (_notFound) ...[
          _ManualPkgEntry(searchName: _searchCtrl.text.trim()),
        ],

        const SizedBox(height: 16),
        Divider(height: 1, color: b),
        const SizedBox(height: 14),

        // Popular quick picks (not yet blocked)
        Text('Popular', style: TextStyle(fontFamily: 'Syne',
          fontSize: 13, fontWeight: FontWeight.w700, color: tp)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final entry in _kAppLookup.entries.take(16))
            if (!blocked.contains(entry.value.$1))
              GestureDetector(
                onTap: () async {
                  final (pkg, name, emoji) = entry.value;
                  setState(() => _adding = true);
                  await ref.read(appBlockerProvider.notifier).addApp(SuggestedApp(
                    packageName: pkg, displayName: name, iconEmoji: emoji,
                    iconColor: const Color(0xFF7C6FED), category: AppCategory.other));
                  setState(() => _adding = false);
                  if (mounted) Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: bg3, borderRadius: FGRadius.full,
                    border: Border.all(color: b)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(entry.value.$3, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(entry.value.$2, style: TextStyle(fontFamily: 'DM Sans',
                      fontSize: 12, fontWeight: FontWeight.w500, color: ts)),
                  ]))),
        ]),
       ],
      ), 
     ),
     ),
     );
  }
}


// ── MANUAL PACKAGE ENTRY (fallback when app not in lookup) ──────────
class _ManualPkgEntry extends ConsumerStatefulWidget {
  const _ManualPkgEntry({required this.searchName});
  final String searchName;
  @override ConsumerState<_ManualPkgEntry> createState() => _ManualPkgEntryState();
}

class _ManualPkgEntryState extends ConsumerState<_ManualPkgEntry> {
  final _pkgCtrl = TextEditingController();
  bool _show = false, _adding = false;
  String? _error;

  @override void dispose() { _pkgCtrl.dispose(); super.dispose(); }

  Future<void> _add() async {
    final pkg = _pkgCtrl.text.trim().toLowerCase();
    if (pkg.isEmpty) { setState(() => _error = 'Enter the package name.'); return; }
    if (!pkg.contains('.')) { setState(() => _error = 'Must contain a dot. E.g. com.hotstar'); return; }
    setState(() { _adding = true; _error = null; });
    await ref.read(appBlockerProvider.notifier).addApp(SuggestedApp(
      packageName: pkg,
      displayName: widget.searchName.isNotEmpty ? widget.searchName : pkg.split('.').last,
      iconEmoji: '📱',
      iconColor: const Color(0xFF7C6FED),
      category: AppCategory.other,
    ));
    setState(() => _adding = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final bg4 = isDark ? FGColors.bg4 : FGColorsLight.bg4;
    final b   = isDark ? FGColors.border  : FGColorsLight.border;
    final b2  = isDark ? FGColors.border2 : FGColorsLight.border2;
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts  = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt  = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final p   = isDark ? FGColors.purple      : FGColorsLight.purple;
    final red = isDark ? FGColors.red         : FGColorsLight.red;
    final amber = isDark ? FGColors.amber : FGColorsLight.amber;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg3, borderRadius: FGRadius.md,
          border: Border.all(color: b)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.search_off_rounded, color: amber, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('App not found in our list.',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
                fontWeight: FontWeight.w600, color: tp))),
          ]),
          const SizedBox(height: 6),
          Text(
            'You can still block it by entering its package name.'
            'To find it: open Play Store on your phone, find the app, '
            'tap Share → copy the link. The package name is after "id=" in the URL.'
            'Example: for Hotstar the link is ...?id=com.hotstar — so the package name is com.hotstar.',
            style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: ts, height: 1.5)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _show = !_show),
            child: Text(_show ? 'Hide package name field ▲' : 'Enter package name manually ▼',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 12,
                color: p, decoration: TextDecoration.underline, decorationColor: p))),
          if (_show) ...[
            const SizedBox(height: 10),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: red)),
              const SizedBox(height: 6),
            ],
            TextField(
              controller: _pkgCtrl,
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: tp),
              cursorColor: p,
              decoration: InputDecoration(
                hintText: 'e.g.  com.hotstar',
                hintStyle: TextStyle(color: tt, fontSize: 12),
                filled: true, fillColor: bg4,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: FGRadius.sm, borderSide: BorderSide(color: b2)),
                enabledBorder: OutlineInputBorder(borderRadius: FGRadius.sm, borderSide: BorderSide(color: b2)),
                focusedBorder: OutlineInputBorder(borderRadius: FGRadius.sm, borderSide: BorderSide(color: p)))),
            const SizedBox(height: 10),
            FGButton(label: 'Block this app', icon: Icons.block_rounded,
              loading: _adding, onTap: _add),
          ],
        ])),
    ]);
  }
}

class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet({required this.app, required this.ref});
  final BlockedApp app;
  final WidgetRef ref;

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late int _budget;

  @override
  void initState() {
    super.initState();
    _budget = widget.app.dailyBudgetMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FGColors.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: FGColors.border2)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: FGColors.border2, borderRadius: FGRadius.full),
          )),
          const SizedBox(height: 20),
          Text('Edit daily limit — ${widget.app.displayName}',
            style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [0, 15, 30, 60, 90, 120].map((mins) {
              final active = _budget == mins;
              return GestureDetector(
                onTap: () => setState(() => _budget = mins),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? FGColors.purple : FGColors.bg4,
                    borderRadius: FGRadius.full,
                    border: Border.all(
                      color: active ? FGColors.purple : FGColors.border2),
                  ),
                  child: Text(
                    mins == 0 ? 'Always block' : '$mins min/day',
                    style: TextStyle(
                      fontFamily: 'DM Sans', fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : FGColors.textSecond,
                    )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FGButton(
            label: 'Save',
            onTap: () {
              widget.ref.read(appBlockerProvider.notifier)
                  .updateBudget(widget.app.packageName, _budget);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ── HOW IT WORKS CARD ─────────────────────────
class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FGCard(
      child: Column(children: [
        _Step(n: '1', text: 'Stay Off runs an Accessibility Service in the background.'),
        const SizedBox(height: 10),
        _Step(n: '2', text: 'When you open a blocked app, it\'s detected instantly using Usage Stats.'),
        const SizedBox(height: 10),
        _Step(n: '3', text: 'Stay Off overlays a focus reminder — no root needed.'),
        // const SizedBox(height: 10),
        // _Step(n: '4', text: 'Time-limited apps auto-block when your daily budget runs out.'),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});
  final String n, text;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: FGColors.purpleGlow,
          borderRadius: FGRadius.full,
          border: Border.all(color: FGColors.purpleBorder),
        ),
        child: Center(child: Text(n,
          style: const TextStyle(fontFamily: 'Syne', fontSize: 11,
              fontWeight: FontWeight.w700, color: FGColors.purpleLight))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(text,
        style: const TextStyle(fontFamily: 'DM Sans', fontSize: 12,
            color: FGColors.textSecond, height: 1.5))),
    ]);
  }
}

// ── HOW IT WORKS SHEET ────────────────────────
class _HowItWorksSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FGColors.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: FGColors.border2)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: FGColors.border2, borderRadius: FGRadius.full),
          )),
          const SizedBox(height: 20),
          Text('How app blocking works',
            style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _HowItWorksCard(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FGColors.amberGlow,
              borderRadius: FGRadius.md,
              border: Border.all(color: FGColors.amber.withOpacity(0.25)),
            ),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: FGColors.amber, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Blocking effectiveness depends on both Usage Access and Accessibility permissions being granted.',
                style: TextStyle(fontFamily: 'DM Sans', fontSize: 12,
                    color: FGColors.amber, height: 1.5))),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── EMPTY STATE ───────────────────────────────
class _EmptyBlockedState extends StatelessWidget {
  const _EmptyBlockedState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FGColors.bg3,
        borderRadius: FGRadius.lg,
        border: Border.all(color: FGColors.border),
      ),
      child: const Column(children: [
        Text('📱', style: TextStyle(fontSize: 36)),
        SizedBox(height: 12),
        Text('No apps blocked yet',
          style: TextStyle(fontFamily: 'Syne', fontSize: 15,
              fontWeight: FontWeight.w700, color: FGColors.textPrimary)),
        SizedBox(height: 6),
        Text('Tap an app below to start blocking it',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 12,
              color: FGColors.textThird)),
      ]),
    );
  }
}

// ── SKELETON ─────────────────────────────────
class _AppBlockerSkeleton extends StatelessWidget {
  const _AppBlockerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 76,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: FGColors.bg3,
          borderRadius: FGRadius.md,
        ),
      ),
    );
  }
}