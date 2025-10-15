import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/models/memory_summary.dart';
import 'package:ar_memo_frontend/repositories/memory_repository.dart';

part 'memory_provider.g.dart';

@riverpod
MemoryRepository memoryRepository(Ref ref) {
  return MemoryRepository();
}

@riverpod
Future<List<Memory>> myMemories(Ref ref) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.getMyMemories(limit: 12);
}

@riverpod
Future<MemorySummary> memorySummary(Ref ref) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.getMemorySummary();
}

@riverpod
Future<Memory> memoryDetail(Ref ref, String id) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.getMemoryById(id);
}

@riverpod
Future<List<Memory>> groupMemories(Ref ref, String groupId) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.getGroupMemories(groupId);
}
