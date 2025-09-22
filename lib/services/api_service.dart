import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String _baseUrl = dotenv.env['API_BASE_URL']!;
  String? _token;

  // 싱글톤 인스턴스
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  // 토큰 로드 (앱 시작 시 호출)
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
  }

  // 토큰 저장 (로그인/회원가입 성공 시 호출)
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    _token = token;
  }

  // 토큰 삭제 (로그아웃 시 호출)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    _token = null;
  }

  // 토큰 존재 여부 확인
  bool hasToken() {
    return _token != null;
  }

  // 공통 헤더 생성
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // GET 요청
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.get(url, headers: _getHeaders());
  }

  // POST 요청
  Future<http.Response> post(String endpoint, dynamic data) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.post(url, headers: _getHeaders(), body: data);
  }

  // PUT 요청
  Future<http.Response> put(String endpoint, dynamic data) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.put(url, headers: _getHeaders(), body: data);
  }

  // DELETE 요청
  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.delete(url, headers: _getHeaders());
  }
}