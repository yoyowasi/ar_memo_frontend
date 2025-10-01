import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/models/group.dart';
import 'package:ar_memo_frontend/repositories/group_repository.dart';

final groupRepositoryProvider = Provider((ref) => GroupRepository());

final myGroupsProvider =
StateNotifierProvider<MyGroupsNotifier, AsyncValue<List<Group>>>((ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return MyGroupsNotifier(repository);
});

// 그룹 상세 정보를 위한 Provider (메소드 이름 오류 수정)
final groupDetailProvider =
FutureProvider.family<Group, String>((ref, groupId) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupDetail(groupId);
});

class MyGroupsNotifier extends StateNotifier<AsyncValue<List<Group>>> {
  final GroupRepository _repository;

  MyGroupsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchMyGroups();
  }

  Future<void> fetchMyGroups() async {
    state = const AsyncValue.loading();
    try {
      final groups = await _repository.getMyGroups();
      state = AsyncValue.data(groups);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // 그룹 생성 메소드 (파라미터 오류 수정)
  Future<void> createGroup({required String name, String? color}) async {
    try {
      await _repository.createGroup(name: name, colorHex: color);
      await fetchMyGroups(); // 목록 새로고침
    } catch (e) {
      rethrow;
    }
  }
}