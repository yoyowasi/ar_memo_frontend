import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/repositories/trip_record_repository.dart';

part 'trip_record_provider.g.dart';

@riverpod
TripRecordRepository tripRecordRepository(Ref ref) {
  return TripRecordRepository();
}

@riverpod
class TripRecords extends _$TripRecords {
  @override
  Future<List<TripRecord>> build() async {
    return ref.watch(tripRecordRepositoryProvider).getTripRecords();
  }

  Future<void> addTripRecord({
    required String title,
    required DateTime date,
    String? content,
    String? groupId,
    List<String>? photoUrls,
  }) async {
    final repository = ref.read(tripRecordRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      await repository.createTripRecord(
        title: title,
        date: date,
        content: content,
        groupId: groupId,
        photoUrls: photoUrls,
      );
      ref.invalidate(tripRecordsProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> fetchTripRecords() async {
    ref.invalidate(tripRecordsProvider);
  }
}
