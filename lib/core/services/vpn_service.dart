import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusguard/features/blocklist/providers/blocklist_provider.dart';

const _vpnChannel = MethodChannel('com.focusguard/vpn');

class VpnService {
  static Future<bool> startWithBlocklist(List<String> urls) async {
    try {
      final result = await _vpnChannel.invokeMethod<bool>(
        'startVpn', {'urls': urls});
      return result ?? false;
    } on PlatformException catch (e) {
      if (e.code == 'VPN_DENIED') return false;
      return false;
    }
  }

  static Future<void> updateBlocklist(List<String> urls) async {
    try {
      await _vpnChannel.invokeMethod('updateBlocklist', {'urls': urls});
    } on PlatformException { /* ignore */ }
  }

  static Future<void> stop() async {
    try {
      await _vpnChannel.invokeMethod('stopVpn');
    } on PlatformException { /* ignore */ }
  }

  static Future<bool> isRunning() async {
    try {
      return await _vpnChannel.invokeMethod<bool>('isVpnRunning') ?? false;
    } on PlatformException { return false; }
  }
}

// Provider that auto-starts VPN when app opens
final vpnInitProvider = Provider<void>((ref) {
  // Watch the blocklist — whenever it changes, sync to VPN
  final blocklist = ref.watch(blocklistProvider);
  final activeUrls = blocklist.sites
      .where((s) => s.isActive)
      .map((s) => s.url)
      .toList();

  // Fire and forget
  Future.microtask(() => VpnService.updateBlocklist(activeUrls));
});