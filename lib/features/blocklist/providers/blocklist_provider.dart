// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:focusguard/features/blocklist/models/blocked_site.dart';

// const _kSitesKey  = 'fg_blocked_sites';
// const _vpnChannel = MethodChannel('com.focusguard/vpn');

// class BlocklistState {
//   const BlocklistState({
//     this.sites = const [],
//     this.selectedCategory,
//     this.isLoading = false,
//   });
//   final List<BlockedSite> sites;
//   final SiteCategory? selectedCategory;
//   final bool isLoading;

//   List<BlockedSite> get filtered => selectedCategory == null
//       ? sites
//       : sites.where((s) => s.category == selectedCategory).toList();

//   int get totalActive => sites.where((s) => s.isActive).length;

//   BlocklistState copyWith({
//     List<BlockedSite>? sites,
//     SiteCategory? selectedCategory,
//     bool clearCategory = false,
//     bool? isLoading,
//   }) =>
//       BlocklistState(
//         sites: sites ?? this.sites,
//         selectedCategory:
//             clearCategory ? null : (selectedCategory ?? this.selectedCategory),
//         isLoading: isLoading ?? this.isLoading,
//       );
// }

// class BlocklistNotifier extends StateNotifier<BlocklistState> {
//   BlocklistNotifier() : super(const BlocklistState()) {
//     _load();
//   }

//   int _nextId = 1;

//   Future<void> _load() async {
//     state = state.copyWith(isLoading: true);
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final raw = prefs.getString(_kSitesKey);
//       if (raw != null && raw.isNotEmpty) {
//         final list = (jsonDecode(raw) as List)
//             .map((e) => _fromJson(e as Map<String, dynamic>))
//             .toList();
//         if (list.isNotEmpty) {
//           _nextId =
//               list.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
//         }
//         state = state.copyWith(sites: list, isLoading: false);
//         // Sync VPN after load — but safely, after frame
//         Future.microtask(() => _syncVpn(list));
//         return;
//       }
//     } catch (e) {
//       // Corrupted data — start fresh
//     }
//     // Start completely empty
//     state = state.copyWith(sites: [], isLoading: false);
//   }

//   Future<void> _save(List<BlockedSite> sites) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(
//           _kSitesKey, jsonEncode(sites.map(_toJson).toList()));
//     } catch (_) {}
//   }

//   Map<String, dynamic> _toJson(BlockedSite s) => {
//         'id':       s.id,
//         'url':      s.url,
//         'category': s.category.index,
//         'budget':   s.dailyBudgetMinutes,
//         'active':   s.isActive,
//         'addedAt':  s.addedAt.toIso8601String(),
//         'usedToday':s.minutesUsedToday,
//       };

//   BlockedSite _fromJson(Map<String, dynamic> j) => BlockedSite(
//         id:                 j['id'] as int,
//         url:                j['url'] as String,
//         category:           SiteCategory.values[j['category'] as int],
//         dailyBudgetMinutes: j['budget'] as int,
//         isActive:           j['active'] as bool,
//         addedAt:            DateTime.parse(j['addedAt'] as String),
//         minutesUsedToday:   (j['usedToday'] as int?) ?? 0,
//       );

//   // Safe VPN sync — never throws, always async
//   Future<void> _syncVpn(List<BlockedSite> sites) async {
//     try {
//       // Only send DOMAIN-level URLs to VPN (no slash = no path).
//       // Path-based URLs like youtube.com/shorts are handled by the
//       // Accessibility Service (writeBlockPrefs) — NOT the VPN.
//       // Sending youtube.com/shorts to VPN would block ALL of youtube.com.
//       final activeUrls = sites
//           .where((s) => s.isActive)
//           .map((s) => s.url)
//           .toList(); // send all — MainActivity filters the path-based ones
//       await _vpnChannel.invokeMethod(
//           'updateBlocklist', {'urls': activeUrls});
//     } catch (_) {
//       // VPN not running — silently ignore
//     }
//     _writeSiteBudgets(sites);
//   }

