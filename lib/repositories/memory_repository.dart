import 'dart:convert';

import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/models/memory_summary.dart';
import 'package:ar_memo_frontend/services/api_service.dart';

class MemoryRepository {
  final ApiService _apiService = ApiService();

  Future<List<Memory>> getMyMemories({
    int page = 1,
    int limit = 10,
    String? query,
    String? tag,
    String? groupId,
    String? month,
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (query != null && query.isNotEmpty) {
      queryParameters['q'] = query;
    }
    if (tag != null && tag.isNotEmpty) {
      queryParameters['tag'] = tag;
    }
    if (groupId != null && groupId.isNotEmpty) {
      queryParameters['groupId'] = groupId;
    }
    if (month != null && month.isNotEmpty) {
      queryParameters['month'] = month;
    }

    final queryString = Uri(queryParameters: queryParameters).query;
    final endpoint = queryString.isNotEmpty ? '/memories?$queryString' : '/memories';

    final response = await _apiService.get(endpoint);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items;
      if (data is Map<String, dynamic>) {
        final dynamic payload = data['items'] ?? data['data'] ?? data['results'];
        if (payload is List<dynamic>) {
          items = payload;
        } else {
          items = [];
        }
      } else if (data is List<dynamic>) {
        items = data;
      } else {
        items = [];
      }
      return items
          .whereType<Map<String, dynamic>>()
          .map(Memory.fromJson)
          .toList();
    } else {
      throw Exception('Failed to load memories');
    }
  }

  Future<MemorySummary> getMemorySummary({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    final queryParameters = <String, String>{};
    if (latitude != null && longitude != null) {
      queryParameters['lat'] = latitude.toString();
      queryParameters['lng'] = longitude.toString();
    }
    if (radius != null) {
      queryParameters['radius'] = radius.toString();
    }

    final queryString = Uri(queryParameters: queryParameters).query;
    final endpoint =
        queryString.isNotEmpty ? '/memories/stats/summary?$queryString' : '/memories/stats/summary';

    final response = await _apiService.get(endpoint);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final summaryJson = decoded['summary'] is Map<String, dynamic>
            ? decoded['summary'] as Map<String, dynamic>
            : decoded;
        return MemorySummary.fromJson(summaryJson);
      }
      throw Exception('Invalid summary response');
    } else {
      throw Exception('Failed to load memory summary');
    }
  }
}