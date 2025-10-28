import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/models/group.dart';
import 'package:ar_memo_frontend/repositories/group_repository.dart';
import 'package:ar_memo_frontend/providers/api_service_provider.dart';

part 'group_provider.g.dart';

@riverpod
GroupRepository groupRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return GroupRepository(apiService);
}

@riverpod
Future<List<Group>> myGroups(Ref ref) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getMyGroups();
}

@riverpod
Future<Group> groupDetail(Ref ref, String id) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupDetail(id);
}
