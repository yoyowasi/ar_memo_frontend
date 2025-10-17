import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ar_memo_frontend/services/kakao_map_service.dart';

part 'map_provider.g.dart';

@riverpod
KakaoMapService kakaoMapService(Ref ref) {
  return KakaoMapService();
}