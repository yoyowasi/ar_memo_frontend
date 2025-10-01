import 'dart:convert';

import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/models/memory_summary.dart';
import 'package:ar_memo_frontend/services/api_service.dart';

/// Memory 데이터와 관련된 API 통신을 담당하는 클래스
class MemoryRepository {
  final ApiService _apiService = ApiService();

  /// API 응답에서 실제 데이터 목록을 추출하는 private 헬퍼 메서드
  List<dynamic> _unwrapList(dynamic data) {
    if (data is List<dynamic>) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      // 일반적인 페이로드 키들을 확인하여 리스트를 반환
      final payload = data['items'] ?? data['data'] ?? data['results'] ?? data['memories'];
      if (payload is List<dynamic>) {
        return payload;
      }
    }
    // 해당하는 데이터가 없으면 빈 리스트 반환
    return const [];
  }

  /// 나의 Memory 목록을 가져오는 메서드
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
      return items.whereType<Map<String, dynamic>>().map(Memory.fromJson).toList();
    }
    throw Exception('Failed to load memories: ${response.body}');
  }

  /// Memory 요약 정보(통계)를 가져오는 메서드
  Future<MemorySummary> getMemorySummary({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (latitude != null && longitude != null) {
      queryParameters['lat'] = latitude;
      queryParameters['lng'] = longitude;
    }
    if (radius != null) {
      queryParameters['radius'] = radius;
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
      throw Exception('Invalid summary response format');
    }
    throw Exception('Failed to load memory summary: ${response.body}');
  }

  /// ID로 특정 Memory의 상세 정보를 가져오는 메서드
  Future<Memory> getMemoryById(String id) async {
    final response = await _apiService.get('/memories/$id');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        // 응답 데이터에 'memory' 키가 있는지 확인하고 파싱
        final payload = decoded['memory'] is Map<String, dynamic>
            ? decoded['memory'] as Map<String, dynamic>
            : decoded;
        return Memory.fromJson(payload);
      }
    }
    throw Exception('Failed to load memory: ${response.body}');
  }

  /// 새로운 Memory를 생성하는 메서드
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

  /// 기존 Memory를 수정하는 메서드
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

  /// ID로 특정 Memory를 삭제하는 메서드
  Future<void> deleteMemory(String id) async {
    final response = await _apiService.delete('/memories/$id');
    // 성공 응답 코드가 200 또는 204가 아니면 예외 발생
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete memory: ${response.body}');
    }
  }

  /// 특정 좌표 주변의 Memory를 검색하는 메서드
  Future<List<Memory>> searchNearby({
    required double latitude,
    required double longitude,
    double radius = 500, // 기본 반경 500m
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
      final items = _unwrapList(decoded);
      return items.whereType<Map<String, dynamic>>().map(Memory.fromJson).toList();
    }
    throw Exception('Failed to load nearby memories: ${response.body}');
  }

  /// 지도 화면 영역 내의 Memory를 검색하는 메서드
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
      final items = _unwrapList(decoded);
      return items.whereType<Map<String, dynamic>>().map(Memory.fromJson).toList();
    }
    throw Exception('Failed to search memories in view: ${response.body}');
  }

  /// 그룹 ID로 메모 목록을 가져오는 메소드
  Future<List<Memory>> getGroupMemories(String groupId) async {
    final response = await _apiService.get('/groups/$groupId/memories');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final items = _unwrapList(decoded);
      return items.whereType<Map<String, dynamic>>().map(Memory.fromJson).toList();
    }
    throw Exception('Failed to load group memories: ${response.body}');
  }
}