// lib/repositories/trip_record_repository.dart
import 'dart:convert';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/services/api_service.dart';

class TripRecordRepository {
  final ApiService _apiService;

  TripRecordRepository(this._apiService);

  List<Map<String, dynamic>> _extractList(dynamic source) {
    if (source is List) {
      return source.whereType<Map<String, dynamic>>().toList();
    }
    if (source is Map<String, dynamic>) {
      final candidates = [
        source['items'],
        source['data'],
        source['results'],
        source['records'],
        source['tripRecords'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate.whereType<Map<String, dynamic>>().toList();
        }
      }
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractObject(dynamic source) {
    if (source is Map<String, dynamic>) {
      final candidates = [
        source['record'],
        source['tripRecord'],
        source['data'],
        source['item'],
      ];
      for (final candidate in candidates) {
        if (candidate is Map<String, dynamic>) {
          return candidate;
        }
      }
      return source;
    }
    throw Exception('Unexpected trip record payload: $source');
  }

  Future<List<TripRecord>> getTripRecords({int page = 1, int limit = 20}) async {
    final res = await _apiService.get('/api/trip-records', queryParameters: {'page': page, 'limit': limit});
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch trip records: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    final items = _extractList(decoded);
    return items.map(TripRecord.fromJson).toList();
  }

  Future<TripRecord> getTripRecord(String id) async {
    final res = await _apiService.get('/api/trip-records/$id');
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch trip record: ${res.statusCode} ${res.body}');
    }
    final decoded = jsonDecode(res.body);
    final payload = _extractObject(decoded);
    return TripRecord.fromJson(payload);
  }

  Future<void> createTripRecord({
    required String title,
    required DateTime date,
    String? content,
    String? groupId,
    List<String>? photoUrls,
    double? latitude,
    double? longitude,
  }) async {
    final body = {
      'title': title,
      'date': date.toIso8601String(),
      if (content != null) 'content': content,
      if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
      if (photoUrls != null) 'photoUrls': photoUrls,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    final res = await _apiService.post('/api/trip-records', data: body);
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to create trip record: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> updateTripRecord({
    required String id,
    String? title,
    DateTime? date,
    String? content,
    String? groupId,
    bool isGroupIdUpdated = false,
    List<String>? photoUrls,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (date != null) 'date': date.toIso8601String(),
      if (content != null) 'content': content,
      if (isGroupIdUpdated) 'groupId': groupId,
      if (photoUrls != null) 'photoUrls': photoUrls,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    final res = await _apiService.put('/api/trip-records/$id', data: body);
    if (res.statusCode != 200) {
      throw Exception('Failed to update trip record: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deleteTripRecord(String id) async {
    final res = await _apiService.delete('/api/trip-records/$id');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete trip record: ${res.statusCode} ${res.body}');
    }
  }
}