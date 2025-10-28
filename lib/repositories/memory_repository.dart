import 'dart:convert';
import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/models/memory_summary.dart';
import 'package:ar_memo_frontend/services/api_service.dart';

/// Memory 데이터와 관련된 API 통신을 담당하는 클래스
class MemoryRepository {
  final ApiService _apiService;

  MemoryRepository(this._apiService);

  Map<String, dynamic> _cleanPayload(Map<String, dynamic> payload) {
    payload.removeWhere((key, value) =>
        value == null || (value is Iterable && value.isEmpty));
    return payload;
  }

  /// API 응답에서 실제 데이터 목록을 추출하는 private 헬퍼 메서드
  List<dynamic> _unwrapList(dynamic data) {
    if (data is List<dynamic>) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final payload =
          data['items'] ?? data['data'] ?? data['results'] ?? data['memories'];
      if (payload is List<dynamic>) {
        return payload;
      }
    }
    return const [];
  }

  /// 새로운 Memory를 생성하는 메서드
  Future<Memory> createMemory({
    required double latitude,
    required double longitude,
    String? text,
    List<String>? tags,
    String? groupId,
    String? visibility,
    String? photoUrl,
    String? audioUrl,
    List<double>? anchor,
  }) async {
    final payload = _cleanPayload({
      'latitude': latitude,
      'longitude': longitude,
      'text': text,
      'tags': tags,
      'groupId': groupId,
      'visibility': visibility,
      'photoUrl': photoUrl,
      'audioUrl': audioUrl,
      'anchor': anchor,
    });

    final response = await _apiService.post(
      '/memories',
      data: payload,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final payload = decoded['memory'] is Map<String, dynamic>
            ? decoded['memory'] as Map<String, dynamic>
            : decoded;
        return Memory.fromJson(payload);
      }
      throw Exception('Invalid create memory response format');
    }
    throw Exception('Failed to create memory: ${response.body}');
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
      return items
          .whereType<Map<String, dynamic>>()
          .map(Memory.fromJson)
          .toList();
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
        final payload = decoded['memory'] is Map<String, dynamic>
            ? decoded['memory'] as Map<String, dynamic>
            : decoded;
        return Memory.fromJson(payload);
      }
    }
    throw Exception('Failed to load memory: ${response.body}');
  }

  /// 그룹 ID로 메모 목록을 가져오는 메소드
  Future<List<Memory>> getGroupMemories(String groupId) async {
    final response = await _apiService.get('/groups/$groupId/memories');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final items = _unwrapList(decoded);
      return items
          .whereType<Map<String, dynamic>>()
          .map(Memory.fromJson)
          .toList();
    }
    throw Exception('Failed to load group memories: ${response.body}');
  }
}