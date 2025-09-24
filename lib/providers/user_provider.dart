import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ar_memo_frontend/models/user.dart';
import 'package:ar_memo_frontend/repositories/auth_repository.dart';

final currentUserProvider = FutureProvider<User>((ref) async {
  final repository = AuthRepository();
  if (!repository.isLoggedIn) {
    await repository.init();
  }
  final data = await repository.fetchCurrentUser();
  final userJson = data['user'] is Map<String, dynamic> ? data['user'] as Map<String, dynamic> : data;
  return User.fromJson(userJson);
});
