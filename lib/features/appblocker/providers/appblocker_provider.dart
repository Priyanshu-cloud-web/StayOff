import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:focusguard/features/appblocker/models/blocked_app.dart';

const _kAppsKey   = 'fg_blocked_apps';
const _appChannel = MethodChannel('com.focusguard/app_blocker');

enum PermissionStatus { unknown, granted, denied }

class AppBlockerState {
  const AppBlockerState({
    this.blockedApps = const [],
    this.accessibilityPermission = PermissionStatus.unknown,
    this.isLoading = false,
  });
  final List<BlockedApp> blockedApps;
  final PermissionStatus accessibilityPermission;
  final bool isLoading;

  bool get a11yGranted => accessibilityPermission == PermissionStatus.granted;
  int  get totalBlocked => blockedApps.where((a) => a.isActive).length;

  AppBlockerState copyWith({
    List<BlockedApp>? blockedApps,
    PermissionStatus? accessibilityPermission,
    bool? isLoading,
  }) => AppBlockerState(
    blockedApps: blockedApps ?? this.blockedApps,
    accessibilityPermission: accessibilityPermission ?? this.accessibilityPermission,
    isLoading: isLoading ?? this.isLoading,
  );
}

class AppBlockerNotifier extends StateNotifier<AppBlockerState> {
  AppBlockerNotifier() : super(const AppBlockerState()) {
    _init();
    // Listen for real-time accessibility status pushed from MainActivity.onResume()
    _appChannel.setMethodCallHandler((call) async {
      if (call.method == '_notifyA11yStatus') {
        final granted = call.arguments as bool? ?? false;
        state = state.copyWith(
          accessibilityPermission:
              granted ? PermissionStatus.granted : PermissionStatus.denied);
      }
    });
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await Future.wait([_checkA11y(), _load()]);
    state = state.copyWith(isLoading: false);
  }

  // ── PERSISTENCE ─────────────────────────────────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kAppsKey);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => _fromJson(e as Map<String, dynamic>)).toList();
        state = state.copyWith(blockedApps: list);
        return;
      } catch (_) {}
    }
    state = state.copyWith(blockedApps: []);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppsKey,
        jsonEncode(state.blockedApps.map(_toJson).toList()));
  }

  Map<String, dynamic> _toJson(BlockedApp a) => {
    'pkg': a.packageName, 'name': a.displayName, 'cat': a.category.index,
    'budget': a.dailyBudgetMinutes, 'active': a.isActive,
    'used': a.minutesUsedToday, 'emoji': a.iconEmoji,
    'color': a.iconColor?.value ?? 0xFF7C6FED,
  };

  BlockedApp _fromJson(Map<String, dynamic> j) => BlockedApp(
    packageName: j['pkg'] as String, displayName: j['name'] as String,
    category: AppCategory.values[j['cat'] as int],
    dailyBudgetMinutes: j['budget'] as int, isActive: j['active'] as bool,
    minutesUsedToday: (j['used'] as int?) ?? 0,
    iconEmoji: (j['emoji'] as String?) ?? '📱',
    iconColor: Color((j['color'] as int?) ?? 0xFF7C6FED),
  );

  // ── PERMISSIONS ─────────────────────────────────────────────────
  Future<void> _checkA11y() async {
    try {
      final ok = await _appChannel.invokeMethod<bool>('checkAccessibilityPermission') ?? false;
      state = state.copyWith(
        accessibilityPermission: ok ? PermissionStatus.granted : PermissionStatus.denied);
    } on PlatformException {
      state = state.copyWith(accessibilityPermission: PermissionStatus.denied);
    }
  }

  /// Opens directly to FocusGuard's accessibility entry, then re-checks on return.
  Future<void> openAccessibilitySettings() async {
    try {
      await _appChannel.invokeMethod('openAccessibilitySettings');
    } on PlatformException { /* ignore */ }
    // Poll until granted or 10 s passes (handles return from settings)
    for (var i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkA11y();
      if (state.a11yGranted) break;
    }
  }

  // Force re-check (called by UI on app resume)
  Future<void> refreshA11y() => _checkA11y();

  // ── CRUD ────────────────────────────────────────────────────────
  Future<void> addApp(SuggestedApp s, {int budgetMinutes = 0}) async {
    if (state.blockedApps.any((a) => a.packageName == s.packageName)) return;
    final app = BlockedApp(
      packageName: s.packageName, displayName: s.displayName,
      category: s.category, dailyBudgetMinutes: budgetMinutes,
      isActive: true, iconEmoji: s.iconEmoji, iconColor: s.iconColor,
    );
    state = state.copyWith(blockedApps: [...state.blockedApps, app]);
    await _save();
    _native('addBlockedApp', {'packageName': s.packageName, 'budgetMinutes': budgetMinutes});
  }

  Future<void> toggleApp(String pkg) async {
    state = state.copyWith(
      blockedApps: state.blockedApps
          .map((a) => a.packageName == pkg ? a.copyWith(isActive: !a.isActive) : a).toList());
    await _save();
    _native('toggleApp', {'packageName': pkg});
  }

  Future<void> removeApp(String pkg) async {
    state = state.copyWith(blockedApps: state.blockedApps.where((a) => a.packageName != pkg).toList());
    await _save();
    _native('removeBlockedApp', {'packageName': pkg});
  }

  Future<void> updateBudget(String pkg, int mins) async {
    state = state.copyWith(
      blockedApps: state.blockedApps
          .map((a) => a.packageName == pkg ? a.copyWith(dailyBudgetMinutes: mins) : a).toList());
    await _save();
    _native('updateBudget', {'packageName': pkg, 'budgetMinutes': mins});
  }

  // Safe fire-and-forget native call
  void _native(String method, Map<String, dynamic> args) {
    Future.microtask(() async {
      try { await _appChannel.invokeMethod(method, args); } catch (_) {}
    });
  }
}

final appBlockerProvider =
    StateNotifierProvider<AppBlockerNotifier, AppBlockerState>(
  (_) => AppBlockerNotifier());