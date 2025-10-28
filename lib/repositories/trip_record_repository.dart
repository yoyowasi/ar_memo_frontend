// lib/repositories/trip_record_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TripRecordRepository {
  TripRecordRepository();

  String get _baseUrl {
    final base = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:4000/api';
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 로그인 시 받은 JWT를 호출부에서 넘겨 쓰도록 필요하면 인자 추가해서 사용하세요.
  Future<List<TripRecord>> getTripRecords({int page = 1, int limit = 20, String? token}) async {
    final uri = Uri.parse('$_baseUrl/trip-records?page=$page&limit=$limit');
    final res = await http.get(uri, headers: _headers(token: token));
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch trip records: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    return items.map(TripRecord.fromJson).toList();
  }

  Future<TripRecord> getTripRecord(String id, {String? token}) async {
    final uri = Uri.parse('$_baseUrl/trip-records/$id');
    final res = await http.get(uri, headers: _headers(token: token));
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch trip record: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return TripRecord.fromJson(data);
  }

  Future<void> createTripRecord({
    required String title,
    required DateTime date,
    String? content,
    String? groupId,
    List<String>? photoUrls,
    double? latitude,
    double? longitude,
    String? token,
  }) async {
    final uri = Uri.parse('$_baseUrl/trip-records');
    final body = {
      'title': title,
      'date': date.toIso8601String(),
      if (content != null) 'content': content,
      if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
      if (photoUrls != null) 'photoUrls': photoUrls,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    final res = await http.post(uri, headers: _headers(token: token), body: jsonEncode(body));
    if (res.statusCode != 201) {
      throw Exception('Failed to create trip record: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> updateTripRecord({
    required String id,
    String? title,
    DateTime? date,
    String? content,
    String? groupId,
    List<String>? photoUrls,
    double? latitude,
    double? longitude,
    String? token,
  }) async {
    final uri = Uri.parse('$_baseUrl/trip-records/$id');
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (date != null) 'date': date.toIso8601String(),
      if (content != null) 'content': content,
      if (groupId != null) 'groupId': groupId,
      if (photoUrls != null) 'photoUrls': photoUrls,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    final res = await http.put(uri, headers: _headers(token: token), body: jsonEncode(body));
    if (res.statusCode != 200) {
      throw Exception('Failed to update trip record: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deleteTripRecord(String id, {String? token}) async {
    final uri = Uri.parse('$_baseUrl/trip-records/$id');
    final res = await http.delete(uri, headers: _headers(token: token));
    if (res.statusCode != 200) {
      throw Exception('Failed to delete trip record: ${res.statusCode} ${res.body}');
    }
  }
}
