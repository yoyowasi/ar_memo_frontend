import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/providers/auth_provider.dart';
import 'package:ar_memo_frontend/screens/login_screen.dart';
import 'package:ar_memo_frontend/screens/main_screen.dart'; // HomeScreen 대신 MainScreen

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authStateProvider);

    // 로그인 상태에 따라 MainScreen 또는 LoginScreen을 보여줍니다.
    return isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}