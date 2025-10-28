// lib/repositories/trip_record_repository.dart
import 'dart:convert';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/services/api_service.dart';

class TripRecordRepository {
  final ApiService _apiService;

  TripRecordRepository(this._apiService);

  Future<List<TripRecord>> getTripRecords({int page = 1, int limit = 20}) async {
    final res = await _apiService.get('/trip-records', queryParameters: {'page': page, 'limit': limit});
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch trip records: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    return items.map(TripRecord.fromJson).toList();
  }

  Future<TripRecord> getTripRecord(String id) async {
    final res = await _apiService.get('/trip-records/$id');
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
    final res = await _apiService.post('/trip-records', data: body);
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
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (date != null) 'date': date.toIso8601String(),
      if (content != null) 'content': content,
      if (groupId != null) 'groupId': groupId,
      if (photoUrls != null) 'photoUrls': photoUrls,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    final res = await _apiService.put('/trip-records/$id', data: body);
    if (res.statusCode != 200) {
      throw Exception('Failed to update trip record: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deleteTripRecord(String id) async {
    final res = await _apiService.delete('/trip-records/$id');
    if (res.statusCode != 200) {
      throw Exception('Failed to delete trip record: ${res.statusCode} ${res.body}');
    }
  }
}
