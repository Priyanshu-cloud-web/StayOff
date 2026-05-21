import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── CONFIG ────────────────────────────────────
// Change this to your machine's local IP when testing on a real device
// For emulator use: http://10.0.2.2:8000
// For real device use: http://192.168.x.x:8000
const kBaseUrl = 'http://10.0.2.2:8000';

// ── SECURE STORAGE KEYS ───────────────────────
const _kAccessToken  = 'fg_access_token';
const _kRefreshToken = 'fg_refresh_token';
const _kUserId       = 'fg_user_id';
const _kUserEmail    = 'fg_user_email';
const _kUserName     = 'fg_user_name';

// ── AUTH USER MODEL ───────────────────────────
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.accessToken,
    required this.refreshToken,
  });

  final int id;
  final String email;
  final String name;
  final String accessToken;
  final String refreshToken;
}

// ── API SERVICE ───────────────────────────────
class ApiService {
  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Attach JWT to every request automatically
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _kAccessToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // 401 → try refresh token once
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            // Retry original request with new token
            final token = await _storage.read(key: _kAccessToken);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        return handler.next(error);
      },
    ));
  }

  static final ApiService instance = ApiService._();

  late final Dio _dio;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── AUTH ──────────────────────────────────
  Future<AuthUser> login(String email, String password) async {
    final resp = await _dio.post('/api/login', data: {
      'email': email.trim(),
      'password': password,
    });
    final data = resp.data as Map<String, dynamic>;
    final user = AuthUser(
      id:           data['user_id'] as int,
      email:        data['email'] as String,
      name:         data['name'] as String,
      accessToken:  data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    await _saveUser(user);
    return user;
  }

  Future<AuthUser> register(String name, String email, String password) async {
    final resp = await _dio.post('/api/register', data: {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    });
    final data = resp.data as Map<String, dynamic>;
    final user = AuthUser(
      id:           data['user_id'] as int,
      email:        data['email'] as String,
      name:         data['name'] as String,
      accessToken:  data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    await _saveUser(user);
    return user;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/logout');
    } catch (_) {}
    await _clearUser();
  }

  Future<bool> _tryRefresh() async {
    try {
      final refresh = await _storage.read(key: _kRefreshToken);
      if (refresh == null) return false;
      final resp = await _dio.post('/api/refresh',
          options: Options(headers: {'Authorization': 'Bearer $refresh'}));
      final newToken = resp.data['access_token'] as String;
      await _storage.write(key: _kAccessToken, value: newToken);
      return true;
    } catch (_) {
      await _clearUser();
      return false;
    }
  }

  // ── SAVED SESSION CHECK ───────────────────
  /// Returns the saved user if token exists, null otherwise.
  /// Call on app start for auto-login.
  Future<AuthUser?> getSavedUser() async {
    final token = await _storage.read(key: _kAccessToken);
    if (token == null) return null;
    final id    = await _storage.read(key: _kUserId);
    final email = await _storage.read(key: _kUserEmail);
    final name  = await _storage.read(key: _kUserName);
    if (id == null || email == null || name == null) return null;
    return AuthUser(
      id: int.tryParse(id) ?? 0,
      email: email,
      name: name,
      accessToken: token,
      refreshToken: await _storage.read(key: _kRefreshToken) ?? '',
    );
  }

  Future<void> _saveUser(AuthUser user) async {
    await _storage.write(key: _kAccessToken,  value: user.accessToken);
    await _storage.write(key: _kRefreshToken, value: user.refreshToken);
    await _storage.write(key: _kUserId,       value: '${user.id}');
    await _storage.write(key: _kUserEmail,    value: user.email);
    await _storage.write(key: _kUserName,     value: user.name);
  }

  Future<void> _clearUser() async {
    await _storage.deleteAll();
  }

  // ── GENERIC HELPERS ───────────────────────
  Future<Map<String, dynamic>> get(String path) async {
    final r = await _dio.get(path);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final r = await _dio.post(path, data: body);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final r = await _dio.patch(path, data: body);
    return r.data as Map<String, dynamic>;
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}

// ── PROVIDER ─────────────────────────────────
final apiServiceProvider = Provider<ApiService>((_) => ApiService.instance);