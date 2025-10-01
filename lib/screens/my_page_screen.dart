// lib/screens/my_page_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/providers/auth_provider.dart';
import 'package:ar_memo_frontend/providers/user_provider.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('마이페이지', style: heading2),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: userAsync.when(
        data: (user) => ListView(
          children: [
            const SizedBox(height: 24),
            // 프로필 정보 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: mutedSurfaceColor,
                    backgroundImage: user.avatarUrl.isNotEmpty
                        ? NetworkImage(user.avatarUrl)
                        : null,
                    child: user.avatarUrl.isEmpty
                        ? const Icon(Icons.person,
                        size: 40, color: subTextColor)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name.isNotEmpty ? user.name : '이름 없음',
                            style: heading2),
                        const SizedBox(height: 4),
                        Text(user.email, style: bodyText1),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: subTextColor),
                    onPressed: () {
                      // TODO: 내 정보 수정 페이지로 이동
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(thickness: 8, color: mutedSurfaceColor),

            // 메뉴 리스트
            _buildMenuList(context, ref),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('프로필 정보를 불러오지 못했습니다.\n잠시 후 다시 시도해주세요.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentUserProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 메뉴 리스트 위젯
  Widget _buildMenuList(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildMenuListItem(
          icon: Icons.group_outlined,
          title: '그룹 관리',
          onTap: () {
            // MainScreen의 BottomNavigationBar 인덱스를 변경하여 화면 전환
            DefaultTabController.of(context).animateTo(1);
          },
        ),
        _buildMenuListItem(
          icon: Icons.notifications_outlined,
          title: '알림 설정',
          onTap: () {},
        ),

        _buildMenuListItem(
          icon: Icons.help_outline,
          title: '고객센터',
          onTap: () {},
        ),
        _buildMenuListItem(
          icon: Icons.info_outline,
          title: '앱 정보',
          onTap: () {},
        ),
        const Divider(indent: 16, endIndent: 16),
        _buildMenuListItem(
          icon: Icons.logout,
          title: '로그아웃',
          onTap: () => ref.read(authStateProvider.notifier).logout(),
        ),
      ],
    );
  }

  // 메뉴 항목을 만드는 헬퍼 위젯
  Widget _buildMenuListItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: subTextColor),
      title: Text(title, style: bodyText1),
      trailing: const Icon(Icons.chevron_right, color: subTextColor),
      onTap: onTap,
    );
  }
}