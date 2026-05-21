import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusguard/features/blocklist/providers/blocklist_provider.dart';
import 'package:focusguard/features/appblocker/providers/appblocker_provider.dart';
import 'package:focusguard/features/safeguard/providers/safeguard_provider.dart';
import 'package:focusguard/features/lock/providers/lock_provider.dart';

const _quotes = [
  'Discipline is choosing between what you want now and what you want most.',
  'Focus is the art of knowing what to ignore.',
  'Every scroll is a trade. Your attention for someone else agenda.',
  'The apps are designed to keep you watching. You are designed to do more.',
  'Stop managing your time. Start managing your attention.',
  'What you do in the next 30 minutes shapes who you become.',
  'Small consistent actions build the life you actually want.',
  'Your future self is watching what you choose right now.',
  'The best time to put the phone down is always now.',
  'You need fewer distractions, not more time.',
  'Boredom is the beginning of creativity. Sit with it.',
  'Checking your phone will not make the anxiety go away. Creating something will.',
];

class DashboardData {
  const DashboardData({
    required this.sitesBlocked,
    required this.appsBlocked,
    required this.lockRemaining,
    required this.safeguardActive,
    required this.quote,
    required this.distractionsBlockedToday,
  });
  final int sitesBlocked;
  final int appsBlocked;
  final String lockRemaining;
  final bool safeguardActive;
  final String quote;
  final int distractionsBlockedToday;
}

class DashboardNotifier extends Notifier<DashboardData> {
  int _quoteIdx = 0;

  @override
  DashboardData build() {
    // Watch live providers — dashboard auto-updates when any change
    final blocklist  = ref.watch(blocklistProvider);
    final appBlocker = ref.watch(appBlockerProvider);
    final safeguard  = ref.watch(safeguardProvider);
    final lock       = ref.watch(lockProvider);

    return DashboardData(
      sitesBlocked: blocklist.totalActive,
      appsBlocked:  appBlocker.totalBlocked,
      lockRemaining: lock.remainingLabel,
      safeguardActive: safeguard.isEnabled,
      quote: _quotes[_quoteIdx],
      distractionsBlockedToday: blocklist.totalActive + appBlocker.totalBlocked,
    );
  }

  void refreshQuote() {
    _quoteIdx = (_quoteIdx + 1) % _quotes.length;
    ref.invalidateSelf();
  }
}

final dashboardProvider =
    NotifierProvider<DashboardNotifier, DashboardData>(DashboardNotifier.new);