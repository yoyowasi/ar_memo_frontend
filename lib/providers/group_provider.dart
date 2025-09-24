import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/models/group.dart';
import 'package:ar_memo_frontend/repositories/group_repository.dart';

final groupRepositoryProvider = Provider((ref) => GroupRepository());

final myGroupsProvider = FutureProvider<List<Group>>((ref) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getMyGroups();
});