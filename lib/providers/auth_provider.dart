// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/repositories/auth_repository.dart';
import 'package:ar_memo_frontend/providers/user_provider.dart';

// AuthRepository 인스턴스를 제공하는 프로바이더
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// 로그인 상태를 관리하는 프로바이더
final authStateProvider = NotifierProvider<AuthStateNotifier, bool>(AuthStateNotifier.new);

class AuthStateNotifier extends Notifier<bool> {
  late AuthRepository _authRepository;

  @override
  bool build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _initialize();
    return _authRepository.isLoggedIn;
  }

  Future<void> _initialize() async {
    await _authRepository.init();
    // 'if (mounted)'를 제거하고 바로 상태를 업데이트합니다.
    state = _authRepository.isLoggedIn;
  }

  Future<void> login(String email, String password) async {
    await _authRepository.login(email, password);
    ref.invalidate(currentUserProvider);
    state = true;
  }

  Future<void> register(String email, String password, [String? name]) async {
    await _authRepository.register(email, password, name);
    ref.invalidate(currentUserProvider);
    state = true;
  }

  Future<void> logout() async {
    await _authRepository.logout();
    ref.invalidate(currentUserProvider);
    state = false;
  }
}