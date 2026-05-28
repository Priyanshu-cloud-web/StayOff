// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:focusguard/core/theme/app_theme.dart';
// import 'package:focusguard/shared/widgets/fg_widgets.dart';
// import 'package:focusguard/features/blocklist/models/blocked_site.dart';
// import 'package:focusguard/features/blocklist/providers/blocklist_provider.dart';

// class BlocklistScreen extends ConsumerStatefulWidget {
//   const BlocklistScreen({super.key});
//   @override ConsumerState<BlocklistScreen> createState() => _BlocklistScreenState();
// }

// class _BlocklistScreenState extends ConsumerState<BlocklistScreen>
//     with WidgetsBindingObserver {
//   Timer? _usageTimer;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _startSync();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) _startSync();
//     if (state == AppLifecycleState.paused)  _stopSync();
//   }

//   void _startSync() {
//     _usageTimer?.cancel();
//     ref.read(blocklistProvider.notifier).syncUsage();
//     _usageTimer = Timer.periodic(const Duration(seconds: 10), (_) {
//       ref.read(blocklistProvider.notifier).syncUsage();
//     });
//   }

//   void _stopSync() {
//     _usageTimer?.cancel();
//     _usageTimer = null;
//   }

//   @override
//   void dispose() {
//     _stopSync();
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state  = ref.watch(blocklistProvider);
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final bg     = isDark ? FGColors.bg : FGColorsLight.bg;

//     return Scaffold(
//       backgroundColor: bg,
//       body: SafeArea(
//         child: Column(children: [
//           _TopBar(state: state, isDark: isDark),
//           if (state.sites.isNotEmpty) _FilterRow(state: state, isDark: isDark),
//           Expanded(
//             child: state.isLoading
//                 ? _Skeleton(isDark: isDark)
//                 : state.sites.isEmpty
//                     ? _EmptyState(
//                         isDark: isDark,
//                         onAdd: () => _showAddSheet(context))
//                     : state.filtered.isEmpty
//                         ? _NoResults(isDark: isDark)
//                         : _SiteList(
//                             sites: state.filtered, isDark: isDark),
//           ),
//         ]),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => _showAddSheet(context),
//         backgroundColor:
//             isDark ? FGColors.purple : FGColorsLight.purple,
//         elevation: 0,
//         icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
//         label: const Text('Add site / app',
//             style: TextStyle(
//                 fontFamily: 'Syne',
//                 fontWeight: FontWeight.w700,
//                 color: Colors.white,
//                 fontSize: 13)),
//       ),
//     );
//   }

//   void _showAddSheet(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => ProviderScope(
//         parent: ProviderScope.containerOf(context),
//         child: const _AddSheet(),
//       ),
//     );
//   }
// }

// // ── TOP BAR ───────────────────────────────────
// class _TopBar extends ConsumerWidget {
//   const _TopBar({required this.state, required this.isDark});
//   final BlocklistState state;
//   final bool isDark;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final tp = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
//     final ts = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
//       child: Row(children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Blocklist',
//                   style: TextStyle(
//                       fontFamily: 'Syne',
//                       fontSize: 20,
//                       fontWeight: FontWeight.w700,
//                       color: tp)),
//               Text(
//                 state.sites.isEmpty
//                     ? 'No sites added yet'
//                     : '${state.totalActive} active · ${state.sites.length} total',
//                 style: TextStyle(
//                     fontFamily: 'DM Sans', fontSize: 12, color: ts)),
//             ],
//           ),
//         ),
//         FGIconBtn(
//           icon: Icons.add_rounded,
//           color: isDark ? FGColors.purpleLight : FGColorsLight.purpleLight,
//           onTap: () => showModalBottomSheet(
//             context: context,
//             isScrollControlled: true,
//             backgroundColor: Colors.transparent,
//             builder: (_) => ProviderScope(
//               parent: ProviderScope.containerOf(context),
//               child: const _AddSheet(),
//             ),
//           ),
//         ),
//       ]),
//     );
//   }
// }

// // ── FILTER CHIPS ──────────────────────────────
// class _FilterRow extends ConsumerWidget {
//   const _FilterRow({required this.state, required this.isDark});
//   final BlocklistState state;
//   final bool isDark;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final notifier = ref.read(blocklistProvider.notifier);
//     final selected = state.selectedCategory;

//     // Only show categories that have at least one site
//     final usedCats = SiteCategory.values
//         .where((cat) => state.sites.any((s) => s.category == cat))
//         .toList();

//     if (usedCats.isEmpty) return const SizedBox.shrink();

//     return SizedBox(
//       height: 44,
//       child: ListView(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
//         children: [
//           _Chip(
//             label: 'All',
//             count: state.sites.length,
//             active: selected == null,
//             isDark: isDark,
//             onTap: () => notifier.setCategory(null),
//           ),
//           ...usedCats.map((cat) {
//             final count =
//                 state.sites.where((s) => s.category == cat).length;
//             return _Chip(
//               label: cat.label,
//               count: count,
//               active: selected == cat,
//               isDark: isDark,
//               onTap: () => notifier.setCategory(cat),
//             );
//           }),
//         ],
//       ),
//     );
//   }
// }

