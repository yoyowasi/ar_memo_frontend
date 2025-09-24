import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/repositories/upload_repository.dart';

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository();
});
