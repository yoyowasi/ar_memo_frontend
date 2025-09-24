import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/models/memory_summary.dart';
import 'package:ar_memo_frontend/repositories/memory_repository.dart';

final memoryRepositoryProvider = Provider((ref) => MemoryRepository());

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

typedef NearbySearchParams = ({double latitude, double longitude, double radius});

final nearbyMemoriesProvider = FutureProvider.family<List<Memory>, NearbySearchParams>((ref, params) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.searchNearby(
    latitude: params.latitude,
    longitude: params.longitude,
    radius: params.radius,
  );
});

typedef MapViewSearchParams = ({
  double swLat,
  double swLng,
  double neLat,
  double neLng,
  double centerLat,
  double centerLng,
  int limit,
});

final mapViewMemoriesProvider = FutureProvider.family<List<Memory>, MapViewSearchParams>((ref, params) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.searchInView(
    swLat: params.swLat,
    swLng: params.swLng,
    neLat: params.neLat,
    neLng: params.neLng,
    centerLat: params.centerLat,
    centerLng: params.centerLng,
    limit: params.limit,
  );
});

