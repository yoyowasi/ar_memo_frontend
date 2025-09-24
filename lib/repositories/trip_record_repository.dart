import 'dart:convert';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/services/api_service.dart';

class TripRecordRepository {
  final ApiService _apiService = ApiService();

  Future<List<TripRecord>> getTripRecords() async {
    final response = await _apiService.get('/trip-records');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((item) => TripRecord.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load trip records: ${response.body}');
    }
  }

  Future<TripRecord> createTripRecord({
    required String title,
    required DateTime date,
    String? content,
    String? groupId,
    List<String>? photoUrls,
  }) async {
    final body = {
      'title': title,
      'date': date.toIso8601String(),
      'content': content ?? '',
      'groupId': groupId,
      'photoUrls': photoUrls ?? [],
    };
    body.removeWhere((key, value) => value == null);

    final response = await _apiService.post('/trip-records', jsonEncode(body));
    if (response.statusCode == 201) {
      return TripRecord.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create trip record: ${response.body}');
    }
  }
}