// class _Chip extends StatelessWidget {
//   const _Chip({
//     required this.label,
//     required this.count,
//     required this.active,
//     required this.isDark,
//     required this.onTap,
//   });
//   final String label;
//   final int count;
//   final bool active, isDark;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final p   = isDark ? FGColors.purple     : FGColorsLight.purple;
//     final b2  = isDark ? FGColors.border2    : FGColorsLight.border2;
//     final bg3 = isDark ? FGColors.bg3        : FGColorsLight.bg3;
//     final ts  = isDark ? FGColors.textSecond : FGColorsLight.textSecond;

//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         margin: const EdgeInsets.only(right: 8),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//         decoration: BoxDecoration(
//           color: active ? p : bg3,
//           borderRadius: FGRadius.full,
//           border: Border.all(color: active ? p : b2),
//         ),
//         child: Text(
//           '$label  $count',
//           style: TextStyle(
//             fontFamily: 'DM Sans',
//             fontSize: 12,
//             fontWeight: FontWeight.w600,
//             color: active ? Colors.white : ts,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ── SITE LIST ─────────────────────────────────
// class _SiteList extends ConsumerWidget {
//   const _SiteList({required this.sites, required this.isDark});
//   final List<BlockedSite> sites;
//   final bool isDark;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return ListView.builder(
//       padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
//       physics: const BouncingScrollPhysics(),
//       itemCount: sites.length,
//       itemBuilder: (_, i) => _SiteRow(site: sites[i], isDark: isDark),
//     );
//   }
// }

// // ── SITE ROW ──────────────────────────────────
// class _SiteRow extends ConsumerWidget {
//   const _SiteRow({required this.site, required this.isDark});
//   final BlockedSite site;
//   final bool isDark;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final notifier = ref.read(blocklistProvider.notifier);
//     final bg3 = isDark ? FGColors.bg3         : FGColorsLight.bg3;
//     final b   = isDark ? FGColors.border       : FGColorsLight.border;
//     final tp  = isDark ? FGColors.textPrimary  : FGColorsLight.textPrimary;
//     final tt  = isDark ? FGColors.textThird    : FGColorsLight.textThird;
//     final teal = isDark ? FGColors.teal        : FGColorsLight.teal;
//     final red  = isDark ? FGColors.red         : FGColorsLight.red;

//     return Dismissible(
//       key: ValueKey(site.id),
//       direction: DismissDirection.endToStart,
//       background: Container(
//         margin: const EdgeInsets.only(bottom: 10),
//         decoration: BoxDecoration(
//           color: red.withOpacity(0.12),
//           borderRadius: FGRadius.md,
//         ),
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.only(right: 20),
//         child: Icon(Icons.delete_outline_rounded, color: red, size: 22),
//       ),
//       confirmDismiss: (_) async {
//         // Ask confirmation first
//         final confirmed = await showDialog<bool>(
//               context: context,
//               builder: (_) => AlertDialog(
//                 backgroundColor: isDark ? FGColors.bg3 : FGColorsLight.bg3,
//                 shape: RoundedRectangleBorder(borderRadius: FGRadius.lg),
//                 title: Text('Remove?', style: TextStyle(
//                     fontFamily: 'Syne', fontSize: 16,
//                     fontWeight: FontWeight.w700, color: tp)),
//                 content: Text('Remove "${site.url}" from blocklist?',
//                     style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
//                         color: isDark ? FGColors.textSecond : FGColorsLight.textSecond)),
//                 actions: [
//                   TextButton(onPressed: () => Navigator.pop(context, false),
//                       child: Text('Cancel', style: TextStyle(
//                           color: isDark ? FGColors.textThird : FGColorsLight.textThird))),
//                   TextButton(onPressed: () => Navigator.pop(context, true),
//                       child: Text('Remove', style: TextStyle(
//                           color: red, fontWeight: FontWeight.w600))),
//                 ],
//               )) ?? false;
//         if (!confirmed) return false;
//         // Actually delete — if locked, show message and return false (keep item)
//         final ok = await notifier.deleteSite(site.id);
//         if (!ok && context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//             content: Text('Commitment lock is active — cannot remove until it expires.'),
//             backgroundColor: Color(0xFFB91C1C),
//             behavior: SnackBarBehavior.floating,
//           ));
//         }
//         return ok;  // false = Dismissible keeps the item visible, no black screen
//       },
//       onDismissed: (_) {
//         // Deletion already done in confirmDismiss — nothing to do here
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 10),
//         decoration: BoxDecoration(
//           color: bg3,
//           borderRadius: FGRadius.md,
//           border: Border.all(color: b),
//         ),
//         child: Column(children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 // Icon
//                 Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: _catColor(site.category, isDark)
//                         .withOpacity(0.12),
//                     borderRadius: FGRadius.sm,
//                     border: Border.all(
//                         color: _catColor(site.category, isDark)
//                             .withOpacity(0.3)),
//                   ),
//                   child: Center(
//                       child: Text(site.faviconEmoji,
//                           style: const TextStyle(fontSize: 18))),
//                 ),
//                 const SizedBox(width: 10),

//                 // Info
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(site.url,
//                           style: TextStyle(
//                               fontFamily: 'DM Sans',
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600,
//                               color: tp),
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 1),
//                       const SizedBox(height: 4),
//                       Row(children: [
//                         Flexible(
//                           child: Text(
//                             site.isAlwaysBlocked
//                                 ? 'Always blocked'
//                                 : '${site.dailyBudgetMinutes} min/day',
//                             style: TextStyle(
//                                 fontFamily: 'DM Sans',
//                                 fontSize: 11,
//                                 color: tt),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ]),
//                     ],
//                   ),
//                 ),

