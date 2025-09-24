import 'dart:convert';

import 'package:ar_memo_frontend/services/api_service.dart';

import '../models/group.dart';

class GroupRepository {
  final ApiService _apiService = ApiService();

  Future<List<Group>> getMyGroups() async {
    final response = await _apiService.get('/groups');
    if (response.statusCode == 200) {
      final List<dynamic> items = jsonDecode(response.body);
      return items.map((item) => Group.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load groups');
    }
  }
}