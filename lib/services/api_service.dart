import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final http.Client _client;
  final String _baseUrl;
  final SharedPreferences _sharedPreferences;
  String? _token;

  ApiService({
    required http.Client client,
    required String baseUrl,
    required SharedPreferences sharedPreferences,
  })  : _client = client,
        _baseUrl = baseUrl,
        _sharedPreferences = sharedPreferences;

  Future<void> loadToken() async {
    _token = _sharedPreferences.getString('jwt_token');
  }

  Future<void> setToken(String token) async {
    await _sharedPreferences.setString('jwt_token', token);
    _token = token;
  }

  Future<void> clearToken() async {
    await _sharedPreferences.remove('jwt_token');
    _token = null;
  }

  bool hasToken() => _token != null && _token!.isNotEmpty;

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final baseUri = Uri.parse(_baseUrl);
    final basePath = baseUri.path;

    String combinedPath;
    if (normalizedEndpoint == '/') {
      combinedPath = basePath.isEmpty ? '/' : basePath;
    } else if (basePath.isEmpty || basePath == '/') {
      combinedPath = normalizedEndpoint;
    } else if (normalizedEndpoint.startsWith(basePath)) {
      combinedPath = normalizedEndpoint;
    } else {
      final trimmedBase =
          basePath.endsWith('/') ? basePath.substring(0, basePath.length - 1) : basePath;
      combinedPath = '$trimmedBase$normalizedEndpoint';
    }

    final normalizedPath = combinedPath.replaceAll(RegExp(r'//+'), '/');
    final uri = baseUri.replace(path: normalizedPath);

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
    if (_token != null && _token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    return request;
  }

  Future<http.StreamedResponse> sendMultipart(http.MultipartRequest request) {
    if (_token != null && _token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    return request.send();
  }
}