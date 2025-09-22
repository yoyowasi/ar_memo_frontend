import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/repositories/auth_repository.dart';

// AuthRepository 인스턴스를 제공하는 프로바이더
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// 로그인 상태를 관리하는 프로바이더
final authStateProvider = StateNotifierProvider<AuthStateNotifier, bool>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(authRepository);
});

class AuthStateNotifier extends StateNotifier<bool> {
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository) : super(_authRepository.isLoggedIn);

  Future<void> init() async {
    await _authRepository.init();
    state = _authRepository.isLoggedIn;
  }

  Future<void> login(String email, String password) async {
    await _authRepository.login(email, password);
    state = true;
  }

  Future<void> register(String email, String password, [String? name]) async {
    await _authRepository.register(email, password, name);
    state = true;
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = false;
  }
}