//                 // Toggle
//                 Transform.scale(
//                   scale: 0.85,
//                   child: Switch(
//                     value: site.isActive,
//                     onChanged: (_) async {
//                       final ok = await notifier.toggleSite(site.id);
//                       if (!ok && context.mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                           content: const Text('Commitment lock is active — cannot disable blocks until it expires.'),
//                           backgroundColor: Colors.red.shade700,
//                           behavior: SnackBarBehavior.floating,
//                         ));
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Budget progress bar
//           if (!site.isAlwaysBlocked)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//               child: Column(children: [
//                 Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         site.minutesRemaining > 0
//                           ? '${site.minutesRemaining}m left today'
//                           : 'Limit reached',
//                           style: TextStyle(
//                               fontFamily: 'DM Sans',
//                               fontSize: 10,
//                               color: tt)),
//                       Text('${site.minutesRemaining}m left',
//                           style: TextStyle(
//                               fontFamily: 'DM Sans',
//                               fontSize: 10,
//                               color: teal)),
//                     ]),
//                 const SizedBox(height: 4),
//                 ClipRRect(
//                   borderRadius: FGRadius.full,
//                   child: LinearProgressIndicator(
//                     value: site.budgetProgress,
//                     minHeight: 3,
//                     backgroundColor: isDark
//                         ? FGColors.bg4
//                         : FGColorsLight.bg4,
//                     valueColor: AlwaysStoppedAnimation(
//                         site.budgetProgress > 0.8 ? red : teal),
//                   ),
//                 ),
//               ]),
//             ),
//         ]),
//       ),
//     );
//   }

//   Color _catColor(SiteCategory cat, bool isDark) {
//     switch (cat) {
//       case SiteCategory.shortsReels:
//         return isDark ? FGColors.red : FGColorsLight.red;
//       case SiteCategory.gaming:
//         return isDark ? FGColors.amber : FGColorsLight.amber;
//       case SiteCategory.entertainment:
//         return isDark ? FGColors.purple : FGColorsLight.purple;
//       default:
//         return isDark ? FGColors.textSecond : FGColorsLight.textSecond;
//     }
//   }
// }

// class _CatPill extends StatelessWidget {
//   const _CatPill(this.cat);
//   final SiteCategory cat;

//   @override
//   Widget build(BuildContext context) {
//     final style = switch (cat) {
//       SiteCategory.shortsReels   => FGBadgeStyle.red,
//       SiteCategory.gaming        => FGBadgeStyle.amber,
//       SiteCategory.entertainment => FGBadgeStyle.purple,
//       _                          => FGBadgeStyle.gray,
//     };
//     return FGBadge(cat.label, style: style);
//   }
// }

// // ── ADD SHEET ─────────────────────────────────
// class _AddSheet extends ConsumerStatefulWidget {
//   const _AddSheet();
//   @override
//   ConsumerState<_AddSheet> createState() => _AddSheetState();
// }

// class _AddSheetState extends ConsumerState<_AddSheet> {
//   final _urlCtrl = TextEditingController();
//   int  _budgetMinutes  = 0;    // 0 = always block
//   bool _useTimeLimit   = false;
//   bool _adding         = false;
//   String? _error;

//   @override
//   void dispose() {
//     _urlCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _submit() async {
//     final url = _urlCtrl.text.trim();
//     if (url.isEmpty) {
//       setState(() => _error = 'Please enter a URL.');
//       return;
//     }
//     // Normalize URL
//     var trimmed = url.toLowerCase()
//         .replaceAll(RegExp(r'^https?://'), '')
//         .replaceAll(RegExp(r'^www\.'), '');

//     // If user typed "canva" with no dot and no slash → auto-append .com
//     // Only do this for simple words (no dots, no slashes already)
//     if (!trimmed.contains('.') && !trimmed.contains('/') && trimmed.isNotEmpty) {
//       trimmed = '$trimmed.com';
//     }

//     // If site already exists — UPDATE its time limit instead of rejecting
//     final sites = ref.read(blocklistProvider).sites;
//     final existingIdx = sites.indexWhere((s) => s.url == trimmed);
//     if (existingIdx != -1) {
//       setState(() { _adding = true; _error = null; });
//       await ref.read(blocklistProvider.notifier).updateBudget(
//         sites[existingIdx].id, _useTimeLimit ? _budgetMinutes : 0);
//       if (mounted) Navigator.pop(context);
//       return;
//     }

//     setState(() { _adding = true; _error = null; });
//     await ref.read(blocklistProvider.notifier).addSite(
//       url: url,
//       dailyBudgetMinutes: _useTimeLimit ? _budgetMinutes : 0,
//     );
//     if (mounted) Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark  = Theme.of(context).brightness == Brightness.dark;
//     final bottom  = MediaQuery.of(context).viewInsets.bottom;
//     final bg2  = isDark ? FGColors.bg2 : FGColorsLight.bg2;
//     final bg3  = isDark ? FGColors.bg3 : FGColorsLight.bg3;
//     final bg4  = isDark ? FGColors.bg4 : FGColorsLight.bg4;
//     final b2   = isDark ? FGColors.border2     : FGColorsLight.border2;
//     final tp   = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
//     final ts   = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
//     final tt   = isDark ? FGColors.textThird   : FGColorsLight.textThird;
//     final p    = isDark ? FGColors.purple      : FGColorsLight.purple;

