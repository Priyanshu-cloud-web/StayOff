import 'package:equatable/equatable.dart';

enum SiteCategory {
  social, shortsReels, gaming, entertainment, other;

  String get label => switch (this) {
    SiteCategory.social        => 'Social',
    SiteCategory.shortsReels   => 'Reels',
    SiteCategory.gaming        => 'Gaming',
    SiteCategory.entertainment => 'Entertainment',
    SiteCategory.other         => 'Other',
  };

  String get emoji => switch (this) {
    SiteCategory.social        => '💬',
    SiteCategory.shortsReels   => '🎬',
    SiteCategory.gaming        => '🎮',
    SiteCategory.entertainment => '🎭',
    SiteCategory.other         => '🌐',
  };
}

class BlockedSite extends Equatable {
  const BlockedSite({
    required this.id,
    required this.url,
    required this.category,
    required this.dailyBudgetMinutes,
    required this.isActive,
    required this.addedAt,
    this.minutesUsedToday = 0,
  });

  final int id;
  final String url;
  final SiteCategory category;
  final int dailyBudgetMinutes; // 0 = always block
  final bool isActive;
  final DateTime addedAt;
  final int minutesUsedToday;

  bool get isAlwaysBlocked => dailyBudgetMinutes == 0;
  int get minutesRemaining =>
      isAlwaysBlocked ? 0 : (dailyBudgetMinutes - minutesUsedToday).clamp(0, dailyBudgetMinutes);
  double get budgetProgress => isAlwaysBlocked
      ? 1.0 : dailyBudgetMinutes == 0 ? 0.0
      : (minutesUsedToday / dailyBudgetMinutes).clamp(0.0, 1.0);

  String get faviconEmoji {
    if (url.contains('instagram')) return '📸';
    if (url.contains('youtube'))   return '▶️';
    if (url.contains('tiktok'))    return '🎵';
    if (url.contains('snapchat'))  return '👻';
    if (url.contains('twitter') || url.contains('x.com')) return '𝕏';
    if (url.contains('facebook'))  return '📘';
    if (url.contains('reddit'))    return '🟠';
    if (url.contains('bgmi') || url.contains('freefire')) return '🎮';
    if (url.contains('netflix'))   return '🎬';
    if (url.contains('pinterest')) return '📌';
    return '🌐';
  }

  BlockedSite copyWith({
    int? id, String? url, SiteCategory? category,
    int? dailyBudgetMinutes, bool? isActive,
    DateTime? addedAt, int? minutesUsedToday,
  }) => BlockedSite(
    id: id ?? this.id, url: url ?? this.url,
    category: category ?? this.category,
    dailyBudgetMinutes: dailyBudgetMinutes ?? this.dailyBudgetMinutes,
    isActive: isActive ?? this.isActive, addedAt: addedAt ?? this.addedAt,
    minutesUsedToday: minutesUsedToday ?? this.minutesUsedToday,
  );

  @override
  List<Object?> get props => [id, url, category, dailyBudgetMinutes, isActive, addedAt];
}

const kQuickAddSuggestions = [
  'instagram/reels', 'youtube/shorts', 'tiktok.com',
  'snapchat.com', 'reddit.com', 'twitter.com', 'facebook.com',
  'netflix.com', 'bgmi.in',
];