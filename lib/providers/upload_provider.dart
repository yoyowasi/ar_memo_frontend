import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ar_memo_frontend/repositories/upload_repository.dart';

part 'upload_provider.g.dart';

@riverpod
UploadRepository uploadRepository(Ref ref) {
  return UploadRepository();
}