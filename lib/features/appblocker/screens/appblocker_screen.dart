import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusguard/core/theme/app_theme.dart';
import 'package:focusguard/shared/widgets/fg_widgets.dart';
import 'package:focusguard/features/appblocker/models/blocked_app.dart';
import 'package:focusguard/features/appblocker/providers/appblocker_provider.dart';
import 'package:focusguard/features/appblocker/providers/installed_apps_provider.dart';

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
                        if (!state.a11yGranted)
                          _PermissionBanners(state: state),

                        if (state.blockedApps.isNotEmpty) ...[
                          const FGSectionLabel('Blocked apps', topPad: 4),
                          ...state.blockedApps.map(
                            (app) => _AppRow(app: app)),
                        ] else
                          const _EmptyBlockedState(),

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
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (app.iconColor ?? FGColors.bg4).withOpacity(0.15),
                  borderRadius: FGRadius.md,
                  border: Border.all(
                    color: (app.iconColor ?? FGColors.border).withOpacity(0.3)),
                ),
                child: Center(
                  child: app.icon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            app.icon!,
                            width: 26,
                            height: 26,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        )
                      : Text(
                          app.iconEmoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                ),
              ),
              const SizedBox(width: 12),

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

              Switch(
                value: app.isActive,
                onChanged: (_) => notifier.toggleApp(app.packageName),
              ),
            ]),
          ),

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

// ── ADD APP SHEET WITH TIME LIMIT SELECTOR ────────────────────────────
class _AddAppSheet extends ConsumerStatefulWidget {
  const _AddAppSheet();

  @override
  ConsumerState<_AddAppSheet> createState() => _AddAppSheetState();
}

class _AddAppSheetState extends ConsumerState<_AddAppSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  
  int _budgetMinutes = 30;
  bool _useTimeLimit = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(installedAppsProvider.notifier).loadApps();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final installedState = ref.watch(installedAppsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = isDark ? FGColors.purple : FGColorsLight.purple;
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final bg4 = isDark ? FGColors.bg4 : FGColorsLight.bg4;
    final b2 = isDark ? FGColors.border2 : FGColorsLight.border2;
    final ts = isDark ? FGColors.textSecond : FGColorsLight.textSecond;
    final tt = isDark ? FGColors.textThird : FGColorsLight.textThird;
    final tp = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;

    return Container(
      decoration: const BoxDecoration(
        color: FGColors.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: FGColors.border2)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 14),
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: FGColors.border2,
                  borderRadius: FGRadius.full,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Block installed apps',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: FGColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select an app below to block it with a daily time limit.',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: FGColors.textThird,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) {
                      ref.read(installedAppsProvider.notifier).search(v);
                    },
                    style: const TextStyle(color: FGColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search installed apps...',
                      hintStyle: const TextStyle(color: FGColors.textThird),
                      prefixIcon: const Icon(Icons.search_rounded, color: FGColors.textThird),
                      filled: true,
                      fillColor: FGColors.bg4,
                      border: OutlineInputBorder(
                        borderRadius: FGRadius.md,
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: FGRadius.md,
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: FGRadius.md,
                        borderSide: const BorderSide(color: FGColors.purple, width: 1.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── TIME LIMIT SELECTOR ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _useTimeLimit ? p.withOpacity(0.08) : bg3,
                  borderRadius: FGRadius.md,
                  border: Border.all(color: _useTimeLimit ? p.withOpacity(0.3) : b2),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.timer_outlined,
                      color: _useTimeLimit ? (isDark ? FGColors.purpleLight : FGColorsLight.purpleLight) : tt,
                      size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Set daily time limit',
                        style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _useTimeLimit ? (isDark ? FGColors.purpleLight : FGColorsLight.purpleLight) : tp)),
                      Text(_useTimeLimit
                          ? 'Block after $_budgetMinutes min/day'
                          : 'Off — always blocked',
                        style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: tt)),
                    ])),
                    Switch(
                      value: _useTimeLimit,
                      onChanged: (v) => setState(() {
                        _useTimeLimit = v;
                        if (v && _budgetMinutes == 0) _budgetMinutes = 30;
                      })),
                  ]),
                  if (_useTimeLimit) ...[
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8,
                      children: [15, 30, 60, 90, 120, 180].map((m) {
                        final active = _budgetMinutes == m;
                        return GestureDetector(
                          onTap: () => setState(() => _budgetMinutes = m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: active ? p : bg4,
                              borderRadius: FGRadius.full,
                              border: Border.all(color: active ? p : b2)),
                            child: Text(m >= 60 ? '${m ~/ 60}h' : '${m}min',
                              style: TextStyle(fontFamily: 'DM Sans', fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active ? Colors.white : ts))));
                      }).toList()),
                  ],
                ]),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: installedState.loading
                  ? const Center(child: CircularProgressIndicator())
                  : installedState.filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No apps found',
                            style: TextStyle(fontFamily: 'DM Sans', color: FGColors.textThird),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          itemCount: installedState.filtered.length,
                          itemBuilder: (_, index) {
                            final app = installedState.filtered[index];
                            final alreadyBlocked = ref.watch(appBlockerProvider).blockedApps.any(
                              (e) => e.packageName == app.packageName,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: FGColors.bg3,
                                borderRadius: FGRadius.md,
                                border: Border.all(color: FGColors.border),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: FGColors.bg4,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: app.icon != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.memory(app.icon!, fit: BoxFit.cover, gaplessPlayback: true),
                                        )
                                      : const Center(child: Text('📱', style: TextStyle(fontSize: 22))),
                                ),
                                title: Text(
                                  app.appName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: FGColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  app.packageName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    color: FGColors.textThird,
                                  ),
                                ),
                                trailing: alreadyBlocked
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: FGColors.redGlow,
                                          borderRadius: FGRadius.full,
                                        ),
                                        child: const Text(
                                          'Blocked',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: FGColors.red,
                                          ),
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: () async {
                                          await ref.read(appBlockerProvider.notifier).addApp(
                                            SuggestedApp(
                                              packageName: app.packageName,
                                              displayName: app.appName,
                                              iconEmoji: '📱',
                                              iconColor: FGColors.purple,
                                              category: AppCategory.other,
                                              icon: app.icon,
                                            ),
                                            budgetMinutes: _useTimeLimit ? _budgetMinutes : 0,
                                          );
                                          if (mounted) Navigator.pop(context);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: FGColors.purpleGlow,
                                            borderRadius: FGRadius.full,
                                          ),
                                          child: const Icon(Icons.add_rounded, color: FGColors.purple, size: 20),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── MANUAL PACKAGE ENTRY ──────────────────────────
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
    await ref.read(appBlockerProvider.notifier).addApp(
      SuggestedApp(
        packageName: pkg,
        displayName: widget.searchName.isNotEmpty ? widget.searchName : pkg.split('.').last,
        iconEmoji: '📱',
        iconColor: const Color(0xFF7C6FED),
        category: AppCategory.other,
      ),
      budgetMinutes: 0,
    );
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

