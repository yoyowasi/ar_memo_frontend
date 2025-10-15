
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/auth_repository.dart';
import 'package:ar_memo_frontend/providers/user_provider.dart';

part 'auth_provider.g.dart';

// AuthRepository 인스턴스를 제공하는 프로바이더
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

// 로그인 상태를 관리하는 프로바이더
@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  bool build() {
    final authRepository = ref.watch(authRepositoryProvider);
    // 앱 시작 시, 저장된 로그인 정보로 상태를 초기화합니다.
    _initialize(authRepository);
    return authRepository.isLoggedIn;
  }

  Future<void> _initialize() async {
    await _authRepository.init();
    state = _authRepository.isLoggedIn;
  }

  Future<void> login(String email, String password) async {
    await ref.read(authRepositoryProvider).login(email, password);
    ref.invalidate(currentUserProvider); // 현재 유저 정보 갱신
    state = true;
  }

  Future<void> register(String email, String password, [String? name]) async {
    await ref.read(authRepositoryProvider).register(email, password, name);
    ref.invalidate(currentUserProvider); // 현재 유저 정보 갱신
    state = true;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.invalidate(currentUserProvider); // 현재 유저 정보 무효화
    state = false;
  }
}