//   /// Read real-time usage from A11y SharedPrefs and update site state
//   Future<void> syncUsage() async {
//     try {
//       final result = await _vpnChannel.invokeMethod<Map>(
//           'readSiteUsage') as Map<Object?, Object?>?;
//       if (result == null) return;
//       final usedMs = (result['usedMs'] as String?) ?? '';
//       if (usedMs.isEmpty) return;

//       // Parse "youtube.com/shorts:183000,instagram.com/reels:60000"
//       final usageMap = <String, int>{};
//       for (final entry in usedMs.split(',')) {
//         final idx = entry.trim().lastIndexOf(':');
//         if (idx > 0) {
//           final key = entry.trim().substring(0, idx);
//           final ms  = int.tryParse(entry.trim().substring(idx + 1)) ?? 0;
//           usageMap[key] = (ms / 60000).floor();   // convert ms → minutes
//         }
//       }

//       // Update sites whose url matches a usage key
//       final updated = state.sites.map((s) {
//         final mins = usageMap[s.url] ?? usageMap[s.url.split('/').first];
//         if (mins != null && mins != s.minutesUsedToday) {
//           return s.copyWith(minutesUsedToday: mins);
//         }
//         return s;
//       }).toList();

//       if (updated != state.sites) {
//         state = state.copyWith(sites: updated);
//       }
//     } catch (_) {}
//   }

//   void _writeSiteBudgets(List<BlockedSite> sites) {
//     try {
//       final parts = <String>[];
//       for (final s in sites) {
//         if (s.isActive && s.dailyBudgetMinutes > 0) {
//           parts.add(s.url + ':' + s.dailyBudgetMinutes.toString());
//         }
//       }
//       final budgets = parts.join(',');
//       _vpnChannel.invokeMethod('writeSiteBudgets', {'budgets': budgets});
//     } catch (_) {}
//   }

//   // ── CRUD ──────────────────────────────────
//   // Auto-detect category from URL
//   static SiteCategory _detectCategory(String url) {
//     final u = url.toLowerCase();
//     if (u.contains('youtube') || u.contains('netflix') || u.contains('twitch') ||
//         u.contains('prime') || u.contains('disney') || u.contains('hulu'))
//       return SiteCategory.entertainment;
//     if (u.contains('instagram') || u.contains('tiktok') || u.contains('snapchat') ||
//         u.contains('twitter') || u.contains('x.com') || u.contains('facebook') ||
//         u.contains('linkedin') || u.contains('reddit') || u.contains('pinterest'))
//       return SiteCategory.social;
//     if (u.contains('shorts') || u.contains('reels') || u.contains('reel'))
//       return SiteCategory.shortsReels;
//     if (u.contains('whatsapp') || u.contains('telegram') || u.contains('discord') ||
//         u.contains('messenger') || u.contains('signal'))
//       return SiteCategory.social;
//     if (u.contains('game') || u.contains('steam') || u.contains('play') ||
//         u.contains('pubg') || u.contains('freefire'))
//       return SiteCategory.gaming;
//     return SiteCategory.other;
//   }

//   Future<void> addSite({
//     required String url,
//     required int dailyBudgetMinutes,
//     SiteCategory? category,
//   }) async {
//     final trimmed = url
//         .trim()
//         .toLowerCase()
//         .replaceAll(RegExp(r'^https?://'), '')
//         .replaceAll(RegExp(r'^www\.'), '');

//     if (trimmed.isEmpty) return;
//     if (state.sites.any((s) => s.url == trimmed)) return;

//     final site = BlockedSite(
//       id:                 _nextId++,
//       url:                trimmed,
//       category:           category ?? _detectCategory(trimmed),
//       dailyBudgetMinutes: dailyBudgetMinutes,
//       isActive:           true,
//       addedAt:            DateTime.now(),
//     );

//     final updated = [...state.sites, site];
//     state = state.copyWith(sites: updated);

