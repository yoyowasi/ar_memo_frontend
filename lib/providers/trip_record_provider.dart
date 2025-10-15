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
    // build method fetches the initial data
    return ref.watch(tripRecordRepositoryProvider).getTripRecords();
  }

  // Method to add a record
  Future<void> addTripRecord({
    required String title,
    required DateTime date,
    String? content,
    String? groupId,
    List<String>? photoUrls,
  }) async {
    final repository = ref.read(tripRecordRepositoryProvider);
    // Perform the action
    await repository.createTripRecord(
      title: title,
      date: date,
      content: content,
      groupId: groupId,
      photoUrls: photoUrls,
    );
    // Invalidate the provider to re-fetch the list
    ref.invalidate(tripRecordsProvider);
  }

  // Method to update a record
  Future<void> updateTripRecord({
    required String id,
    String? title,
    DateTime? date,
    String? content,
    String? groupId,
    List<String>? photoUrls,
  }) async {
    final repository = ref.read(tripRecordRepositoryProvider);
    await repository.updateTripRecord(
      id: id,
      title: title,
      date: date,
      content: content,
      groupId: groupId,
      photoUrls: photoUrls,
    );
    ref.invalidate(tripRecordsProvider);
  }

  // Method to delete a record
  Future<void> deleteTripRecord(String id) async {
    final repository = ref.read(tripRecordRepositoryProvider);
    await repository.deleteTripRecord(id);
    ref.invalidate(tripRecordsProvider);
  }
}

@riverpod
Future<TripRecord> tripRecordDetail(Ref ref, String id) async {
  final repo = ref.watch(tripRecordRepositoryProvider);
  return repo.getTripRecord(id);
}