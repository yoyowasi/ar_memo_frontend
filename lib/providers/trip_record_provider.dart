// lib/providers/trip_record_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/providers/api_service_provider.dart';
import 'package:ar_memo_frontend/providers/memory_provider.dart';
import 'package:ar_memo_frontend/repositories/trip_record_repository.dart';

part 'trip_record_provider.g.dart';

@riverpod
TripRecordRepository tripRecordRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TripRecordRepository(apiService);
}

@riverpod
class TripRecords extends _$TripRecords {
  @override
  Future<List<TripRecord>> build() async {
    return ref.watch(tripRecordRepositoryProvider).getTripRecords();
  }

  Future addTripRecord({
    required String title,
    required DateTime date,
    String? content,
    String? groupId,
    List<String>? photoUrls,
    double? latitude,
    double? longitude,
  }) async {
    final repository = ref.read(tripRecordRepositoryProvider);
    try {
      await repository.createTripRecord(
        title: title,
        date: date,
        content: content,
        groupId: groupId,
        photoUrls: photoUrls,
        latitude: latitude,
        longitude: longitude,
      );
      ref.invalidateSelf();
      ref.invalidate(memorySummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future updateTripRecord({
    required String id,
    String? title,
    DateTime? date,
    String? content,
    String? groupId,
    bool isGroupIdUpdated = false,
    List<String>? photoUrls,
    double? latitude,
    double? longitude,
  }) async {
    final repository = ref.read(tripRecordRepositoryProvider);
    try {
      await repository.updateTripRecord(
        id: id,
        title: title,
        date: date,
        content: content,
        groupId: groupId,
        isGroupIdUpdated: isGroupIdUpdated,
        photoUrls: photoUrls,
        latitude: latitude,
        longitude: longitude,
      );
      ref.invalidateSelf();
      ref.invalidate(tripRecordDetailProvider(id));
      ref.invalidate(memorySummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // 🟢 개선된 deleteTripRecord 메서드
  Future deleteTripRecord(String id) async {
    final repository = ref.read(tripRecordRepositoryProvider);
    try {
      // 낙관적 업데이트: UI를 먼저 업데이트
      final previousState = state;
      state = await AsyncValue.guard(() async {
        final currentRecords = await future;
        return currentRecords.where((record) => record.id != id).toList();
      });

      try {
        // 실제 서버 삭제
        await repository.deleteTripRecord(id);

        // 관련 Provider 무효화
        ref.invalidate(tripRecordDetailProvider(id));
        ref.invalidate(memorySummaryProvider);
      } catch (e) {
        // 삭제 실패 시 이전 상태로 롤백
        state = previousState;
        rethrow;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

@riverpod
Future<TripRecord> tripRecordDetail(Ref ref, String id) async {
  final repo = ref.watch(tripRecordRepositoryProvider);
  return repo.getTripRecord(id);
}
