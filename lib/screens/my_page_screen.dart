import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/providers/auth_provider.dart';
import 'package:ar_memo_frontend/providers/user_provider.dart';
import 'package:ar_memo_frontend/theme/text_styles.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
      ),
      body: userAsync.when(
        data: (user) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
              child: user.avatarUrl.isEmpty
                  ? Text(
                      user.name.isNotEmpty
                          ? user.name.substring(0, 1)
                          : (user.email.isNotEmpty ? user.email.substring(0, 1) : '?'),
                      style: heading2,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(user.name.isNotEmpty ? user.name : '이름 미등록', style: heading2),
                  const SizedBox(height: 4),
                  Text(user.email, style: bodyText1),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => ref.read(authStateProvider.notifier).logout(),
              child: const Text('로그아웃'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('프로필 정보를 불러오지 못했습니다.\n${error.toString()}'),
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
}