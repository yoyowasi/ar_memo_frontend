import 'dart:convert';

import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/services/api_service.dart';

class MemoryRepository {
  final ApiService _apiService = ApiService();

  Future<List<TripRecord>> getMyMemories() async {
    // 백엔드의 list API 엔드포인트는 '/api/memories' 입니다.
    final response = await _apiService.get('/memories');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((item) => TripRecord.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load memories');
    }
  }
}