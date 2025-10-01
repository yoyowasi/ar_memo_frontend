import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/models/group.dart';
import 'package:ar_memo_frontend/repositories/group_repository.dart';

final groupRepositoryProvider = Provider((ref) => GroupRepository());

// 그룹 목록을 관리하고 업데이트하기 위해 StateNotifierProvider를 사용합니다.
final myGroupsProvider =
StateNotifierProvider<MyGroupsNotifier, AsyncValue<List<Group>>>((ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return MyGroupsNotifier(repository);
});

// 그룹 상세 정보를 가져오기 위한 FutureProvider (오류 수정)
final groupDetailProvider =
FutureProvider.family<Group, String>((ref, groupId) {
  final repository = ref.watch(groupRepositoryProvider);
  // getGroupDetails -> getGroupDetail로 메소드 이름 수정
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

  Future<void> createGroup(String name, {String? color}) async {
    try {
      // Repository의 메소드에 맞게 명명된 파라미터로 전달
      await _repository.createGroup(name: name, colorHex: color);
      await fetchMyGroups(); // 그룹 생성 후 목록을 즉시 새로고침
    } catch (e) {
      rethrow; // UI에서 에러를 처리할 수 있도록 다시 던집니다.
    }
  }
}