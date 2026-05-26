// import 'package:equatable/equatable.dart';
// import 'package:flutter/material.dart';
// import 'dart:typed_data';

// enum AppCategory {
//   social,
//   shortsReels,
//   gaming,
//   entertainment,
//   messaging,
//   other;

//   String get label => switch (this) {
//     AppCategory.social        => 'Social',
//     AppCategory.shortsReels   => 'Reels',
//     AppCategory.gaming        => 'Gaming',
//     AppCategory.entertainment => 'Entertainment',
//     AppCategory.messaging     => 'Messaging',
//     AppCategory.other         => 'Other',
//   };
// }

// class BlockedApp extends Equatable {
//   const BlockedApp({
//     required this.packageName,
//     required this.displayName,
//     required this.category,
//     required this.dailyBudgetMinutes,
//     required this.isActive,
//     this.minutesUsedToday = 0,
//     this.iconEmoji = '📱',
//     this.iconColor,
//   });

//   final String packageName;
//   final String displayName;
//   final AppCategory category;
//   final int dailyBudgetMinutes; // 0 = always block
//   final bool isActive;
//   final int minutesUsedToday;
//   final String iconEmoji;
//   final Color? iconColor;
//   final Uint8List? icon;

//   bool get isAlwaysBlocked => dailyBudgetMinutes == 0;

//   int get minutesRemaining => isAlwaysBlocked
//       ? 0
//       : (dailyBudgetMinutes - minutesUsedToday).clamp(0, dailyBudgetMinutes);

//   double get budgetProgress => isAlwaysBlocked
//       ? 1.0
//       : dailyBudgetMinutes == 0
//           ? 0.0
//           : (minutesUsedToday / dailyBudgetMinutes).clamp(0.0, 1.0);

//   BlockedApp copyWith({
//     String? packageName,
//     String? displayName,
//     AppCategory? category,
//     int? dailyBudgetMinutes,
//     bool? isActive,
//     int? minutesUsedToday,
//     String? iconEmoji,
//     Color? iconColor,
//     Uint8List? icon,
//     icon: icon ?? this.icon,
//   }) =>
//       BlockedApp(
//         packageName: packageName ?? this.packageName,
//         displayName: displayName ?? this.displayName,
//         category: category ?? this.category,
//         dailyBudgetMinutes: dailyBudgetMinutes ?? this.dailyBudgetMinutes,
//         isActive: isActive ?? this.isActive,
//         minutesUsedToday: minutesUsedToday ?? this.minutesUsedToday,
//         iconEmoji: iconEmoji ?? this.iconEmoji,
//         iconColor: iconColor ?? this.iconColor,
//       );

//   @override
//   List<Object?> get props =>
//       [packageName, displayName, category, dailyBudgetMinutes, isActive];
// }

// // ── SUGGESTED APPS LIST ───────────────────────
// class SuggestedApp {
//   const SuggestedApp({
//     required this.packageName,
//     required this.displayName,
//     required this.iconEmoji,
//     required this.iconColor,
//     required this.category,
//   });
//   final String packageName;
//   final String displayName;
//   final String iconEmoji;
//   final Color iconColor;
//   final AppCategory category;
// }

