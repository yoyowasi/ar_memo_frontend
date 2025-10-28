import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/models/memory_summary.dart';
import 'package:ar_memo_frontend/repositories/memory_repository.dart';
import 'package:ar_memo_frontend/providers/api_service_provider.dart';

part 'memory_provider.g.dart';

@riverpod
MemoryRepository memoryRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MemoryRepository(apiService);
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

@riverpod
class MemoryCreator extends _$MemoryCreator {
  @override
  FutureOr<Memory?> build() {
    return null;
  }

  Future<Memory> createMemory({
    required double latitude,
    required double longitude,
    String? text,
    List<String>? tags,
    String? groupId,
    String? visibility,
    String? photoUrl,
    String? audioUrl,
    List<double>? anchor,
  }) async {
    final repository = ref.read(memoryRepositoryProvider);
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final memory = await repository.createMemory(
        latitude: latitude,
        longitude: longitude,
        text: text,
        tags: tags,
        groupId: groupId,
        visibility: visibility,
        photoUrl: photoUrl,
        audioUrl: audioUrl,
        anchor: anchor,
      );

      ref.invalidate(myMemoriesProvider);
      ref.invalidate(memorySummaryProvider);
      return memory;
    });

    state = result;
    return result.requireValue;
  }
}