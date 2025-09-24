import 'dart:convert';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/services/api_service.dart';

class TripRecordRepository {
  final ApiService _apiService = ApiService();

  List<dynamic> _extractItems(dynamic data) {
    if (data is List<dynamic>) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final payload = data['items'] ?? data['data'] ?? data['results'];
      if (payload is List<dynamic>) {
        return payload;
      }
    }
    return const [];
  }

  Future<List<TripRecord>> getTripRecords({
    int page = 1,
    int limit = 20,
    String? query,
    String? groupId,
    String? month,
  }) async {
    final response = await _apiService.get(
      '/trip-records',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (query != null && query.isNotEmpty) 'q': query,
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
        if (month != null && month.isNotEmpty) 'month': month,
      },
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final items = _extractItems(decoded);
      return items
          .whereType<Map<String, dynamic>>()
          .map(TripRecord.fromJson)
          .toList();
    }
    throw Exception('Failed to load trip records: ${response.body}');
  }

  Future<TripRecord> getTripRecord(String id) async {
    final response = await _apiService.get('/trip-records/$id');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final payload = decoded['record'] is Map<String, dynamic> ? decoded['record'] as Map<String, dynamic> : decoded;
        return TripRecord.fromJson(payload);
      }
    }
    throw Exception('Failed to fetch trip record: ${response.body}');
  }

  Future<TripRecord> createTripRecord({
    required String title,
    required DateTime date,
    String? content,
    String? groupId,
    List<String>? photoUrls,
  }) async {
    final response = await _apiService.post(
      '/trip-records',
      data: {
        'title': title,
        'date': date.toIso8601String(),
        if (content != null) 'content': content,
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
        'photoUrls': photoUrls ?? <String>[],
      },
    );
    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final payload = decoded['record'] is Map<String, dynamic>
            ? decoded['record'] as Map<String, dynamic>
            : decoded;
        return TripRecord.fromJson(payload);
      }
    }
    throw Exception('Failed to create trip record: ${response.body}');
  }

  Future<TripRecord> updateTripRecord({
    required String id,
    String? title,
    DateTime? date,
    String? content,
    String? groupId,
    List<String>? photoUrls,
  }) async {
    final response = await _apiService.put(
      '/trip-records/$id',
      data: {
        if (title != null) 'title': title,
        if (date != null) 'date': date.toIso8601String(),
        if (content != null) 'content': content,
        if (groupId != null) 'groupId': groupId,
        if (photoUrls != null) 'photoUrls': photoUrls,
      },
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final payload = decoded['record'] is Map<String, dynamic> ? decoded['record'] as Map<String, dynamic> : decoded;
        return TripRecord.fromJson(payload);
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