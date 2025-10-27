import 'dart:convert';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/services/api_service.dart';

class TripRecordRepository {
  final ApiService _apiService = ApiService();

  List<dynamic> _extractItems(dynamic data) {
    // ... (이전과 동일) ...
    if (data is List<dynamic>) { return data; }
    if (data is Map<String, dynamic>) { final payload = data['items'] ?? data['data'] ?? data['results']; if (payload is List<dynamic>) { return payload; } }
    return const [];
  }

  Future<List<TripRecord>> getTripRecords({
    int page = 1, int limit = 20,
    String? query, String? groupId, String? month,
  }) async {
    final response = await _apiService.get('/trip-records', queryParameters: {
      'page': page, 'limit': limit,
      if (query != null && query.isNotEmpty) 'q': query,
      if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
      if (month != null && month.isNotEmpty) 'month': month,
    },);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final items = _extractItems(decoded);
      return items.whereType<Map<String, dynamic>>().map(TripRecord.fromJson).toList();
    }
    throw Exception('Failed to load trip records: ${response.body}');
  }

  Future<TripRecord> getTripRecord(String id) async {
    final response = await _apiService.get('/trip-records/$id');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        // 백엔드 응답 형식에 따라 payload 추출 (detail 응답이 data나 record 키를 가질 수 있음)
        final payload = decoded['record'] ?? decoded['data'] ?? decoded;
        if (payload is Map<String, dynamic>) {
          return TripRecord.fromJson(payload);
        }
      }
    }
    throw Exception('Failed to fetch trip record: ${response.body}');
  }


  Future<TripRecord> createTripRecord({
    required String title, required DateTime date,
    String? content, String? groupId, List<String>? photoUrls,
    // --- 위치 파라미터 ---
    double? latitude, double? longitude,
    // --------------------
  }) async {
    final Map<String, dynamic> data = {
      'title': title,
      'date': date.toUtc().toIso8601String(), // UTC ISO8601 형식
      'photoUrls': photoUrls ?? <String>[],
      if (content != null) 'content': content,
      if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
      // 위치 정보 추가
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    final response = await _apiService.post('/trip-records', data: data);
    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final payload = decoded['record'] ?? decoded['data'] ?? decoded;
        if (payload is Map<String, dynamic>) {
          return TripRecord.fromJson(payload);
        }
      }
    }
    throw Exception('Failed to create trip record: ${response.body}');
  }

  Future<TripRecord> updateTripRecord({
    required String id,
    String? title, DateTime? date, String? content,
    String? groupId, List<String>? photoUrls,
    // --- 위치 파라미터 ---
    double? latitude, double? longitude,
    // --------------------
  }) async {
    final Map<String, dynamic> data = {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      // groupId를 null로 설정하여 그룹 해제 가능하도록 수정
      'groupId': groupId, // null이 전달될 수 있음
      if (photoUrls != null) 'photoUrls': photoUrls,
      // 위치 정보 추가
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    if (date != null) {
      data['date'] = date.toUtc().toIso8601String(); // UTC ISO8601 형식
    }

    final response = await _apiService.put('/trip-records/$id', data: data);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final payload = decoded['record'] ?? decoded['data'] ?? decoded;
        if (payload is Map<String, dynamic>) {
          return TripRecord.fromJson(payload);
        }
      }
    }
    throw Exception('Failed to update trip record: ${response.body}');
  }

  Future<void> deleteTripRecord(String id) async {
    final response = await _apiService.delete('/trip-records/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete trip record: ${response.body}');
    }
  }
}