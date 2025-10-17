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
    // build 메서드는 초기 데이터를 가져옵니다.
    return ref.watch(tripRecordRepositoryProvider).getTripRecords();
  }

  // 기록을 추가하는 메서드
  Future<void> addTripRecord({
    required String title,
    required DateTime date,
    String? content,
    String? groupId,
    List<String>? photoUrls,
  }) async {
    final repository = ref.read(tripRecordRepositoryProvider);
    await repository.createTripRecord(
      title: title,
      date: date,
      content: content,
      groupId: groupId,
      photoUrls: photoUrls,
    );
    // !!!!!!!!!!!! 수정된 부분 !!!!!!!!!!!!
    // 프로바이더를 다시 빌드(fetch)하기 위해 자신을 무효화합니다.
    ref.invalidateSelf();
  }

  // 기록을 수정하는 메서드
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
    // !!!!!!!!!!!! 수정된 부분 !!!!!!!!!!!!
    ref.invalidateSelf();
  }

  // 기록을 삭제하는 메서드
  Future<void> deleteTripRecord(String id) async {
    final repository = ref.read(tripRecordRepositoryProvider);
    await repository.deleteTripRecord(id);
    // !!!!!!!!!!!! 수정된 부분 !!!!!!!!!!!!
    ref.invalidateSelf();
  }
}

@riverpod
Future<TripRecord> tripRecordDetail(Ref ref, String id) async {
  final repo = ref.watch(tripRecordRepositoryProvider);
  return repo.getTripRecord(id);
}