//     return Container(
//       decoration: BoxDecoration(
//         color: bg2,
//         borderRadius:
//             const BorderRadius.vertical(top: Radius.circular(24)),
//         border: Border(top: BorderSide(color: b2)),
//       ),
//       padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottom),
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Handle
//             Center(
//               child: Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                     color: b2, borderRadius: FGRadius.full),
//               ),
//             ),
//             const SizedBox(height: 20),

//             Text('Block a site or app',
//                 style: TextStyle(
//                     fontFamily: 'Syne',
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                     color: tp)),
//             const SizedBox(height: 4),
//             Text(
//                 'Enter a domain (e.g. instagram.com) or path (e.g. youtube/shorts).\'',
//                 style: TextStyle(
//                     fontFamily: 'DM Sans', fontSize: 12, color: ts)),
//             const SizedBox(height: 18),

//             // Already-exists info (not an error — shows update mode)
//             Builder(builder: (_) {
//               final url = _urlCtrl.text.trim().toLowerCase()
//                   .replaceAll(RegExp(r'^https?://'), '')
//                   .replaceAll(RegExp(r'^www\.'), '');
//               final exists = url.isNotEmpty &&
//                   ref.watch(blocklistProvider).sites.any((s) => s.url == url);
//               if (!exists) return const SizedBox.shrink();
//               final teal = isDark ? FGColors.teal : FGColorsLight.teal;
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: teal.withOpacity(0.08), borderRadius: FGRadius.sm,
//                     border: Border.all(color: teal.withOpacity(0.3))),
//                   child: Row(children: [
//                     Icon(Icons.info_outline_rounded, color: teal, size: 16),
//                     const SizedBox(width: 8),
//                     Expanded(child: Text('This entry exists. Toggle the time limit below to update it.',
//                       style: TextStyle(fontFamily: 'DM Sans', fontSize: 12,
//                         color: teal, height: 1.3))),
//                   ])));
//             }),
//             // Error
//             if (_error != null) ...[
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: (isDark ? FGColors.red : FGColorsLight.red)
//                       .withOpacity(0.1),
//                   borderRadius: FGRadius.sm,
//                   border: Border.all(
//                       color: (isDark ? FGColors.red : FGColorsLight.red)
//                           .withOpacity(0.35)),
//                 ),
//                 child: Text(_error!,
//                     style: TextStyle(
//                         fontFamily: 'DM Sans',
//                         fontSize: 12,
//                         color: isDark ? FGColors.red : FGColorsLight.red)),
//               ),
//               const SizedBox(height: 12),
//             ],

//             // ── URL INPUT ──
//             _L('What to block', tt),
//             TextField(
//               controller: _urlCtrl,
//               autofocus: true,
//               keyboardType: TextInputType.url,
//               style: TextStyle(
//                   fontFamily: 'DM Sans', fontSize: 14, color: tp),
//               cursorColor: p,
//               decoration: InputDecoration(
//                 hintText: 'e.g.  youtube/shorts  or  instagram.com',
//                 hintStyle:
//                     TextStyle(color: tt, fontSize: 13),
//                 filled: true,
//                 fillColor: bg4,
//                 prefixIcon:
//                     Icon(Icons.link_rounded, color: tt, size: 18),
//                 contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 14, vertical: 14),
//                 border: OutlineInputBorder(
//                     borderRadius: FGRadius.md,
//                     borderSide: BorderSide(color: b2)),
//                 enabledBorder: OutlineInputBorder(
//                     borderRadius: FGRadius.md,
//                     borderSide: BorderSide(color: b2)),
//                 focusedBorder: OutlineInputBorder(
//                     borderRadius: FGRadius.md,
//                     borderSide: BorderSide(color: p, width: 1.5)),
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text('No https:// or www. needed',
//                 style: TextStyle(
//                     fontFamily: 'DM Sans', fontSize: 11, color: tt)),
//             const SizedBox(height: 16),

//             // ── QUICK SUGGESTIONS ──
//             _L('Quick add suggestions', tt),
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: kQuickAddSuggestions
//                   .map((url) => GestureDetector(
//                         onTap: () =>
//                             setState(() => _urlCtrl.text = url),
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 12, vertical: 6),
//                           decoration: BoxDecoration(
//                             color: bg4,
//                             borderRadius: FGRadius.full,
//                             border: Border.all(color: b2),
//                           ),
//                           child: Text(url,
//                               style: TextStyle(
//                                   fontFamily: 'DM Sans',
//                                   fontSize: 11,
//                                   color: ts)),
//                         ),
//                       ))
//                   .toList(),
//             ),
//             const SizedBox(height: 16),



//             const SizedBox(height: 16),

