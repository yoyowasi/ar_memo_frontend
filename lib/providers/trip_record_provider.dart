// lib/providers/trip_record_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/providers/api_service_provider.dart';
import 'package:ar_memo_frontend/repositories/trip_record_repository.dart';

final tripRecordRepositoryProvider = Provider<TripRecordRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TripRecordRepository(apiService);
});

class TripRecords extends AutoDisposeAsyncNotifier<List<TripRecord>> {
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateTripRecord({
    required String id,
    String? title,
    DateTime? date,
    String? content,
    String? groupId,
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
        photoUrls: photoUrls,
        latitude: latitude,
        longitude: longitude,
      );
      ref.invalidateSelf();
      ref.invalidate(tripRecordDetailProvider(id));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteTripRecord(String id) async {
    final repository = ref.read(tripRecordRepositoryProvider);
    try {
      await repository.deleteTripRecord(id);
      ref.invalidateSelf();
      ref.invalidate(tripRecordDetailProvider(id));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final tripRecordsProvider = AutoDisposeAsyncNotifierProvider<TripRecords, List<TripRecord>>(
  TripRecords.new,
);

final tripRecordDetailProvider = FutureProvider.family<TripRecord, String>((ref, id) async {
  final repo = ref.watch(tripRecordRepositoryProvider);
  return repo.getTripRecord(id);
});
