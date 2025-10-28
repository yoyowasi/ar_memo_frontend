import 'dart:convert';

import 'package:ar_memo_frontend/services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  // 로그인 상태 (토큰 유무로 판단)
  bool get isLoggedIn => _apiService.hasToken();

  Future<void> init() async {
    await _apiService.loadToken();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post(
      '/api/auth/login',
      data: <String, String>{
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _apiService.setToken(data['token']);
      return data;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, [String? name]) async {
    final body = <String, String>{
      'email': email,
      'password': password,
    };
    if (name != null && name.isNotEmpty) {
      body['name'] = name;
    }

    final response = await _apiService.post(
      '/api/auth/register',
      data: body,
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _apiService.setToken(data['token']);
      return data;
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchCurrentUser() async {
    final response = await _apiService.get('/api/auth/me');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw Exception('Unexpected user payload: ${response.body}');
    }
    if (response.statusCode == 401) {
      await logout();
      throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
    }
    throw Exception('Failed to fetch profile: ${response.body}');
  }

  Future<void> logout() async {
    await _apiService.clearToken();
  }

  Future<bool> verifyToken() async {
    if (!isLoggedIn) return false;
    try {
      final response = await _apiService.get('/api/auth/me');
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        await logout();
        return false;
      }
      return false; // Other errors
    } catch (e) {
      // Network error or other exceptions
      await logout(); // Assume token is invalid if API call fails
      return false;
    }
  }
}