// const kSuggestedApps = [
//   SuggestedApp(
//     packageName: 'com.instagram.android',
//     displayName: 'Instagram',
//     iconEmoji: '📸',
//     iconColor: Color(0xFFE1306C),
//     category: AppCategory.social,
//   ),
//   SuggestedApp(
//     packageName: 'com.zhiliaoapp.musically',
//     displayName: 'TikTok',
//     iconEmoji: '🎵',
//     iconColor: Color(0xFF010101),
//     category: AppCategory.shortsReels,
//   ),
//   SuggestedApp(
//     packageName: 'com.snapchat.android',
//     displayName: 'Snapchat',
//     iconEmoji: '👻',
//     iconColor: Color(0xFFFFFC00),
//     category: AppCategory.social,
//   ),
//   SuggestedApp(
//     packageName: 'com.twitter.android',
//     displayName: 'Twitter / X',
//     iconEmoji: '𝕏',
//     iconColor: Color(0xFF000000),
//     category: AppCategory.social,
//   ),
//   SuggestedApp(
//     packageName: 'com.facebook.katana',
//     displayName: 'Facebook',
//     iconEmoji: '📘',
//     iconColor: Color(0xFF1877F2),
//     category: AppCategory.social,
//   ),
//   SuggestedApp(
//     packageName: 'com.google.android.youtube',
//     displayName: 'YouTube',
//     iconEmoji: '▶️',
//     iconColor: Color(0xFFFF0000),
//     category: AppCategory.shortsReels,
//   ),
//   SuggestedApp(
//     packageName: 'com.reddit.frontpage',
//     displayName: 'Reddit',
//     iconEmoji: '🟠',
//     iconColor: Color(0xFFFF4500),
//     category: AppCategory.social,
//   ),
//   SuggestedApp(
//     packageName: 'com.pinterest',
//     displayName: 'Pinterest',
//     iconEmoji: '📌',
//     iconColor: Color(0xFFE60023),
//     category: AppCategory.social,
//   ),
//   SuggestedApp(
//     packageName: 'com.pubg.imobile',
//     displayName: 'BGMI',
//     iconEmoji: '🎮',
//     iconColor: Color(0xFFF5A623),
//     category: AppCategory.gaming,
//   ),
//   SuggestedApp(
//     packageName: 'com.dts.freefireth',
//     displayName: 'Free Fire',
//     iconEmoji: '🔥',
//     iconColor: Color(0xFFFF6B35),
//     category: AppCategory.gaming,
//   ),
//   SuggestedApp(
//     packageName: 'com.whatsapp',
//     displayName: 'WhatsApp',
//     iconEmoji: '💬',
//     iconColor: Color(0xFF25D366),
//     category: AppCategory.messaging,
//   ),
//   SuggestedApp(
//     packageName: 'com.netflix.mediaclient',
//     displayName: 'Netflix',
//     iconEmoji: '🎬',
//     iconColor: Color(0xFFE50914),
//     category: AppCategory.entertainment,
//   ),
//   // ── Gaming ──────────────────────────────────────────────────────────
//   SuggestedApp(
//     packageName: 'com.activision.callofduty.shooter',
//     displayName: 'COD Mobile',
//     iconEmoji: '🔫',
//     iconColor: Color(0xFF1E90FF),
//     category: AppCategory.gaming,
//   ),
//   SuggestedApp(
//     packageName: 'com.garena.game.codm',
//     displayName: 'COD (Garena)',
//     iconEmoji: '🔫',
//     iconColor: Color(0xFF1A1A2E),
//     category: AppCategory.gaming,
//   ),
//   SuggestedApp(
//     packageName: 'com.supercell.clashofclans',
//     displayName: 'Clash of Clans',
//     iconEmoji: '⚔️',
//     iconColor: Color(0xFF4CAF50),
//     category: AppCategory.gaming,
//   ),
//   SuggestedApp(
//     packageName: 'com.supercell.clashroyale',
//     displayName: 'Clash Royale',
//     iconEmoji: '🃏',
//     iconColor: Color(0xFF2196F3),
//     category: AppCategory.gaming,
//   ),
//   SuggestedApp(
//     packageName: 'com.miHoYo.GenshinImpact',
//     displayName: 'Genshin Impact',
//     iconEmoji: '🌟',
//     iconColor: Color(0xFF6A5ACD),
//     category: AppCategory.gaming,
//   ),
//   SuggestedApp(
//     packageName: 'com.roblox.client',
//     displayName: 'Roblox',
//     iconEmoji: '🎮',
//     iconColor: Color(0xFFE02020),
//     category: AppCategory.gaming,
//   ),
//   SuggestedApp(
//     packageName: 'com.mojang.minecraftpe',
//     displayName: 'Minecraft',
//     iconEmoji: '⛏️',
//     iconColor: Color(0xFF8B6914),
//     category: AppCategory.gaming,
//   ),
//   // ── Entertainment ────────────────────────────────────────────────────
//   SuggestedApp(
//     packageName: 'com.amazon.avod.thirdpartyclient',
//     displayName: 'Prime Video',
//     iconEmoji: '🎥',
//     iconColor: Color(0xFF00A8E1),
//     category: AppCategory.entertainment,
//   ),
//   SuggestedApp(
//     packageName: 'com.hotstar',
//     displayName: 'Hotstar',
//     iconEmoji: '⭐',
//     iconColor: Color(0xFF1E3A5F),
//     category: AppCategory.entertainment,
//   ),
//   SuggestedApp(
//     packageName: 'com.zee5.android',
//     displayName: 'ZEE5',
//     iconEmoji: '📺',
//     iconColor: Color(0xFF6B3FD4),
//     category: AppCategory.entertainment,
//   ),
//   SuggestedApp(
//     packageName: 'in.startv.hotstar',
//     displayName: 'JioCinema',
//     iconEmoji: '🎞️',
//     iconColor: Color(0xFF003087),
//     category: AppCategory.entertainment,
//   ),
//   SuggestedApp(
//     packageName: 'com.spotify.music',
//     displayName: 'Spotify',
//     iconEmoji: '🎵',
//     iconColor: Color(0xFF1DB954),
//     category: AppCategory.entertainment,
//   ),
//   // ── Social / Messaging ───────────────────────────────────────────────
//   SuggestedApp(
//     packageName: 'com.telegram.messenger',
//     displayName: 'Telegram',
//     iconEmoji: '✈️',
//     iconColor: Color(0xFF2CA5E0),
//     category: AppCategory.messaging,
//   ),
//   SuggestedApp(
//     packageName: 'org.thoughtcrime.securesms',
//     displayName: 'Signal',
//     iconEmoji: '🔒',
//     iconColor: Color(0xFF3A76F0),
//     category: AppCategory.messaging,
//   ),
//   SuggestedApp(
//     packageName: 'com.discord',
//     displayName: 'Discord',
//     iconEmoji: '💬',
//     iconColor: Color(0xFF5865F2),
//     category: AppCategory.messaging,
//   ),
//   SuggestedApp(
//     packageName: 'com.linkedin.android',
//     displayName: 'LinkedIn',
//     iconEmoji: '💼',
//     iconColor: Color(0xFF0077B5),
//     category: AppCategory.social,
//   ),
//   SuggestedApp(
//     packageName: 'com.sharechat.sharechat',
//     displayName: 'ShareChat',
//     iconEmoji: '📱',
//     iconColor: Color(0xFFFF4081),
//     category: AppCategory.social,
//   ),
//   SuggestedApp(
//     packageName: 'com.mxtech.videoplayer.ad',
//     displayName: 'MX Player',
//     iconEmoji: '▶️',
//     iconColor: Color(0xFFFF6D00),
//     category: AppCategory.entertainment,
//   ),
//   SuggestedApp(
//     packageName: 'com.joshapp.android',
//     displayName: 'Josh (Shorts)',
//     iconEmoji: '🎬',
//     iconColor: Color(0xFF00BCD4),
//     category: AppCategory.shortsReels,
//   ),
//   SuggestedApp(
//     packageName: 'com.moj.app',
//     displayName: 'Moj (Shorts)',
//     iconEmoji: '🎭',
//     iconColor: Color(0xFFFF5722),
//     category: AppCategory.shortsReels,
//   ),
// ];



