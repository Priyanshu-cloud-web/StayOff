import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLockExpiry = 'fg_lock_expiry';

class LockState {
  const LockState({this.expiryDate, this.isLoading = true});
  final DateTime? expiryDate;
  final bool isLoading;

  bool get isLocked => expiryDate != null && expiryDate!.isAfter(DateTime.now());

  String get remainingLabel {
    if (expiryDate == null) return 'None';
    final diff = expiryDate!.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 60) return '${(diff.inDays / 30).round()}mo';
    if (diff.inDays > 0)  return '${diff.inDays}d';
    return '${diff.inHours}h';
  }

  LockState copyWith({DateTime? expiryDate, bool? isLoading}) => LockState(
    expiryDate: expiryDate ?? this.expiryDate,
    isLoading: isLoading ?? this.isLoading,
  );
}

class LockNotifier extends StateNotifier<LockState> {
  LockNotifier() : super(const LockState()) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLockExpiry);
    if (raw != null) {
      final expiry = DateTime.tryParse(raw);
      state = LockState(expiryDate: expiry, isLoading: false);
    } else {
      state = const LockState(isLoading: false);
    }
  }

  Future<void> setLock(DateTime expiry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLockExpiry, expiry.toIso8601String());
    state = state.copyWith(expiryDate: expiry, isLoading: false);
  }

  Future<void> clearLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLockExpiry);
    state = const LockState(isLoading: false);
  }
}

final lockProvider = StateNotifierProvider<LockNotifier, LockState>(
  (_) => LockNotifier());