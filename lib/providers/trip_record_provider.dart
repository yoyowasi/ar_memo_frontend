import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/repositories/trip_record_repository.dart';
import 'package:flutter_riverpod/legacy.dart';

// Repository 프로바이더
final tripRecordRepositoryProvider = Provider<TripRecordRepository>((ref) {
  return TripRecordRepository();
});

// 여행 기록 목록 상태를 관리하는 프로바이더
final tripRecordsProvider = StateNotifierProvider<TripRecordsNotifier, AsyncValue<List<TripRecord>>>((ref) {
  final repository = ref.watch(tripRecordRepositoryProvider);
  return TripRecordsNotifier(repository);
});

class TripRecordsNotifier extends StateNotifier<AsyncValue<List<TripRecord>>> {
  final TripRecordRepository _repository;

  TripRecordsNotifier(this._repository) : super(const AsyncValue.loading()) {
    // 프로바이더가 생성될 때 첫 데이터를 로드합니다.
    fetchTripRecords();
  }

  // ✨ 이 메서드를 public으로 유지하여 외부(UI)에서 호출할 수 있도록 합니다.
  // 기록 목록을 새로고침하는 함수
  Future<void> fetchTripRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getTripRecords();
      state = AsyncValue.data(records);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // 기록 추가하기
  Future<void> addTripRecord({
    required String title,
    required DateTime date,
    String? content,
    String? groupId,
  }) async {
    try {
      final newRecord = await _repository.createTripRecord(
        title: title,
        date: date,
        content: content,
        groupId: groupId,
      );

      // 기존 목록을 다시 불러와서 상태를 최신으로 업데이트합니다.
      await fetchTripRecords();

    } catch (e) {
      // 에러 처리를 위해 state를 에러 상태로 변경할 수도 있습니다.
      // 여기서는 간단히 print만 합니다.
      print('Failed to add trip record: $e');
    }
  }
}