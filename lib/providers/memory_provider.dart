import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ar_memo_frontend/models/memory.dart';
import 'package:ar_memo_frontend/models/memory_summary.dart';
import 'package:ar_memo_frontend/repositories/memory_repository.dart';

// MemoryRepository 인스턴스를 제공하는 Provider
final memoryRepositoryProvider = Provider((ref) => MemoryRepository());

// 나의 모든 Memory 목록을 가져오는 Provider (최대 12개)
final myMemoriesProvider = FutureProvider<List<Memory>>((ref) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.getMyMemories(limit: 12);
});

// Memory 요약 정보를 가져오는 Provider
final memorySummaryProvider = FutureProvider<MemorySummary>((ref) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.getMemorySummary();
});

// 특정 ID를 가진 Memory의 상세 정보를 가져오는 Provider
final memoryDetailProvider = FutureProvider.family<Memory, String>((ref, id) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.getMemoryById(id);
});

// 주변 Memory 검색을 위한 파라미터 타입을 정의
typedef NearbySearchParams = ({double latitude, double longitude, double radius});

// 특정 위치 주변의 Memory 목록을 검색하는 Provider
final nearbyMemoriesProvider = FutureProvider.family<List<Memory>, NearbySearchParams>((ref, params) async {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.searchNearby(
    latitude: params.latitude,
    longitude: params.longitude,
    radius: params.radius,
  );
});

// 지도 뷰 내의 Memory 검색을 위한 파라미터 타입을 정의
typedef MapViewSearchParams = ({
  double swLat,
  double swLng,
  double neLat,
  double neLng,
  double centerLat,
  double centerLng,
  int limit,
});

// 현재 지도 화면 영역 내의 Memory 목록을 검색하는 Provider
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