//             // ── TIME LIMIT (chip-only, NO Slider to avoid crash) ──────
//             Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: _useTimeLimit ? p.withOpacity(0.08) : bg3,
//                 borderRadius: FGRadius.md,
//                 border: Border.all(color: _useTimeLimit ? p.withOpacity(0.3) : b2)),
//               child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 Row(children: [
//                   Icon(Icons.timer_outlined,
//                     color: _useTimeLimit
//                       ? (isDark ? FGColors.purpleLight : FGColorsLight.purpleLight) : tt,
//                     size: 20),
//                   const SizedBox(width: 12),
//                   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                     Text('Set daily time limit',
//                       style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: _useTimeLimit
//                           ? (isDark ? FGColors.purpleLight : FGColorsLight.purpleLight) : tp)),
//                     Text(_useTimeLimit
//                         ? 'Block after ${_budgetMinutes} min/day'
//                         : 'Off — always blocked',
//                       style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: tt)),
//                   ])),
//                   Switch(
//                     value: _useTimeLimit,
//                     onChanged: (v) => setState(() {
//                       _useTimeLimit = v;
//                       if (v && _budgetMinutes == 0) _budgetMinutes = 30;
//                     })),
//                 ]),
//                 if (_useTimeLimit) ...[
//                   const SizedBox(height: 12),
//                   Wrap(spacing: 8, runSpacing: 8,
//                     children: [15, 30, 60, 90, 120, 180].map((m) {
//                       final active = _budgetMinutes == m;
//                       return GestureDetector(
//                         onTap: () => setState(() => _budgetMinutes = m),
//                         child: AnimatedContainer(
//                           duration: const Duration(milliseconds: 150),
//                           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
//                           decoration: BoxDecoration(
//                             color: active ? p : bg4,
//                             borderRadius: FGRadius.full,
//                             border: Border.all(color: active ? p : b2)),
//                           child: Text(m >= 60 ? '${m ~/ 60}h' : '${m}min',
//                             style: TextStyle(fontFamily: 'DM Sans', fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: active ? Colors.white : ts))));
//                     }).toList()),
//                 ],
//               ])),
//             const SizedBox(height: 20),

//             // Submit
//             FGButton(
//               label: _useTimeLimit
//                   ? 'Block (${_budgetMinutes}min/day limit)'
//                   : 'Block always',
//               icon: Icons.block_rounded,
//               loading: _adding,
//               onTap: _submit,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _L(String t, Color c) => Padding(
//         padding: const EdgeInsets.only(bottom: 8),
//         child: Text(t.toUpperCase(),
//             style: TextStyle(
//                 fontFamily: 'Syne',
//                 fontSize: 10,
//                 fontWeight: FontWeight.w700,
//                 color: c,
//                 letterSpacing: 0.1)));
// }

// // ── EMPTY STATE ───────────────────────────────
// class _EmptyState extends StatelessWidget {
//   const _EmptyState({required this.isDark, required this.onAdd});
//   final bool isDark;
//   final VoidCallback onAdd;

//   @override
//   Widget build(BuildContext context) {
//     final p  = isDark ? FGColors.purple      : FGColorsLight.purple;
//     final tp = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
//     final ts = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
//     final tt = isDark ? FGColors.textThird   : FGColorsLight.textThird;

//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 90,
//               height: 90,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: p.withOpacity(0.1),
//                 border: Border.all(color: p.withOpacity(0.25)),
//               ),
//               child: const Center(
//                   child: Text('🛡️',
//                       style: TextStyle(fontSize: 40))),
//             ),
//             const SizedBox(height: 20),
//             Text('Nothing blocked yet',
//                 style: TextStyle(
//                     fontFamily: 'Syne',
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                     color: tp)),
//             const SizedBox(height: 8),
//             Text(
//               'Add sites you want to block.\nYouTube Shorts, Instagram Reels, TikTok — your call.',
//               style: TextStyle(
//                   fontFamily: 'DM Sans', fontSize: 13, color: ts),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 6),
//             Text(
//               'Type a site name or URL — canva.com, youtube.com, etc.',
//               style: TextStyle(
//                   fontFamily: 'DM Sans', fontSize: 12, color: tt),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             FGButton(
//               label: 'Add first block',
//               icon: Icons.add_rounded,
//               small: true,
//               onTap: onAdd,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _NoResults extends StatelessWidget {
//   const _NoResults({required this.isDark});
//   final bool isDark;

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text('No sites in this category',
//           style: TextStyle(
//               fontFamily: 'DM Sans',
//               fontSize: 14,
//               color: isDark ? FGColors.textThird : FGColorsLight.textThird)),
//     );
//   }
// }

// // ── SKELETON ──────────────────────────────────
// class _Skeleton extends StatelessWidget {
//   const _Skeleton({required this.isDark});
//   final bool isDark;

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
//       itemCount: 4,
//       itemBuilder: (_, __) => Container(
//         height: 72,
//         margin: const EdgeInsets.only(bottom: 10),
//         decoration: BoxDecoration(
//           color: isDark ? FGColors.bg3 : FGColorsLight.bg3,
//           borderRadius: FGRadius.md,
//         ),
//       ),
//     );
//   }
// }




import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusguard/core/theme/app_theme.dart';
import 'package:focusguard/shared/widgets/fg_widgets.dart';
import 'package:focusguard/features/blocklist/models/blocked_site.dart';
import 'package:focusguard/features/blocklist/providers/blocklist_provider.dart';

class BlocklistScreen extends ConsumerStatefulWidget {
  const BlocklistScreen({super.key});
  @override ConsumerState<BlocklistScreen> createState() => _BlocklistScreenState();
}

class _BlocklistScreenState extends ConsumerState<BlocklistScreen>
    with WidgetsBindingObserver {
  Timer? _usageTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _startSync();
    if (state == AppLifecycleState.paused)  _stopSync();
  }

  void _startSync() {
    _usageTimer?.cancel();
    ref.read(blocklistProvider.notifier).syncUsage();
    _usageTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(blocklistProvider.notifier).syncUsage();
    });
  }

  void _stopSync() {
    _usageTimer?.cancel();
    _usageTimer = null;
  }

  @override
  void dispose() {
    _stopSync();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(blocklistProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? FGColors.bg : FGColorsLight.bg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          _TopBar(state: state, isDark: isDark),
          if (state.sites.isNotEmpty) _FilterRow(state: state, isDark: isDark),
          Expanded(
            child: state.isLoading
                ? _Skeleton(isDark: isDark)
                : state.sites.isEmpty
                    ? _EmptyState(
                        isDark: isDark,
                        onAdd: () => _showAddSheet(context))
                    : state.filtered.isEmpty
                        ? _NoResults(isDark: isDark)
                        : _SiteList(
                            sites: state.filtered, isDark: isDark),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor:
            isDark ? FGColors.purple : FGColorsLight.purple,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text('Add site / app',
            style: TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 13)),
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
        child: const _AddSheet(),
      ),
    );
  }
}

