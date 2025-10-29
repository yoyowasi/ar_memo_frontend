import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/models/memory_summary.dart';
import 'package:ar_memo_frontend/providers/api_service_provider.dart';
import 'package:ar_memo_frontend/repositories/memory_repository.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MemoryRepository(apiService);
});

final myMemoriesProvider = FutureProvider<List<Memory>>((ref) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.getMyMemories(limit: 12);
});

final memorySummaryProvider = FutureProvider<MemorySummary>((ref) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.getMemorySummary();
});

final memoryDetailProvider = FutureProvider.family<Memory, String>((ref, id) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.getMemoryById(id);
});

final groupMemoriesProvider = FutureProvider.family<List<Memory>, String>((ref, groupId) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.getGroupMemories(groupId);
});

class MemoryCreator extends AutoDisposeAsyncNotifier<Memory?> {
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

final memoryCreatorProvider =
    AutoDisposeAsyncNotifierProvider<MemoryCreator, Memory?>(MemoryCreator.new);
