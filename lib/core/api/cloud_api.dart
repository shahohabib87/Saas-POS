import 'package:dio/dio.dart';

/// Result of a successful cloud login.
class CloudSession {
  final String token;
  final String userName;
  final String tenantName;
  final String tenantSlug;

  /// The raw tenant object from the server — carries the subscription status
  /// and expiry dates the terminal needs to enforce entitlement offline.
  final Map<String, dynamic> tenantJson;

  const CloudSession({
    required this.token,
    required this.userName,
    required this.tenantName,
    required this.tenantSlug,
    this.tenantJson = const {},
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
      tenantJson: tenant,
    );
    _dio.options.headers['Authorization'] = 'Bearer ${session.token}';
    return session;
  }

  /// Re-fetch the current user's tenant (subscription state included). Used on
  /// launch to refresh entitlement without a full catalog pull.
  Future<Map<String, dynamic>> fetchMe() async {
    final res = await _dio.get<Map<String, dynamic>>('/me');
    final data = res.data ?? const {};
    return (data['tenant'] as Map<String, dynamic>?) ?? const {};
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
      'last_synced_at': ?lastSyncedAt,
    });
    return res.data ?? const {};
  }

  /// True when the server rejected our token (expired / revoked).
  static bool isUnauthorized(Object e) =>
      e is DioException && e.response?.statusCode == 401;

  /// True when the tenant's subscription has lapsed — the `subscribed` gate
  /// answers 402 Payment Required.
  static bool isPaymentRequired(Object e) =>
      e is DioException && e.response?.statusCode == 402;

  /// The subscription fields the 402 body carries (status + expiry dates), so
  /// the device can update its cached entitlement the moment it's told it has
  /// lapsed — without waiting for the next login.
  static Map<String, dynamic>? tenantFromError(Object e) {
    if (e is! DioException) return null;
    final data = e.response?.data;
    if (data is! Map) return null;
    if (data['status'] == null &&
        data['trial_ends_at'] == null &&
        data['subscription_ends_at'] == null) {
      return null;
    }
    return {
      'status': data['status'],
      'trial_ends_at': data['trial_ends_at'],
      'subscription_ends_at': data['subscription_ends_at'],
    };
  }

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
