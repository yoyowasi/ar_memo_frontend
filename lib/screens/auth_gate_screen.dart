import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/providers/auth_provider.dart';
import 'package:ar_memo_frontend/screens/login_screen.dart';

// TODO: 실제 홈 화면을 만들고 교체해야 합니다.
// StatelessWidget -> ConsumerWidget 으로 변경
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  // ConsumerWidget의 build 메소드는 WidgetRef를 두 번째 매개변수로 받습니다.
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // 이제 'ref'를 정상적으로 사용할 수 있습니다.
            ref.read(authStateProvider.notifier).logout();
          },
          child: const Text('Logout'),
        ),
      ),
    );
  }
}


class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    // 위젯이 빌드된 후 초기화 함수를 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authStateProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authStateProvider);

    return isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}