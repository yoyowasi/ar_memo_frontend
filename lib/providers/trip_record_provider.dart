import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/repositories/trip_record_repository.dart';

// Repository 프로바이더
final tripRecordRepositoryProvider = Provider<TripRecordRepository>((ref) {
  return TripRecordRepository();
});

// 여행 기록 목록 상태를 관리하는 프로바이더
final tripRecordsProvider = AsyncNotifierProvider<TripRecordsNotifier, List<TripRecord>>(() {
  return TripRecordsNotifier();
});

class TripRecordsNotifier extends AsyncNotifier<List<TripRecord>> {
  late TripRecordRepository _repository;

  @override
  Future<List<TripRecord>> build() async {
    _repository = ref.watch(tripRecordRepositoryProvider);
    return _repository.getTripRecords();
  }

  // 기록 추가하기
  Future<void> addTripRecord({
    required String title,
    required DateTime date,
    String? content,
    String? groupId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final newRecord = await _repository.createTripRecord(
        title: title,
        date: date,
        content: content,
        groupId: groupId,
      );
      return [...(await future), newRecord];
    });
  }
}