// ── BUDGET SHEET ─────────────────────────────────
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = isDark ? FGColors.purple : FGColorsLight.purple;
    final bg3 = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final bg4 = isDark ? FGColors.bg4 : FGColorsLight.bg4;
    final b2 = isDark ? FGColors.border2 : FGColorsLight.border2;
    final ts = isDark ? FGColors.textSecond : FGColorsLight.textSecond;

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
          
          GestureDetector(
            onTap: () => setState(() => _budget = 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: _budget == 0 ? p.withOpacity(0.08) : bg3,
                borderRadius: FGRadius.md,
                border: Border.all(color: _budget == 0 ? p : b2),
              ),
              child: Row(children: [
                Icon(Icons.block_rounded, color: _budget == 0 ? p : FGColors.textThird, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Always block',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _budget == 0 ? p : FGColors.textPrimary))),
                if (_budget == 0)
                  Icon(Icons.check_circle, color: p, size: 20),
              ]),
            ),
          ),
          
          GestureDetector(
            onTap: () => setState(() { if (_budget == 0) _budget = 30; }),
            child: Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _budget > 0 ? p.withOpacity(0.08) : bg3,
                borderRadius: FGRadius.md,
                border: Border.all(color: _budget > 0 ? p : b2),
              ),
              child: Row(children: [
                Icon(Icons.timer_outlined, color: _budget > 0 ? p : FGColors.textThird, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Time limit',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _budget > 0 ? p : FGColors.textPrimary))),
                if (_budget > 0)
                  Icon(Icons.check_circle, color: p, size: 20),
              ]),
            ),
          ),
          
          if (_budget > 0) ...[
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [15, 30, 60, 90, 120, 180].map((mins) {
                final active = _budget == mins;
                return GestureDetector(
                  onTap: () => setState(() => _budget = mins),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? p : bg4,
                      borderRadius: FGRadius.full,
                      border: Border.all(color: active ? p : b2),
                    ),
                    child: Text(
                      mins >= 60 ? '${mins ~/ 60}h' : '$mins min',
                      style: TextStyle(
                        fontFamily: 'DM Sans', fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : ts,
                      )),
                  ),
                );
              }).toList(),
            ),
          ],
          
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