// ── TOP BAR ───────────────────────────────────
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.state, required this.isDark});
  final BlocklistState state;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tp = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Blocklist',
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: tp)),
              Text(
                state.sites.isEmpty
                    ? 'No sites added yet'
                    : '${state.totalActive} active · ${state.sites.length} total',
                style: TextStyle(
                    fontFamily: 'DM Sans', fontSize: 12, color: ts)),
            ],
          ),
        ),
        FGIconBtn(
          icon: Icons.add_rounded,
          color: isDark ? FGColors.purpleLight : FGColorsLight.purpleLight,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ProviderScope(
              parent: ProviderScope.containerOf(context),
              child: const _AddSheet(),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── FILTER CHIPS ──────────────────────────────
class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.state, required this.isDark});
  final BlocklistState state;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(blocklistProvider.notifier);
    final selected = state.selectedCategory;

    // Only show categories that have at least one site
    final usedCats = SiteCategory.values
        .where((cat) => state.sites.any((s) => s.category == cat))
        .toList();

    if (usedCats.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        children: [
          _Chip(
            label: 'All',
            count: state.sites.length,
            active: selected == null,
            isDark: isDark,
            onTap: () => notifier.setCategory(null),
          ),
          ...usedCats.map((cat) {
            final count =
                state.sites.where((s) => s.category == cat).length;
            return _Chip(
              label: cat.label,
              count: count,
              active: selected == cat,
              isDark: isDark,
              onTap: () => notifier.setCategory(cat),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.active,
    required this.isDark,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool active, isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p   = isDark ? FGColors.purple     : FGColorsLight.purple;
    final b2  = isDark ? FGColors.border2    : FGColorsLight.border2;
    final bg3 = isDark ? FGColors.bg3        : FGColorsLight.bg3;
    final ts  = isDark ? FGColors.textSecond : FGColorsLight.textSecond;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? p : bg3,
          borderRadius: FGRadius.full,
          border: Border.all(color: active ? p : b2),
        ),
        child: Text(
          '$label  $count',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : ts,
          ),
        ),
      ),
    );
  }
}

// ── SITE LIST ─────────────────────────────────
class _SiteList extends ConsumerWidget {
  const _SiteList({required this.sites, required this.isDark});
  final List<BlockedSite> sites;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: sites.length,
      itemBuilder: (_, i) => _SiteRow(site: sites[i], isDark: isDark),
    );
  }
}

// ── SITE ROW ──────────────────────────────────
class _SiteRow extends ConsumerWidget {
  const _SiteRow({required this.site, required this.isDark});
  final BlockedSite site;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(blocklistProvider.notifier);
    final bg3 = isDark ? FGColors.bg3         : FGColorsLight.bg3;
    final b   = isDark ? FGColors.border       : FGColorsLight.border;
    final tp  = isDark ? FGColors.textPrimary  : FGColorsLight.textPrimary;
    final tt  = isDark ? FGColors.textThird    : FGColorsLight.textThird;
    final teal = isDark ? FGColors.teal        : FGColorsLight.teal;
    final red  = isDark ? FGColors.red         : FGColorsLight.red;

