import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/models/group.dart';
import 'package:ar_memo_frontend/providers/auth_provider.dart';
import 'package:ar_memo_frontend/providers/user_provider.dart';
import 'package:ar_memo_frontend/providers/group_provider.dart';
import 'package:ar_memo_frontend/providers/memory_provider.dart';
import 'package:ar_memo_frontend/screens/group_detail_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  // 그룹 생성/수정 팝업
  void _showGroupDialog(BuildContext context, WidgetRef ref, {Group? groupToEdit}) {
    final nameController = TextEditingController(text: groupToEdit?.name);
    String? selectedColorHex = groupToEdit?.colorHex ?? '#FF8040';
    bool isLoading = false;
    final bool isEditMode = groupToEdit != null;

    final List<String> colorPalette = [
      '#FF8040', '#FFB380', '#FFC9A3', '#FFDBC2', '#FFE8D9',
      '#FF94AD', '#FFB3C4', '#FFD1DA', '#FFE0E7', '#FFEBF0',
      '#8D7BFD', '#ADA2FD', '#CDBFFD', '#DCD7FE', '#EAE6FE',
      '#7BC6FD', '#A1D6FE', '#C3E4FE', '#D9EFFE', '#EAF6FE',
      '#7BFDB9', '#A1FDBF', '#C3FDCE', '#D9FDDE', '#EAFEEC',
    ];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            Future<void> submitGroup() async {
              final name = nameController.text;
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('그룹 이름을 입력하세요.')));
                return;
              }
              setState(() => isLoading = true);
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              final groupRepo = ref.read(groupRepositoryProvider);
              try {
                if (isEditMode) {
                  await groupRepo.updateGroup(id: groupToEdit!.id, name: name, colorHex: selectedColorHex);
                } else {
                  await groupRepo.createGroup(name: name, colorHex: selectedColorHex);
                }
                ref.invalidate(myGroupsProvider);
                navigator.pop();
                messenger.showSnackBar(SnackBar(content: Text(isEditMode ? '그룹이 수정되었습니다.' : '그룹이 생성되었습니다.')));
              } catch (e) {
                if (builderContext.mounted) messenger.showSnackBar(SnackBar(content: Text('오류 발생: $e')));
              } finally {
                if (builderContext.mounted) setState(() => isLoading = false);
              }
            }

            // 팝업 UI
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.only(top: 24, bottom: 0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              title: Center(child: Text(isEditMode ? '그룹 수정' : '그룹 만들기', style: heading2)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: nameController, decoration: InputDecoration(labelText: '그룹 이름', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)), style: bodyText1),
                    const SizedBox(height: 16),
                    const Text('그룹 색상', style: bodyText1),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0, runSpacing: 8.0,
                      children: colorPalette.map((hex) {
                        final colorValue = int.tryParse('0xFF${hex.replaceFirst('#', '')}') ?? 0xFFFFFFFF;
                        final bool isSelected = selectedColorHex == hex;
                        return InkWell(
                          onTap: () => setState(() => selectedColorHex = hex),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: Color(colorValue), shape: BoxShape.circle, border: isSelected ? Border.all(color: primaryColor, width: 3) : Border.all(color: Colors.grey[300]!, width: 1)),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: <Widget>[
                TextButton(child: const Text('취소', style: TextStyle(color: subTextColor)), onPressed: () => Navigator.pop(dialogContext)),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: isLoading ? null : submitGroup, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 24)), child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,)) : Text(isEditMode ? '수정 완료' : '만들기')),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final myGroupsAsync = ref.watch(myGroupsProvider);
    final memorySummaryAsync = ref.watch(memorySummaryProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('프로필', style: heading2),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: borderColor, height: 1.0)
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          ref.invalidate(myGroupsProvider);
          ref.invalidate(memorySummaryProvider);
          await Future.wait([
            ref.read(currentUserProvider.future),
            ref.read(myGroupsProvider.future),
            ref.read(memorySummaryProvider.future),
          ]);
        },
        child: ListView(
          children: [
            // 프로필 정보
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: userAsync.when(
                data: (user) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  CircleAvatar(radius: 40, backgroundColor: mutedSurfaceColor, backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null, child: user.avatarUrl.isEmpty ? const Icon(Icons.person_outline, size: 40, color: subTextColor) : null),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.name.isNotEmpty ? user.name : '이름 없음', style: heading1), const SizedBox(height: 4),
                    Text(user.email, style: bodyText2),
                  ],),
                  ),
                ],),
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (error, _) => Center(child: Text('프로필 로딩 오류: $error', textAlign: TextAlign.center, style: bodyText2)),
              ),
            ),
            // 통계
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
                child: memorySummaryAsync.when(
                    data: (summary) => Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _buildStatItem('전체 일기', summary.total.toString()),
                      _buildStatItem('방문한 달', '-'), // TODO
                      _buildStatItem('방문한 곳', '-'), // TODO
                    ],),
                    loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, __) => const SizedBox(height: 60, child: Center(child: Text('통계 로딩 실패', style: bodyText2)))
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 그룹
            _buildSectionTitle('나의 그룹', actionWidget: IconButton(icon: const Icon(Icons.add_circle_outline, color: primaryColor), tooltip: '새 그룹 만들기', onPressed: () => _showGroupDialog(context, ref))),
            myGroupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Padding(padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0), child: Center(child: Text('소속된 그룹이 없습니다.', style: bodyText2)));
                }
                return ListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero,
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                      leading: CircleAvatar(backgroundColor: Color(group.colorValue), child: Text(group.name.isNotEmpty ? group.name[0].toUpperCase() : '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      title: Text(group.name, style: bodyText1),
                      subtitle: Text('멤버 ${group.memberIds.length + 1}명', style: bodyText2), // TODO: 멤버 수 정확히 표시
                      trailing: const Icon(Icons.chevron_right, color: subTextColor),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GroupDetailScreen(groupId: group.id))),
                      onLongPress: () => _showGroupDialog(context, ref, groupToEdit: group),
                    );
                  },
                );
              },
              loading: () => const Padding(padding: EdgeInsets.all(24.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (err, stack) => Padding(padding: const EdgeInsets.all(24.0), child: Center(child: Text('그룹 목록 로딩 실패: $err', textAlign: TextAlign.center, style: bodyText2))),
            ),
            const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16),
            // 설정
            _buildSectionTitle('설정'),
            _buildMenuListItem(icon: Icons.notifications_outlined, title: '알림 설정', onTap: () { /* TODO */ }),
            _buildMenuListItem(icon: Icons.info_outline, title: '앱 정보', onTap: () { /* TODO */ }),
            const Divider(height: 16, thickness: 1, indent: 16, endIndent: 16),
            _buildMenuListItem(icon: Icons.logout, title: '로그아웃', onTap: () => ref.read(authStateProvider.notifier).logout()),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 통계 아이템 위젯
  Widget _buildStatItem(String label, String value) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: heading1.copyWith(color: primaryColor, fontSize: 22)), const SizedBox(height: 4),
      Text(label, style: bodyText2),
    ],);
  }

  // 섹션 타이틀 위젯
  Widget _buildSectionTitle(String title, {Widget? actionWidget}) {
    return Padding(padding: const EdgeInsets.only(left: 20.0, right: 8.0, top: 16.0, bottom: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: heading2.copyWith(fontSize: 18)),
      if (actionWidget != null) actionWidget,
    ],),);
  }

  // 메뉴 리스트 아이템 위젯
  Widget _buildMenuListItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
      leading: Icon(icon, color: subTextColor, size: 24),
      title: Text(title, style: bodyText1),
      trailing: const Icon(Icons.chevron_right, color: subTextColor, size: 24),
      onTap: onTap,
    );
  }
}