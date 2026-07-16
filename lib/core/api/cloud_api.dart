import 'package:dio/dio.dart';

/// Result of a successful cloud login.
class CloudSession {
  final String token;
  final String userName;
  final String tenantName;
  final String tenantSlug;

  const CloudSession({
    required this.token,
    required this.userName,
    required this.tenantName,
    required this.tenantSlug,
  });
}

/// Thin HTTP client for the EasyCasher cloud (Laravel Sanctum API).
///
/// Mirrors the web POS's client: token in the Authorization header, JSON
/// everywhere, all endpoints tenant-scoped by the server.
class CloudApi {
  CloudApi({required String baseUrl, String? token})
      : _dio = Dio(BaseOptions(
          // Normalise: the API root always ends in /api
          baseUrl: _normalise(baseUrl),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        )) {
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  final Dio _dio;

  static String _normalise(String url) {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    if (!u.endsWith('/api')) u = '$u/api';
    return u;
  }

  /// Owner/manager email login → Sanctum token + tenant info.
  Future<CloudSession> login(String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/login',
      data: {'email': email, 'password': password},
    );
    final data = res.data!;
    final user = data['user'] as Map<String, dynamic>? ?? {};
    final tenant = data['tenant'] as Map<String, dynamic>? ?? {};
    final session = CloudSession(
      token: data['token'] as String,
      userName: (user['name'] ?? '') as String,
      tenantName: (tenant['name'] ?? '') as String,
      tenantSlug: (tenant['slug'] ?? '') as String,
    );
    _dio.options.headers['Authorization'] = 'Bearer ${session.token}';
    return session;
  }

  Future<List<dynamic>> _list(String path) async {
    final res = await _dio.get<List<dynamic>>(path);
    return res.data ?? const [];
  }

  Future<List<dynamic>> fetchCategories() => _list('/categories');
  Future<List<dynamic>> fetchMenuItems() => _list('/menu-items');
  Future<List<dynamic>> fetchTables() => _list('/tables');
  Future<List<dynamic>> fetchStaff() => _list('/staff?with_pins=1');
  Future<List<dynamic>> fetchDrivers() => _list('/drivers');
  Future<List<dynamic>> fetchDeliveryAreas() => _list('/delivery-areas');

  /// The offline-first sync endpoint: push queued orders, get the delta back.
  Future<Map<String, dynamic>> sync({
    required List<dynamic> orders,
    String? lastSyncedAt,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>('/sync', data: {
      'orders': orders,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
    });
    return res.data ?? const {};
  }

  /// True when the server rejected our token (expired / revoked).
  static bool isUnauthorized(Object e) =>
      e is DioException && e.response?.statusCode == 401;

  /// Human-readable message out of a Dio error (validation msg if present).
  static String errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Could not reach the server — check the address and internet.';
      }
      return 'Request failed (${e.response?.statusCode ?? 'network'}).';
    }
    return 'Unexpected error: $e';
  }
}
