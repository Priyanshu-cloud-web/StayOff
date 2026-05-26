import 'package:focusguard/features/appblocker/models/blocked_app.dart';

class AppCategoryDetector {
  static AppCategory detect(String appName, String packageName) {
    final text = '${appName.toLowerCase()} ${packageName.toLowerCase()}';

    // SOCIAL
    if (_contains(text, [
      'instagram',
      'facebook',
      'twitter',
      'x.com',
      'reddit',
      'snapchat',
      'linkedin',
      'pinterest',
      'sharechat',
      'threads',
    ])) {
      return AppCategory.social;
    }

    // SHORTS / REELS
    if (_contains(text, [
      'youtube',
      'tiktok',
      'moj',
      'josh',
      'takatak',
      'reels',
      'shorts',
    ])) {
      return AppCategory.shortsReels;
    }

    // GAMING
    if (_contains(text, [
      'game',
      'pubg',
      'bgmi',
      'freefire',
      'roblox',
      'minecraft',
      'genshin',
      'clash',
      'callofduty',
      'steam',
      'epic',
    ])) {
      return AppCategory.gaming;
    }

    // ENTERTAINMENT
    if (_contains(text, [
      'netflix',
      'hotstar',
      'primevideo',
      'spotify',
      'zee5',
      'jiocinema',
      'mxplayer',
      'music',
      'video',
    ])) {
      return AppCategory.entertainment;
    }
    // MESSAGING
    if (_contains(text, [
      'whatsapp',
      'telegram',
      'discord',
      'signal',
      'messenger',
      'wechat',
    ])) {
      return AppCategory.messaging;
    }

    return AppCategory.other;
  }

  static bool _contains(String value, List<String> items) {
    for (final item in items) {
      if (value.contains(item)) {
        return true;
      }
    }

    return false;
  }
}