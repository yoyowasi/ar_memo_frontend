import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._internal()
      : _client = http.Client(),
        _baseUrl = _normalizeBaseUrl(dotenv.env['API_BASE_URL']);

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final http.Client _client;
  final String _baseUrl;
  String? _token;

  static String _normalizeBaseUrl(String? raw) {
    if (raw == null || raw.isEmpty) {
      throw StateError('API_BASE_URL이 .env 파일에 정의되어 있지 않습니다.');
    }
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  Future<void> dispose() async {
    _client.close();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    _token = token;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    _token = null;
  }

  bool hasToken() => _token != null && _token!.isNotEmpty;

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$_baseUrl$normalizedEndpoint');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final filtered = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value != null) {
        filtered[key] = value.toString();
      }
    });
    return uri.replace(queryParameters: filtered);
  }

  Map<String, String> _buildHeaders({bool includeJsonContentType = true}) {
    final headers = <String, String>{};
    if (includeJsonContentType) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Object? _encodeBody(Object? data) {
    if (data == null) {
      return null;
    }
    if (data is String || data is List<int>) {
      return data;
    }
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    return _client.get(uri, headers: _buildHeaders(includeJsonContentType: false));
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Object? data,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    return _client.post(uri, headers: _buildHeaders(), body: _encodeBody(data));
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Object? data,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    return _client.put(uri, headers: _buildHeaders(), body: _encodeBody(data));
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Object? data,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    return _client.patch(uri, headers: _buildHeaders(), body: _encodeBody(data));
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    return _client.delete(uri, headers: _buildHeaders(includeJsonContentType: false));
  }

  http.MultipartRequest multipartRequest(String method, String endpoint) {
    final request = http.MultipartRequest(method, _buildUri(endpoint));
    return request;
  }

  Future<http.StreamedResponse> sendMultipart(http.MultipartRequest request) {
    if (_token != null && _token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    return request.send();
  }
}