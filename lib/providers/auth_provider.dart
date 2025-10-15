// lib/providers/auth_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ar_memo_frontend/repositories/auth_repository.dart';
import 'package:ar_memo_frontend/providers/user_provider.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

// Use AsyncNotifier for async initialization
@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  Future<bool> build() async {
    // The build method now returns a Future
    final authRepository = ref.watch(authRepositoryProvider);
    await authRepository.init();
    return authRepository.isLoggedIn;
  }

  Future<void> login(String email, String password) async {
    final authRepository = ref.read(authRepositoryProvider);
    // Set state to loading
    state = const AsyncValue.loading();
    // Update state based on the outcome of the async operation
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