import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ar_memo_frontend/models/group.dart';
import 'package:ar_memo_frontend/providers/api_service_provider.dart';
import 'package:ar_memo_frontend/repositories/group_repository.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return GroupRepository(apiService);
});

final myGroupsProvider = FutureProvider<List<Group>>((ref) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getMyGroups();
});

final groupDetailProvider = FutureProvider.family<Group, String>((ref, id) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupDetail(id);
});