    return Dismissible(
      key: ValueKey(site.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: red.withOpacity(0.12),
          borderRadius: FGRadius.md,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline_rounded, color: red, size: 22),
      ),
      confirmDismiss: (_) async {
        // Ask confirmation first
        final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: isDark ? FGColors.bg3 : FGColorsLight.bg3,
                shape: RoundedRectangleBorder(borderRadius: FGRadius.lg),
                title: Text('Remove?', style: TextStyle(
                    fontFamily: 'Syne', fontSize: 16,
                    fontWeight: FontWeight.w700, color: tp)),
                content: Text('Remove "${site.url}" from blocklist?',
                    style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
                        color: isDark ? FGColors.textSecond : FGColorsLight.textSecond)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel', style: TextStyle(
                          color: isDark ? FGColors.textThird : FGColorsLight.textThird))),
                  TextButton(onPressed: () => Navigator.pop(context, true),
                      child: Text('Remove', style: TextStyle(
                          color: red, fontWeight: FontWeight.w600))),
                ],
              )) ?? false;
        if (!confirmed) return false;
        // Actually delete — if locked, show message and return false (keep item)
        final ok = await notifier.deleteSite(site.id);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Commitment lock is active — cannot remove until it expires.'),
            backgroundColor: Color(0xFFB91C1C),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return ok;  // false = Dismissible keeps the item visible, no black screen
      },
      onDismissed: (_) {
        // Deletion already done in confirmDismiss — nothing to do here
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bg3,
          borderRadius: FGRadius.md,
          border: Border.all(color: b),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _catColor(site.category, isDark)
                        .withOpacity(0.12),
                    borderRadius: FGRadius.sm,
                    border: Border.all(
                        color: _catColor(site.category, isDark)
                            .withOpacity(0.3)),
                  ),
                  child: Center(
                      child: Text(site.faviconEmoji,
                          style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(site.url,
                          style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: tp),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                      const SizedBox(height: 4),
                      Row(children: [
                        Flexible(
                          child: Text(
                            site.isAlwaysBlocked
                                ? 'Always blocked'
                                : '${site.dailyBudgetMinutes} min/day',
                            style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                color: tt),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),

                // Toggle
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: site.isActive,
                    onChanged: (_) async {
                      final ok = await notifier.toggleSite(site.id);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Commitment lock is active — cannot disable blocks until it expires.'),
                          backgroundColor: Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Budget progress bar
          if (!site.isAlwaysBlocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        site.minutesRemaining > 0
                          ? '${site.minutesRemaining}m left today'
                          : 'Limit reached',
                          style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 10,
                              color: tt)),
                      Text('${site.minutesRemaining}m left',
                          style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 10,
                              color: teal)),
                    ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: FGRadius.full,
                  child: LinearProgressIndicator(
                    value: site.budgetProgress,
                    minHeight: 3,
                    backgroundColor: isDark
                        ? FGColors.bg4
                        : FGColorsLight.bg4,
                    valueColor: AlwaysStoppedAnimation(
                        site.budgetProgress > 0.8 ? red : teal),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  Color _catColor(SiteCategory cat, bool isDark) {
    switch (cat) {
      case SiteCategory.shortsReels:
        return isDark ? FGColors.red : FGColorsLight.red;
      case SiteCategory.gaming:
        return isDark ? FGColors.amber : FGColorsLight.amber;
      case SiteCategory.entertainment:
        return isDark ? FGColors.purple : FGColorsLight.purple;
      default:
        return isDark ? FGColors.textSecond : FGColorsLight.textSecond;
    }
  }
}

class _CatPill extends StatelessWidget {
  const _CatPill(this.cat);
  final SiteCategory cat;

  @override
  Widget build(BuildContext context) {
    final style = switch (cat) {
      SiteCategory.shortsReels   => FGBadgeStyle.red,
      SiteCategory.gaming        => FGBadgeStyle.amber,
      SiteCategory.entertainment => FGBadgeStyle.purple,
      _                          => FGBadgeStyle.gray,
    };
    return FGBadge(cat.label, style: style);
  }
}

// ── ADD SHEET ─────────────────────────────────
class _AddSheet extends ConsumerStatefulWidget {
  const _AddSheet();
  @override
  ConsumerState<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends ConsumerState<_AddSheet> {
  final _urlCtrl = TextEditingController();
  int  _budgetMinutes  = 0;    // 0 = always block
  bool _useTimeLimit   = false;
  bool _adding         = false;
  String? _error;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Please enter a URL.');
      return;
    }
    // Normalize URL
    var trimmed = url.toLowerCase()
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'^www\.'), '');

    // If user typed "canva" with no dot and no slash → auto-append .com
    // Only do this for simple words (no dots, no slashes already)
    if (!trimmed.contains('.') && !trimmed.contains('/') && trimmed.isNotEmpty) {
      trimmed = '$trimmed.com';
    }

    // If site already exists — UPDATE its time limit instead of rejecting
    final sites = ref.read(blocklistProvider).sites;
    final existingIdx = sites.indexWhere((s) => s.url == trimmed);
    if (existingIdx != -1) {
      setState(() { _adding = true; _error = null; });
      await ref.read(blocklistProvider.notifier).updateBudget(
        sites[existingIdx].id, _useTimeLimit ? _budgetMinutes : 0);
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() { _adding = true; _error = null; });
    await ref.read(blocklistProvider.notifier).addSite(
      url: url,
      dailyBudgetMinutes: _useTimeLimit ? _budgetMinutes : 0,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bottom  = MediaQuery.of(context).viewInsets.bottom;
    final bg2  = isDark ? FGColors.bg2 : FGColorsLight.bg2;
    final bg3  = isDark ? FGColors.bg3 : FGColorsLight.bg3;
    final bg4  = isDark ? FGColors.bg4 : FGColorsLight.bg4;
    final b2   = isDark ? FGColors.border2     : FGColorsLight.border2;
    final tp   = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts   = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt   = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final p    = isDark ? FGColors.purple      : FGColorsLight.purple;

    return Container(
      decoration: BoxDecoration(
        color: bg2,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: b2)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: b2, borderRadius: FGRadius.full),
              ),
            ),
            const SizedBox(height: 20),

            Text('Block a site or app',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: tp)),
            const SizedBox(height: 4),
            Text(
                'Enter a domain (e.g. instagram.com) or path (e.g. youtube/shorts).',
                style: TextStyle(
                    fontFamily: 'DM Sans', fontSize: 12, color: ts)),
            const SizedBox(height: 18),

            // Already-exists info (not an error — shows update mode)
            Builder(builder: (_) {
              final url = _urlCtrl.text.trim().toLowerCase()
                  .replaceAll(RegExp(r'^https?://'), '')
                  .replaceAll(RegExp(r'^www\.'), '');
              final exists = url.isNotEmpty &&
                  ref.watch(blocklistProvider).sites.any((s) => s.url == url);
              if (!exists) return const SizedBox.shrink();
              final teal = isDark ? FGColors.teal : FGColorsLight.teal;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.08), borderRadius: FGRadius.sm,
                    border: Border.all(color: teal.withOpacity(0.3))),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, color: teal, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text('This entry exists. Toggle the time limit below to update it.',
                      style: TextStyle(fontFamily: 'DM Sans', fontSize: 12,
                        color: teal, height: 1.3))),
                  ])));
            }),
            // Error
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? FGColors.red : FGColorsLight.red)
                      .withOpacity(0.1),
                  borderRadius: FGRadius.sm,
                  border: Border.all(
                      color: (isDark ? FGColors.red : FGColorsLight.red)
                          .withOpacity(0.35)),
                ),
                child: Text(_error!,
                    style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: isDark ? FGColors.red : FGColorsLight.red)),
              ),
              const SizedBox(height: 12),
            ],

            // ── URL INPUT ──
            _L('What to block', tt),
            TextField(
              controller: _urlCtrl,
              autofocus: true,
              keyboardType: TextInputType.url,
              style: TextStyle(
                  fontFamily: 'DM Sans', fontSize: 14, color: tp),
              cursorColor: p,
              decoration: InputDecoration(
                hintText: 'e.g.  youtube/shorts  or  instagram.com',
                hintStyle:
                    TextStyle(color: tt, fontSize: 13),
                filled: true,
                fillColor: bg4,
                prefixIcon:
                    Icon(Icons.link_rounded, color: tt, size: 18),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: FGRadius.md,
                    borderSide: BorderSide(color: b2)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: FGRadius.md,
                    borderSide: BorderSide(color: b2)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: FGRadius.md,
                    borderSide: BorderSide(color: p, width: 1.5)),
              ),
            ),
            const SizedBox(height: 6),
            Text('No https:// or www. needed',
                style: TextStyle(
                    fontFamily: 'DM Sans', fontSize: 11, color: tt)),
            const SizedBox(height: 16),

            // ── QUICK SUGGESTIONS ──
            _L('Quick add suggestions', tt),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kQuickAddSuggestions
                  .map((url) => GestureDetector(
                        onTap: () =>
                            setState(() => _urlCtrl.text = url),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: bg4,
                            borderRadius: FGRadius.full,
                            border: Border.all(color: b2),
                          ),
                          child: Text(url,
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  color: ts)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 16),

            // ── TIME LIMIT (chip-only, NO Slider to avoid crash) ──────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _useTimeLimit ? p.withOpacity(0.08) : bg3,
                borderRadius: FGRadius.md,
                border: Border.all(color: _useTimeLimit ? p.withOpacity(0.3) : b2)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.timer_outlined,
                    color: _useTimeLimit
                      ? (isDark ? FGColors.purpleLight : FGColorsLight.purpleLight) : tt,
                    size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Set daily time limit',
                      style: TextStyle(fontFamily: 'DM Sans', fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _useTimeLimit
                          ? (isDark ? FGColors.purpleLight : FGColorsLight.purpleLight) : tp)),
                    Text(_useTimeLimit
                        ? 'Block after ${_budgetMinutes} min/day'
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
              ])),
            const SizedBox(height: 20),

            // Submit
            FGButton(
              label: _useTimeLimit
                  ? 'Block (${_budgetMinutes}min/day limit)'
                  : 'Block always',
              icon: Icons.block_rounded,
              loading: _adding,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _L(String t, Color c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t.toUpperCase(),
            style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: c,
                letterSpacing: 0.1)));
}