//     // Save and sync AFTER state update — never inside it
//     await _save(updated);
//     Future.microtask(() => _syncVpn(updated));
//   }

//   Future<bool> toggleSite(int id) async {
//     // Cannot disable a block while commitment lock is active
//     final site = state.sites.firstWhere((s) => s.id == id);
//     if (!site.isActive) {
//       // Enabling is always allowed
//     } else {
//       // Disabling — check lock
//       final lockPrefs = await SharedPreferences.getInstance();
//       final raw = lockPrefs.getString('fg_lock_expiry');
//       if (raw != null) {
//         final expiry = DateTime.tryParse(raw);
//         if (expiry != null && expiry.isAfter(DateTime.now())) return false; // LOCKED
//       }
//     }
//     final updated = state.sites
//         .map((s) => s.id == id ? s.copyWith(isActive: !s.isActive) : s)
//         .toList();
//     state = state.copyWith(sites: updated);
//     await _save(updated);
//     Future.microtask(() => _syncVpn(updated));
//     return true;
//   }

//   Future<bool> deleteSite(int id) async {
//     // Cannot delete while commitment lock is active
//     final lockPrefs = await SharedPreferences.getInstance();
//     final raw = lockPrefs.getString('fg_lock_expiry');
//     if (raw != null) {
//       final expiry = DateTime.tryParse(raw);
//       if (expiry != null && expiry.isAfter(DateTime.now())) return false; // LOCKED
//     }
//     final updated = state.sites.where((s) => s.id != id).toList();
//     state = state.copyWith(sites: updated);
//     await _save(updated);
//     Future.microtask(() => _syncVpn(updated));
//     return true;
//   }

//   Future<void> updateBudget(int id, int minutes) async {
//     final updated = state.sites
//         .map((s) => s.id == id ? s.copyWith(dailyBudgetMinutes: minutes) : s)
//         .toList();
//     state = state.copyWith(sites: updated);
//     await _save(updated);
//   }

//   void setCategory(SiteCategory? cat) => state =
//       state.copyWith(selectedCategory: cat, clearCategory: cat == null);
// }

// final blocklistProvider =
//     StateNotifierProvider<BlocklistNotifier, BlocklistState>(
//   (_) => BlocklistNotifier());



import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:focusguard/features/blocklist/models/blocked_site.dart';

const _kSitesKey  = 'fg_blocked_sites';
const _vpnChannel = MethodChannel('com.focusguard/vpn');

class BlocklistState {
  const BlocklistState({
    this.sites = const [],
    this.selectedCategory,
    this.isLoading = false,
  });
  final List<BlockedSite> sites;
  final SiteCategory? selectedCategory;
  final bool isLoading;

  List<BlockedSite> get filtered => selectedCategory == null
      ? sites
      : sites.where((s) => s.category == selectedCategory).toList();

  int get totalActive => sites.where((s) => s.isActive).length;

  BlocklistState copyWith({
    List<BlockedSite>? sites,
    SiteCategory? selectedCategory,
    bool clearCategory = false,
    bool? isLoading,
  }) =>
      BlocklistState(
        sites: sites ?? this.sites,
        selectedCategory:
            clearCategory ? null : (selectedCategory ?? this.selectedCategory),
        isLoading: isLoading ?? this.isLoading,
      );
}

class BlocklistNotifier extends StateNotifier<BlocklistState> {
  BlocklistNotifier() : super(const BlocklistState()) {
    _load();
  }

