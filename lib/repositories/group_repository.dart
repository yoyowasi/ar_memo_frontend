import 'dart:convert';

import 'package:ar_memo_frontend/models/group.dart';
import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/services/api_service.dart';

class GroupRepository {
  final ApiService _apiService;

  GroupRepository(this._apiService);

  List<dynamic> _unwrapList(dynamic data) {
    if (data is List<dynamic>) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final payload = data['items'] ?? data['groups'] ?? data['data'];
      if (payload is List<dynamic>) {
        return payload;
      }
    }
    return const [];
  }

  Future<List<Group>> getMyGroups() async {
    final response = await _apiService.get('/api/groups');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final items = _unwrapList(decoded);
      return items
          .whereType<Map<String, dynamic>>()
          .map(Group.fromJson)
          .toList();
    }
    throw Exception('Failed to load groups: ${response.body}');
  }

  Future<Group> getGroupDetail(String id) async {
    final response = await _apiService.get('/api/groups/$id');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final payload = decoded['group'] is Map<String, dynamic>
            ? decoded['group'] as Map<String, dynamic>
            : decoded;
        return Group.fromJson(payload);
      }
    }
    throw Exception('Failed to fetch group: ${response.body}');
  }

  Future<Group> createGroup({
    required String name,
    String? colorHex,
  }) async {
    final response = await _apiService.post(
      '/api/groups',
      data: {
        'name': name,
        if (colorHex != null && colorHex.isNotEmpty) 'color': colorHex,
      },
    );
    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return Group.fromJson(decoded);
      }
    }
    throw Exception('Failed to create group: ${response.body}');
  }

  Future<Group> updateGroup({
    required String id,
    String? name,
    String? colorHex,
  }) async {
    final response = await _apiService.put(
      '/api/groups/$id',
      data: {
        if (name != null) 'name': name,
        if (colorHex != null) 'color': colorHex,
      },
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final payload = decoded['group'] is Map<String, dynamic>
            ? decoded['group'] as Map<String, dynamic>
            : decoded;
        return Group.fromJson(payload);
      }
    }
    throw Exception('Failed to update group: ${response.body}');
  }

  Future<void> deleteGroup(String id) async {
    final response = await _apiService.delete('/api/groups/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete group: ${response.body}');
    }
  }

  Future<List<Memory>> getGroupMemories(String id, {int page = 1, int limit = 20}) async {
    final response = await _apiService.get(
      '/api/groups/$id/memories',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
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

  Future<Group> addMember({required String groupId, required String userId}) async {
    final response = await _apiService.post(
      '/api/groups/$groupId/members',
      data: {'userId': userId},
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final payload = decoded['group'] is Map<String, dynamic>
            ? decoded['group'] as Map<String, dynamic>
            : decoded;
        return Group.fromJson(payload);
      }
    }
    throw Exception('Failed to add member: ${response.body}');
  }

  Future<Group> removeMember({required String groupId, required String userId}) async {
    final response = await _apiService.delete('/api/groups/$groupId/members/$userId');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final payload = decoded['group'] is Map<String, dynamic>
            ? decoded['group'] as Map<String, dynamic>
            : decoded;
        return Group.fromJson(payload);
      }
    }
    throw Exception('Failed to remove member: ${response.body}');
  }
}