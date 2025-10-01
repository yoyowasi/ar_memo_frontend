import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ar_memo_frontend/models/group.dart';
import 'package:ar_memo_frontend/repositories/group_repository.dart';

part 'group_provider.g.dart';

@riverpod
GroupRepository groupRepository(Ref ref) {
  return GroupRepository();
}

@riverpod
class MyGroups extends _$MyGroups {
  @override
  Future<List<Group>> build() {
    return ref.watch(groupRepositoryProvider).getMyGroups();
  }

  Future<void> createGroup({required String name, String? color}) async {
    final repository = ref.read(groupRepositoryProvider);
    await repository.createGroup(name: name, colorHex: color);
    ref.invalidateSelf();
  }
}

@riverpod
Future<Group> groupDetail(Ref ref, String groupId) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupDetail(groupId);
}
