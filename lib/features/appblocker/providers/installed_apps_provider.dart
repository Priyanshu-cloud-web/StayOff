import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import '../models/blocked_app.dart';

final installedAppsProvider =
    StateNotifierProvider<InstalledAppsNotifier, InstalledAppsState>(
  (ref) => InstalledAppsNotifier(),
);

class InstalledAppsState {
  final bool loading;
  final List<BlockedApp> apps;
  final List<BlockedApp> filtered;
  final String query;

  const InstalledAppsState({
    this.loading = false,
    this.apps = const [],
    this.filtered = const [],
    this.query = '',
  });

  InstalledAppsState copyWith({
    bool? loading,
    List<BlockedApp>? apps,
    List<BlockedApp>? filtered,
    String? query,
  }) {
    return InstalledAppsState(
      loading: loading ?? this.loading,
      apps: apps ?? this.apps,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
    );
  }
}

class InstalledAppsNotifier extends StateNotifier<InstalledAppsState> {
  InstalledAppsNotifier() : super(const InstalledAppsState()) {
    loadApps();
  }

  Future<void> loadApps() async {
    state = state.copyWith(loading: true);

    try {
      final List<AppInfo> installedApps =
          await InstalledApps.getInstalledApps(
        true,
        true,
      );

      final apps = installedApps.map((app) {
        Uint8List? iconBytes;

        try {
          iconBytes = app.icon;
        } catch (_) {}

        return BlockedApp(
          packageName: app.packageName,
          displayName: app.name,
          category: AppCategory.other,
          dailyBudgetMinutes: 30,
          isActive: false,
          icon: iconBytes,
        );
      }).toList();

      apps.sort(
        (a, b) => a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase()),
      );

      state = state.copyWith(
        loading: false,
        apps: apps,
        filtered: apps,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
      );
    }
  }

  void search(String query) {
    final filtered = state.apps.where((app) {
      return app.displayName
          .toLowerCase()
          .contains(query.toLowerCase());
    }).toList();

    state = state.copyWith(
      query: query,
      filtered: filtered,
    );
  }
}