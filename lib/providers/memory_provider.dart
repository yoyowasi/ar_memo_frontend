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

class NearbySearchParams {
  final double latitude;
  final double longitude;
  final double radius;
  NearbySearchParams({required this.latitude, required this.longitude, required this.radius});
}

@riverpod
Future<List<Memory>> nearbyMemories(Ref ref, NearbySearchParams params) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.searchNearby(
    latitude: params.latitude,
    longitude: params.longitude,
    radius: params.radius,
  );
}

class MapViewSearchParams {
  final double swLat;
  final double swLng;
  final double neLat;
  final double neLng;
  final double centerLat;
  final double centerLng;
  final int limit;
  MapViewSearchParams({
    required this.swLat,
    required this.swLng,
    required this.neLat,
    required this.neLng,
    required this.centerLat,
    required this.centerLng,
    required this.limit,
  });
}

@riverpod
Future<List<Memory>> mapViewMemories(Ref ref, MapViewSearchParams params) async {
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
}