import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

enum AppCategory {
  social,
  shortsReels,
  gaming,
  entertainment,
  messaging,
  other;

  String get label => switch (this) {
        AppCategory.social        => 'Social',
        AppCategory.shortsReels   => 'Reels',
        AppCategory.gaming        => 'Gaming',
        AppCategory.entertainment => 'Entertainment',
        AppCategory.messaging     => 'Messaging',
        AppCategory.other         => 'Other',
      };
}

class BlockedApp extends Equatable {
  const BlockedApp({
    required this.packageName,
    required this.displayName,
    required this.category,
    required this.dailyBudgetMinutes,
    required this.isActive,
    this.minutesUsedToday = 0,
    this.iconEmoji = '📱',
    this.iconColor,
    this.icon,
  });

  final String packageName;
  final String displayName;

  String get appName => displayName;

  final AppCategory category;
  final int dailyBudgetMinutes;
  final bool isActive;
  final int minutesUsedToday;

  final String iconEmoji;
  final Color? iconColor;

  // REAL APP ICON BYTES
  final Uint8List? icon;

  bool get isAlwaysBlocked => dailyBudgetMinutes == 0;

  int get minutesRemaining => isAlwaysBlocked
      ? 0
      : (dailyBudgetMinutes - minutesUsedToday)
          .clamp(0, dailyBudgetMinutes);

