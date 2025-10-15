import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/providers/group_provider.dart';
import 'package:ar_memo_frontend/screens/group_detail_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';

class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key});

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Center(child: Text('새 그룹 만들기')),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: '그룹 이름을 입력하세요',
              border: OutlineInputBorder(),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text;
                if (name.isNotEmpty) {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    // 수정된 Provider 호출 방식
                    await ref
                        .read(myGroupsProvider.notifier)
                        .createGroup(name: name);
                    navigator.pop();
                  } catch (e) {
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('그룹 생성 실패: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('만들기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myGroups = ref.watch(myGroupsProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('내 그룹', style: heading2),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: textColor),
            onPressed: () => _showCreateGroupDialog(context, ref),
          ),
        ],
      ),
      body: myGroups.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
                child: Text('소속된 그룹이 없습니다.\n새로운 그룹을 만들어보세요!',
                    textAlign: TextAlign.center, style: bodyText1));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myGroupsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Card(
                  elevation: 1.5,
                  margin:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(group.colorValue),
                      child: Text(
                        group.name.isNotEmpty ? group.name[0] : '',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(group.name, style: bodyText1),
                    subtitle: Text('멤버 ${group.memberIds.length}명'),
                    trailing:
                    const Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GroupDetailScreen(groupId: group.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('오류 발생: $err')),
      ),
    );
  }
}