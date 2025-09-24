import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/repositories/memory_repository.dart';

final memoryRepositoryProvider = Provider((ref) => MemoryRepository());

final myMemoriesProvider = FutureProvider<List<TripRecord>>((ref) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.getMyMemories();
});