// ── EMPTY STATE ───────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark, required this.onAdd});
  final bool isDark;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p  = isDark ? FGColors.purple      : FGColorsLight.purple;
    final tp = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt = isDark ? FGColors.textThird   : FGColorsLight.textThird;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.withOpacity(0.1),
                border: Border.all(color: p.withOpacity(0.25)),
              ),
              child: const Center(
                  child: Text('🛡️',
                      style: TextStyle(fontSize: 40))),
            ),
            const SizedBox(height: 20),
            Text('Nothing blocked yet',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: tp)),
            const SizedBox(height: 8),
            Text(
              'Add sites you want to block.\nYouTube Shorts, Instagram Reels, TikTok — your call.',
              style: TextStyle(
                  fontFamily: 'DM Sans', fontSize: 13, color: ts),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Type a site name or URL — canva.com, youtube.com, etc.',
              style: TextStyle(
                  fontFamily: 'DM Sans', fontSize: 12, color: tt),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FGButton(
              label: 'Add first block',
              icon: Icons.add_rounded,
              small: true,
              onTap: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('No sites in this category',
          style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: isDark ? FGColors.textThird : FGColorsLight.textThird)),
    );
  }
}

// ── SKELETON ──────────────────────────────────
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? FGColors.bg3 : FGColorsLight.bg3,
          borderRadius: FGRadius.md,
        ),
      ),
    );
  }
}