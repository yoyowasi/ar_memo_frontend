import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ar_memo_frontend/models/user.dart';
import 'package:ar_memo_frontend/providers/auth_provider.dart';

part 'user_provider.g.dart';

@riverpod
Future<User> currentUser(Ref ref) async {
  final repository = ref.watch(authRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  // Only proceed when the auth state is successfully loaded and is true.
  if (authState.value == true) {
    final data = await repository.fetchCurrentUser();
    final userJson = data['user'] is Map<String, dynamic> ? data['user'] as Map<String, dynamic> : data;
    return User.fromJson(userJson);
  } else {
    throw Exception('User not logged in');
  }
}