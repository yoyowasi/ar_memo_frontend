import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/repositories/trip_record_repository.dart';

final tripRecordRepositoryProvider = Provider<TripRecordRepository>((ref) {
  return TripRecordRepository();
});

final tripRecordsProvider = StateNotifierProvider<TripRecordsNotifier, AsyncValue<List<TripRecord>>>((ref) {
  final repository = ref.watch(tripRecordRepositoryProvider);
  return TripRecordsNotifier(repository);
});

class TripRecordsNotifier extends StateNotifier<AsyncValue<List<TripRecord>>> {
  final TripRecordRepository _repository;

  TripRecordsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchTripRecords();
  }

  Future<void> fetchTripRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getTripRecords();
      state = AsyncValue.data(records);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTripRecord({
    required String title,
    required DateTime date,
    String? content,
    String? groupId,
  }) async {
    try {
      await _repository.createTripRecord(
        title: title,
        date: date,
        content: content,
        groupId: groupId,
      );
      await fetchTripRecords();
    } catch (e) {
      print('Failed to add trip record: $e');
      // Re-throw the error to be caught in the UI
      throw Exception('Failed to add trip record');
    }
  }
}