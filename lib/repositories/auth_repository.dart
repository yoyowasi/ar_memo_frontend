import 'dart:convert';
import 'package:ar_memo_frontend/services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  // 로그인 상태 (토큰 유무로 판단)
  bool get isLoggedIn => _apiService.hasToken();

  Future<void> init() async {
    await _apiService.loadToken();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post(
      '/auth/login',
      jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
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
      '/auth/register',
      jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _apiService.setToken(data['token']);
      return data;
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }


  Future<void> logout() async {
    await _apiService.clearToken();
  }
}