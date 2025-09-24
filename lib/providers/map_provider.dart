import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/services/kakao_map_service.dart';

final kakaoMapServiceProvider = Provider<KakaoMapService>((ref) {
  return KakaoMapService();
});
