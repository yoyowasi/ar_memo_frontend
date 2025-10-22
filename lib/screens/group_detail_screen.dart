import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:kakao_map_plugin/kakao_map_plugin.dart'; // <- 삭제
import 'package:ar_memo_frontend/models/group.dart';
import 'package:ar_memo_frontend/providers/group_provider.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          data: (group) => Text(group.name, style: heading2),
          loading: () => const Text('그룹 정보 로딩...', style: heading2),
          error: (_, __) => const Text('그룹 정보', style: heading2),
        ),
      ),
      body: groupAsync.when(
        data: (Group group) => ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- 지도 위젯 제거 ---
            // SizedBox(height: 200, child: KakaoMap(...)),
            // const SizedBox(height: 16),
            // ---------------------

            Text('그룹 ID: ${group.id}', style: bodyText2),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('그룹 색상: ', style: bodyText1),
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                      color: Color(group.colorValue), // Group 모델의 getter 사용
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey)
                  ),
                )
              ],
            ),
            const Divider(height: 32),
            Text('멤버 목록', style: heading2.copyWith(fontSize: 18)),
            // TODO: 멤버 목록 표시 (User 정보 필요)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('사용자 ID: ${group.ownerId} (소유자)'),
            ),
            ...group.memberIds.map((memberId) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text('사용자 ID: $memberId'),
            )),
            const Divider(height: 32),
            Text('그룹 관련 기록', style: heading2.copyWith(fontSize: 18)),
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text('(관련 기록 표시 예정)', style: bodyText2),
            )),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('그룹 정보를 불러오는 중 오류 발생: $err')),
      ),
    );
  }
}