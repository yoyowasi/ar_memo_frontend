// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ar_memo_frontend/providers/api_service_provider.dart';
import 'package:ar_memo_frontend/providers/user_provider.dart';
import 'package:ar_memo_frontend/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepository(apiService);
});

class AuthState extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final authRepository = ref.watch(authRepositoryProvider);
    await authRepository.init();

    if (authRepository.isLoggedIn) {
      final isValid = await authRepository.verifyToken();
      if (!isValid) {
        await authRepository.logout();
      }
      return isValid;
    }
    return false;
  }

  Future<void> login(String email, String password) async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await authRepository.login(email, password);
      ref.invalidate(currentUserProvider);
      return true;
    });
  }

  Future<void> register(String email, String password, [String? name]) async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await authRepository.register(email, password, name);
      ref.invalidate(currentUserProvider);
      return true;
    });
  }

  Future<void> logout() async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await authRepository.logout();
      ref.invalidate(currentUserProvider);
      return false;
    });
  }
}

final authStateProvider = AsyncNotifierProvider<AuthState, bool>(AuthState.new);