  int _nextId = 1;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSitesKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((e) => _fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _nextId =
              list.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
        }
        state = state.copyWith(sites: list, isLoading: false);
        Future.microtask(() => _syncVpn(list));
        return;
      }
    } catch (e) {
      // Corrupted data — start fresh
    }
    state = state.copyWith(sites: [], isLoading: false);
  }

  Future<void> _save(List<BlockedSite> sites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kSitesKey, jsonEncode(sites.map(_toJson).toList()));
    } catch (_) {}
  }

  Map<String, dynamic> _toJson(BlockedSite s) => {
        'id':       s.id,
        'url':      s.url,
        'category': s.category.index,
        'budget':   s.dailyBudgetMinutes,
        'active':   s.isActive,
        'addedAt':  s.addedAt.toIso8601String(),
        'usedToday': s.minutesUsedToday,
      };

  BlockedSite _fromJson(Map<String, dynamic> j) => BlockedSite(
        id:                 j['id'] as int,
        url:                j['url'] as String,
        category:           SiteCategory.values[j['category'] as int],
        dailyBudgetMinutes: j['budget'] as int,
        isActive:           j['active'] as bool,
        addedAt:            DateTime.parse(j['addedAt'] as String),
        minutesUsedToday:   (j['usedToday'] as int?) ?? 0,
      );

  // UPDATED: Send alwaysBlock flag correctly
  Future<void> _syncVpn(List<BlockedSite> sites) async {
    try {
      final activeSites = sites.where((s) => s.isActive).toList();
      
      if (activeSites.isEmpty) {
        await _vpnChannel.invokeMethod('stopVpn');
        return;
      }
      
      // For path-based URLs (shorts/reels), send individually with alwaysBlock flag
      for (final site in activeSites) {
        final isAlwaysBlock = site.dailyBudgetMinutes == 0;
        
        // For path-based URLs like youtube.com/shorts
        if (site.url.contains('/')) {
          await _vpnChannel.invokeMethod('updateBlocklist', {
            'urls': [site.url],
            'alwaysBlock': isAlwaysBlock
          });
        }
      }
      
      // For domain-based URLs, send all at once
      final domainUrls = activeSites.where((s) => !s.url.contains('/')).map((s) => s.url).toList();
      if (domainUrls.isNotEmpty) {
        await _vpnChannel.invokeMethod('updateBlocklist', {
          'urls': domainUrls,
          'alwaysBlock': false
        });
      }
      
    } catch (e) {
      // VPN not running — silently ignore
      print('VPN sync error: $e');
    }
    _writeSiteBudgets(sites);
  }

  // UPDATED: Write site budgets for time-limited content
  void _writeSiteBudgets(List<BlockedSite> sites) {
    try {
      final parts = <String>[];
      for (final s in sites) {
        // Only include active sites with time limit (budget > 0)
        if (s.isActive && s.dailyBudgetMinutes > 0) {
          parts.add('${s.url}:${s.dailyBudgetMinutes}');
        }
      }
      final budgets = parts.join(',');
      if (budgets.isNotEmpty) {
        _vpnChannel.invokeMethod('writeSiteBudgets', {'budgets': budgets});
        print('Site budgets written: $budgets');
      }
    } catch (e) {
      print('Error writing site budgets: $e');
    }
  }

  // UPDATED: Better usage parsing
  Future<void> syncUsage() async {
    try {
      final result = await _vpnChannel.invokeMethod<Map>(
          'readSiteUsage') as Map<Object?, Object?>?;
      if (result == null) return;
      
      final usedMs = (result['usedMs'] as String?) ?? '';
      
      if (usedMs.isEmpty) return;

      // Parse usage map from "key:minutes,key2:minutes2" format
      final usageMap = <String, int>{};
      for (final entry in usedMs.split(',')) {
        if (entry.isEmpty) continue;
        final idx = entry.lastIndexOf(':');
        if (idx > 0) {
          final key = entry.substring(0, idx);
          final minutes = int.tryParse(entry.substring(idx + 1)) ?? 0;
          usageMap[key] = minutes;
        }
      }

      // Update sites whose url matches a usage key
      final updated = state.sites.map((s) {
        // Check exact match first
        var usedMinutes = usageMap[s.url];
        
        // For paths like "youtube.com/shorts", check if any key contains it
        if (usedMinutes == null) {
          for (final key in usageMap.keys) {
            if (key.contains(s.url) || s.url.contains(key)) {
              usedMinutes = usageMap[key];
              break;
            }
          }
        }
        
        if (usedMinutes != null && usedMinutes != s.minutesUsedToday) {
          return s.copyWith(minutesUsedToday: usedMinutes);
        }
        return s;
      }).toList();

      if (updated != state.sites) {
        state = state.copyWith(sites: updated);
      }
    } catch (e) {
      print('Error syncing usage: $e');
    }
  }

  static SiteCategory _detectCategory(String url) {
    final u = url.toLowerCase();
    if (u.contains('youtube') || u.contains('netflix') || u.contains('twitch') ||
        u.contains('prime') || u.contains('disney') || u.contains('hulu'))
      return SiteCategory.entertainment;
    if (u.contains('instagram') || u.contains('tiktok') || u.contains('snapchat') ||
        u.contains('twitter') || u.contains('x.com') || u.contains('facebook') ||
        u.contains('linkedin') || u.contains('reddit') || u.contains('pinterest'))
      return SiteCategory.social;
    if (u.contains('shorts') || u.contains('reels') || u.contains('reel'))
      return SiteCategory.shortsReels;
    if (u.contains('whatsapp') || u.contains('telegram') || u.contains('discord') ||
        u.contains('messenger') || u.contains('signal'))
      return SiteCategory.social;
    if (u.contains('game') || u.contains('steam') || u.contains('play') ||
        u.contains('pubg') || u.contains('freefire'))
      return SiteCategory.gaming;
    return SiteCategory.other;
  }

  Future<void> addSite({
    required String url,
    required int dailyBudgetMinutes,
    SiteCategory? category,
  }) async {
    final trimmed = url
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'^www\.'), '');

    if (trimmed.isEmpty) return;
    if (state.sites.any((s) => s.url == trimmed)) return;

    final site = BlockedSite(
      id:                 _nextId++,
      url:                trimmed,
      category:           category ?? _detectCategory(trimmed),
      dailyBudgetMinutes: dailyBudgetMinutes,
      isActive:           true,
      addedAt:            DateTime.now(),
    );

    final updated = [...state.sites, site];
    state = state.copyWith(sites: updated);

    await _save(updated);
    Future.microtask(() => _syncVpn(updated));
  }

  Future<bool> toggleSite(int id) async {
    final site = state.sites.firstWhere((s) => s.id == id);
    if (!site.isActive) {
      // Enabling is always allowed
    } else {
      // Disabling — check lock
      final lockPrefs = await SharedPreferences.getInstance();
      final raw = lockPrefs.getString('fg_lock_expiry');
      if (raw != null) {
        final expiry = DateTime.tryParse(raw);
        if (expiry != null && expiry.isAfter(DateTime.now())) return false;
      }
    }
    final updated = state.sites
        .map((s) => s.id == id ? s.copyWith(isActive: !s.isActive) : s)
        .toList();
    state = state.copyWith(sites: updated);
    await _save(updated);
    Future.microtask(() => _syncVpn(updated));
    return true;
  }

  Future<bool> deleteSite(int id) async {
    final lockPrefs = await SharedPreferences.getInstance();
    final raw = lockPrefs.getString('fg_lock_expiry');
    if (raw != null) {
      final expiry = DateTime.tryParse(raw);
      if (expiry != null && expiry.isAfter(DateTime.now())) return false;
    }
    final updated = state.sites.where((s) => s.id != id).toList();
    state = state.copyWith(sites: updated);
    await _save(updated);
    Future.microtask(() => _syncVpn(updated));
    return true;
  }

  Future<void> updateBudget(int id, int minutes) async {
    final updated = state.sites
        .map((s) => s.id == id ? s.copyWith(dailyBudgetMinutes: minutes) : s)
        .toList();
    state = state.copyWith(sites: updated);
    await _save(updated);
    Future.microtask(() => _syncVpn(updated));
  }

  void setCategory(SiteCategory? cat) => state =
      state.copyWith(selectedCategory: cat, clearCategory: cat == null);
}

final blocklistProvider =
    StateNotifierProvider<BlocklistNotifier, BlocklistState>(
  (_) => BlocklistNotifier());