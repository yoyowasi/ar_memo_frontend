import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/models/user.dart';
import 'package:ar_memo_frontend/providers/auth_provider.dart';

part 'user_provider.g.dart';

@riverpod
Future<User> currentUser(Ref ref) async {
  final repository = ref.watch(authRepositoryProvider);
  final isLoggedIn = await ref.watch(authStateProvider.future);

  if (isLoggedIn) {
    final data = await repository.fetchCurrentUser();
    final userJson = data['user'] is Map<String, dynamic> ? data['user'] as Map<String, dynamic> : data;
    return User.fromJson(userJson);
  } else {
    throw Exception('User not logged in');
  }
}