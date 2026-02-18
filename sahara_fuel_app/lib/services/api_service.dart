import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// خدمة API للاتصال بالسيرفر
/// تدير: التوكنات، الطلبات، التحديث التلقائي للجلسة
class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  // ===== الإعدادات =====
  // في الإنتاج غيّر هذا للسيرفر الحقيقي
  String _baseUrl = 'http://localhost:3000/api';
  String? _accessToken;
  String? _refreshToken;

  // Getters
  String get baseUrl => _baseUrl;
  bool get hasToken => _accessToken != null;
  String? get accessToken => _accessToken;

  /// تعيين رابط السيرفر
  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    debugPrint('🌐 API Base URL: $_baseUrl');
  }

  /// تعيين التوكنات بعد تسجيل الدخول
  void setTokens({required String access, required String refresh}) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  /// مسح التوكنات عند تسجيل الخروج
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  // ===================================================================
  // طلبات HTTP العامة
  // ===================================================================

  /// طلب GET
  Future<ApiResponse> get(String path, {Map<String, String>? queryParams}) async {
    final uri = _buildUri(path, queryParams);
    return _sendRequest(() => http.get(uri, headers: _headers()));
  }

  /// طلب POST
  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    return _sendRequest(() => http.post(uri, headers: _headers(), body: body != null ? jsonEncode(body) : null));
  }

  /// طلب PUT
  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    return _sendRequest(() => http.put(uri, headers: _headers(), body: body != null ? jsonEncode(body) : null));
  }

  /// طلب PATCH
  Future<ApiResponse> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    return _sendRequest(() => http.patch(uri, headers: _headers(), body: body != null ? jsonEncode(body) : null));
  }

  /// طلب DELETE
  Future<ApiResponse> delete(String path) async {
    final uri = _buildUri(path);
    return _sendRequest(() => http.delete(uri, headers: _headers()));
  }

  // ===================================================================
  // Auth API
  // ===================================================================

  /// تسجيل الدخول
  Future<ApiResponse> login(String email, String password) async {
    final res = await post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    if (res.success && res.data != null) {
      _accessToken = res.data!['accessToken'];
      _refreshToken = res.data!['refreshToken'];
    }
    return res;
  }

  /// تجديد التوكن
  Future<bool> refreshTokens() async {
    if (_refreshToken == null) return false;
    try {
      final uri = _buildUri('/auth/refresh');
      final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _accessToken = data['data']['accessToken'];
          _refreshToken = data['data']['refreshToken'];
          return true;
        }
      }
    } catch (e) {
      debugPrint('❌ فشل تجديد التوكن: $e');
    }
    return false;
  }

  /// تسجيل الخروج
  Future<ApiResponse> logout() async {
    final res = await post('/auth/logout');
    clearTokens();
    return res;
  }

  /// بيانات المستخدم الحالي
  Future<ApiResponse> getMe() => get('/auth/me');

  /// تغيير كلمة المرور
  Future<ApiResponse> changePassword(String currentPassword, String newPassword) =>
    post('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });

  // ===================================================================
  // Users API
  // ===================================================================

  Future<ApiResponse> getUsers({int page = 1, int limit = 50}) =>
    get('/users', queryParams: {'page': '$page', 'limit': '$limit'});

  Future<ApiResponse> getUser(String id) => get('/users/$id');

  Future<ApiResponse> createUser({
    required String name, required String email, required String password,
    required String role, String phone = '',
  }) => post('/users', body: {
    'name': name, 'email': email, 'password': password, 'role': role, 'phone': phone,
  });

  Future<ApiResponse> updateUser(String id, Map<String, dynamic> data) =>
    put('/users/$id', body: data);

  Future<ApiResponse> deleteUser(String id) => delete('/users/$id');

  // ===================================================================
  // Fuel Transactions API
  // ===================================================================

  Future<ApiResponse> getFuelTransactions({int page = 1, int limit = 50, String? type, String? fuelType}) {
    final params = <String, String>{'page': '$page', 'limit': '$limit'};
    if (type != null) params['type'] = type;
    if (fuelType != null) params['fuel_type'] = fuelType;
    return get('/fuel', queryParams: params);
  }

  Future<ApiResponse> getFuelTransaction(String id) => get('/fuel/$id');

  Future<ApiResponse> createFuelTransaction({
    required String type, required String fuelType, required double quantity,
    double? unitPrice, String? supplier, String? tankId, String? destinationTankId,
    String? driverName, String? truckNumber, double? density, double? colorRating, String? notes,
  }) {
    final body = <String, dynamic>{
      'type': type, 'fuel_type': fuelType, 'quantity': quantity,
    };
    if (unitPrice != null) body['unit_price'] = unitPrice;
    if (supplier != null) body['supplier'] = supplier;
    if (tankId != null) body['tank_id'] = tankId;
    if (destinationTankId != null) body['destination_tank_id'] = destinationTankId;
    if (driverName != null) body['driver_name'] = driverName;
    if (truckNumber != null) body['truck_number'] = truckNumber;
    if (density != null) body['density'] = density;
    if (colorRating != null) body['color_rating'] = colorRating;
    if (notes != null) body['notes'] = notes;
    return post('/fuel', body: body);
  }

  Future<ApiResponse> approveFuelTransaction(String id) => patch('/fuel/$id/approve');

  Future<ApiResponse> deleteFuelTransaction(String id) => delete('/fuel/$id');

  Future<ApiResponse> getFuelStats() => get('/fuel/stats/summary');

  // ===================================================================
  // Tanks API
  // ===================================================================

  Future<ApiResponse> getTanks() => get('/tanks');

  Future<ApiResponse> getTank(String id) => get('/tanks/$id');

  Future<ApiResponse> createTank({
    required String name, required String fuelType, required double capacity,
    double? currentLevel, double? minLevel, String? location, String? branchId,
  }) {
    final body = <String, dynamic>{
      'name': name, 'fuel_type': fuelType, 'capacity': capacity,
    };
    if (currentLevel != null) body['current_level'] = currentLevel;
    if (minLevel != null) body['min_level'] = minLevel;
    if (location != null) body['location'] = location;
    if (branchId != null) body['branch_id'] = branchId;
    return post('/tanks', body: body);
  }

  Future<ApiResponse> updateTank(String id, Map<String, dynamic> data) =>
    put('/tanks/$id', body: data);

  Future<ApiResponse> deleteTank(String id) => delete('/tanks/$id');

  // ===================================================================
  // Branches API
  // ===================================================================

  Future<ApiResponse> getBranches() => get('/branches');

  Future<ApiResponse> createBranch({required String name, String? code, String? address, String? phone}) =>
    post('/branches', body: {'name': name, if (code != null) 'code': code, if (address != null) 'address': address, if (phone != null) 'phone': phone});

  Future<ApiResponse> updateBranch(String id, Map<String, dynamic> data) =>
    put('/branches/$id', body: data);

  Future<ApiResponse> deleteBranch(String id) => delete('/branches/$id');

  // ===================================================================
  // Roles API
  // ===================================================================

  Future<ApiResponse> getRoles() => get('/roles');
  Future<ApiResponse> getPermissions() => get('/roles/permissions');

  // ===================================================================
  // Audit API
  // ===================================================================

  Future<ApiResponse> getAuditLogs({int page = 1, int limit = 50}) =>
    get('/audit', queryParams: {'page': '$page', 'limit': '$limit'});

  Future<ApiResponse> getAuditStats() => get('/audit/stats');

  // ===================================================================
  // Subscriptions API
  // ===================================================================

  Future<ApiResponse> getCurrentSubscription() => get('/subscriptions/current');
  Future<ApiResponse> getSubscriptionHistory() => get('/subscriptions/history');
  Future<ApiResponse> getSubscriptionPlans() => get('/subscriptions/plans');

  // ===================================================================
  // Import / Bulk API
  // ===================================================================

  /// استيراد معاملات وقود (جماعي)
  Future<ApiResponse> importFuelRecords(List<Map<String, dynamic>> records) =>
    post('/import/fuel', body: {'records': records});

  /// استيراد خزانات (جماعي)
  Future<ApiResponse> importTanks(List<Map<String, dynamic>> records) =>
    post('/import/tanks', body: {'records': records});

  /// إنشاء بيانات تجريبية
  Future<ApiResponse> seedDemoData() => post('/import/seed-demo');

  // ===================================================================
  // Health Check
  // ===================================================================

  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ===================================================================
  // الأدوات الداخلية
  // ===================================================================

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final fullUrl = '$_baseUrl$path';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Future<ApiResponse> _sendRequest(Future<http.Response> Function() request) async {
    try {
      var response = await request().timeout(const Duration(seconds: 15));

      // إذا انتهت صلاحية التوكن، حاول تجديده
      if (response.statusCode == 401 && _refreshToken != null) {
        final refreshed = await refreshTokens();
        if (refreshed) {
          response = await request().timeout(const Duration(seconds: 15));
        }
      }

      final body = jsonDecode(response.body);
      return ApiResponse(
        success: body['success'] ?? false,
        data: body['data'],
        error: body['error'],
        code: body['code'],
        statusCode: response.statusCode,
      );
    } on http.ClientException catch (e) {
      return ApiResponse(success: false, error: 'خطأ في الاتصال: ${e.message}', code: 'NETWORK_ERROR');
    } on FormatException {
      return ApiResponse(success: false, error: 'خطأ في تنسيق البيانات', code: 'FORMAT_ERROR');
    } catch (e) {
      return ApiResponse(success: false, error: 'خطأ غير متوقع: $e', code: 'UNKNOWN_ERROR');
    }
  }
}

/// نموذج استجابة API
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final String? code;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.error, this.code, this.statusCode});

  @override
  String toString() => 'ApiResponse(success: $success, code: $code, error: $error)';
}

