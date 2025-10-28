// lib/providers/trip_record_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

@riverpod
Future<TripRecord> tripRecordDetail(Ref ref, String id) async {
  final repo = ref.watch(tripRecordRepositoryProvider);
  return repo.getTripRecord(id);
}
