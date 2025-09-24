import 'dart:convert';

import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/models/memory_summary.dart';
import 'package:ar_memo_frontend/services/api_service.dart';

class MemoryRepository {
  final ApiService _apiService = ApiService();


  List<dynamic> _unwrapList(dynamic data) {
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


  Future<List<Memory>> getMyMemories({
    int page = 1,
    int limit = 10,
    String? query,
    String? tag,
    String? groupId,
    String? month,
  }) async {

    final response = await _apiService.get(
      '/memories',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (query != null && query.isNotEmpty) 'q': query,
        if (tag != null && tag.isNotEmpty) 'tag': tag,
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
        if (month != null && month.isNotEmpty) 'month': month,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = _unwrapList(data);
      return items
          .whereType<Map<String, dynamic>>()
          .map(Memory.fromJson)
          .toList();
    }
    throw Exception('Failed to load memories: ${response.body}');
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

    final response = await _apiService.get(
      '/memories/stats/summary',
      queryParameters: queryParameters,
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final summaryJson = decoded['summary'] is Map<String, dynamic>
            ? decoded['summary'] as Map<String, dynamic>
            : decoded;
        return MemorySummary.fromJson(summaryJson);
      }
      throw Exception('Invalid summary response');
    }
    throw Exception('Failed to load memory summary: ${response.body}');
  }

  Future<Memory> getMemoryById(String id) async {
    final response = await _apiService.get('/memories/$id');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final payload = decoded['memory'] is Map<String, dynamic>
            ? decoded['memory'] as Map<String, dynamic>
            : decoded;
        return Memory.fromJson(payload);
      }
    }
    throw Exception('Failed to load memory: ${response.body}');
  }

  Future<Memory> createMemory({
    required double latitude,
    required double longitude,
    required Map<String, dynamic> anchor,
    String? text,
    List<String>? tags,
    String? groupId,
    String visibility = 'private',
    bool favorite = false,
    String? photoUrl,
    String? thumbUrl,
    String? audioUrl,
  }) async {
    final response = await _apiService.post(
      '/memories',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'anchor': anchor,
        if (text != null) 'text': text,
        if (tags != null) 'tags': tags,
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
        'visibility': visibility,
        'favorite': favorite,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (thumbUrl != null) 'thumbUrl': thumbUrl,
        if (audioUrl != null) 'audioUrl': audioUrl,
      },
    );
    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return Memory.fromJson(decoded);
      }
    }
    throw Exception('Failed to create memory: ${response.body}');
  }

  Future<Memory> updateMemory(
    String id, {
    String? text,
    List<String>? tags,
    bool? favorite,
    String? visibility,
    String? groupId,
    Map<String, dynamic>? anchor,
  }) async {
    final response = await _apiService.put(
      '/memories/$id',
      data: {
        if (text != null) 'text': text,
        if (tags != null) 'tags': tags,
        if (favorite != null) 'favorite': favorite,
        if (visibility != null) 'visibility': visibility,
        if (groupId != null) 'groupId': groupId,
        if (anchor != null) 'anchor': anchor,
      },
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final payload = decoded['memory'] is Map<String, dynamic>
            ? decoded['memory'] as Map<String, dynamic>
            : decoded;
        return Memory.fromJson(payload);
      }
    }
    throw Exception('Failed to update memory: ${response.body}');
  }

  Future<void> deleteMemory(String id) async {
    final response = await _apiService.delete('/memories/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete memory: ${response.body}');
    }
  }

  Future<List<Memory>> searchNearby({
    required double latitude,
    required double longitude,
    double radius = 500,
  }) async {
    final response = await _apiService.get(
      '/memories/near/search',
      queryParameters: {
        'lat': latitude,
        'lng': longitude,
        'radius': radius,
      },
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      dynamic rawItems = decoded;
      if (decoded is Map<String, dynamic>) {
        rawItems = decoded['items'] ?? decoded['results'] ?? decoded['data'] ?? decoded['memories'];
      }
      final items = _unwrapList(rawItems);
      return items
          .whereType<Map<String, dynamic>>()
          .map(Memory.fromJson)
          .toList();
    }
    throw Exception('Failed to load nearby memories: ${response.body}');
  }

  Future<List<Memory>> searchInView({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    required double centerLat,
    required double centerLng,
    int limit = 100,
  }) async {
    final response = await _apiService.get(
      '/memories/in/view',
      queryParameters: {
        'swLat': swLat,
        'swLng': swLng,
        'neLat': neLat,
        'neLng': neLng,
        'centerLat': centerLat,
        'centerLng': centerLng,
        'limit': limit,
      },
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      dynamic rawItems = decoded;
      if (decoded is Map<String, dynamic>) {
        rawItems = decoded['items'] ?? decoded['results'] ?? decoded['data'] ?? decoded['memories'];
      }
      final items = _unwrapList(rawItems);

      return items
          .whereType<Map<String, dynamic>>()
          .map(Memory.fromJson)
          .toList();


    }
    throw Exception('Failed to search memories in view: ${response.body}');
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