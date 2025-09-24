import 'dart:convert';
import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/services/api_service.dart';

class MemoryRepository {
  final ApiService _apiService = ApiService();

  Future<List<Memory>> getMyMemories() async {
    final response = await _apiService.get('/memories');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((item) => Memory.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load memories');
    }
  }
}