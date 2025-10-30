import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ar_memo_frontend/repositories/upload_repository.dart';
import 'package:ar_memo_frontend/providers/api_service_provider.dart';

part 'upload_provider.g.dart';

@riverpod
UploadRepository uploadRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UploadRepository(apiService);
}