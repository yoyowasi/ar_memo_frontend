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
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (isLoggedIn) => isLoggedIn ? const MainScreen() : const LoginScreen(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('An error occurred: $err')),
      ),
    );
  }
}