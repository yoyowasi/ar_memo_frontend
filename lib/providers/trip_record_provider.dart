import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ar_memo_frontend/models/trip_record.dart';
import 'package:ar_memo_frontend/repositories/trip_record_repository.dart';

part 'trip_record_provider.g.dart'; // 코드 생성 파일

// Repository Provider
@riverpod
TripRecordRepository tripRecordRepository(TripRecordRepositoryRef ref) { // Ref 타입 수정
  return TripRecordRepository();
}

// TripRecord 목록 관리 Notifier Provider
@riverpod
class TripRecords extends _$TripRecords {
  @override
  Future<List<TripRecord>> build() async {
    // 초기 데이터 로드
    return ref.watch(tripRecordRepositoryProvider).getTripRecords();
  }

  // 기록 추가
  Future<void> addTripRecord({
    required String title, required DateTime date,
    String? content, String? groupId, List<String>? photoUrls,
    // --- 위치 파라미터 추가 ---
    double? latitude, double? longitude,
    // -------------------------
  }) async {
    final repository = ref.read(tripRecordRepositoryProvider);
    // 상태를 로딩 중으로 업데이트 (선택적)
    // state = const AsyncValue.loading();
    try {
      await repository.createTripRecord(
        title: title, date: date, content: content, groupId: groupId, photoUrls: photoUrls,
        latitude: latitude, longitude: longitude, // 전달
      );
      // 성공 시 상태 무효화하여 목록 새로고침
      ref.invalidateSelf();
    } catch (e, st) {
      // 실패 시 에러 상태로 업데이트
      state = AsyncValue.error(e, st);
      // 에러 다시 던지기 (UI에서 처리하도록)
      rethrow;
    }
  }

  // 기록 수정
  Future<void> updateTripRecord({
    required String id,
    String? title, DateTime? date, String? content,
    String? groupId, List<String>? photoUrls,
    // --- 위치 파라미터 추가 ---
    double? latitude, double? longitude,
    // -------------------------
  }) async {
    final repository = ref.read(tripRecordRepositoryProvider);
    // state = const AsyncValue.loading(); // 로딩 상태 (선택적)
    try {
      await repository.updateTripRecord(
        id: id, title: title, date: date, content: content, groupId: groupId, photoUrls: photoUrls,
        latitude: latitude, longitude: longitude, // 전달
      );
      // 목록 및 상세 정보 Provider 무효화
      ref.invalidateSelf();
      ref.invalidate(tripRecordDetailProvider(id));
    } catch (e, st) {
      state = AsyncValue.error(e, st); // 에러 상태
      rethrow;
    }
  }

  // 기록 삭제
  Future<void> deleteTripRecord(String id) async {
    final repository = ref.read(tripRecordRepositoryProvider);
    // state = const AsyncValue.loading(); // 로딩 상태 (선택적)
    try {
      await repository.deleteTripRecord(id);
      ref.invalidateSelf(); // 목록 갱신
      // 상세 정보 Provider도 무효화 (캐시 제거)
      ref.invalidate(tripRecordDetailProvider(id));
    } catch (e, st) {
      state = AsyncValue.error(e, st); // 에러 상태
      rethrow;
    }
  }
}

// 단일 TripRecord 상세 정보 Provider
@riverpod
Future<TripRecord> tripRecordDetail(TripRecordDetailRef ref, String id) async { // Ref 타입 수정
  final repo = ref.watch(tripRecordRepositoryProvider);
  return repo.getTripRecord(id);
}