  double get budgetProgress => isAlwaysBlocked
      ? 1.0
      : (minutesUsedToday / dailyBudgetMinutes)
          .clamp(0.0, 1.0);

  // BlockedApp copyWith({
  //   String? packageName,
  //   String? displayName,
  //   AppCategory? category,
  //   int? dailyBudgetMinutes,
  //   bool? isActive,
  //   int? minutesUsedToday,
  //   String? iconEmoji,
  //   Color? iconColor,
  //   Uint8List? icon,
  // }) {
  //   return BlockedApp(
  //     packageName: packageName ?? this.packageName,
  //     displayName: displayName ?? this.displayName,
  //     category: category ?? this.category,
  //     dailyBudgetMinutes:
  //         dailyBudgetMinutes ?? this.dailyBudgetMinutes,
  //     isActive: isActive ?? this.isActive,
  //     minutesUsedToday:
  //         minutesUsedToday ?? this.minutesUsedToday,
  //     iconEmoji: iconEmoji ?? this.iconEmoji,
  //     iconColor: iconColor ?? this.iconColor,
  //     icon: icon ?? this.icon,
  //   );
  // }

  BlockedApp copyWith({
    String? packageName,
    String? displayName,
    AppCategory? category,
    int? dailyBudgetMinutes,
    bool? isActive,
    int? minutesUsedToday,
    String? iconEmoji,
    Color? iconColor,
    Uint8List? icon,
  }) {
    return BlockedApp(
      packageName: packageName ?? this.packageName,
      displayName: displayName ?? this.displayName,
      category: category ?? this.category,
      dailyBudgetMinutes:
          dailyBudgetMinutes ?? this.dailyBudgetMinutes,
      isActive: isActive ?? this.isActive,
      minutesUsedToday:
          minutesUsedToday ?? this.minutesUsedToday,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      iconColor: iconColor ?? this.iconColor,
      icon: icon ?? this.icon,
    );
  }

  // @override
  // List<Object?> get props => [
  //       packageName,
  //       displayName,
  //       category,
  //       dailyBudgetMinutes,
  //       isActive,
  //       minutesUsedToday,
  //       iconEmoji,
  //       iconColor,
  //       icon,
  //     ];
  @override
  List<Object?> get props => [
        packageName,
        displayName,
        category,
        dailyBudgetMinutes,
        isActive,
        minutesUsedToday,
        iconEmoji,
        iconColor,
        icon,
      ];
}

// ── SUGGESTED APPS ─────────────────────────────

class SuggestedApp {
  const SuggestedApp({
    required this.packageName,
    required this.displayName,
    required this.iconEmoji,
    required this.iconColor,
    required this.category,
    this.icon,
  });

  final String packageName;
  final String displayName;

  final String iconEmoji;
  final Color iconColor;

  // REAL APP ICON BYTES
  final Uint8List? icon;

  final AppCategory category;
}