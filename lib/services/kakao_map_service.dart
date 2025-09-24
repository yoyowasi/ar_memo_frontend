import 'package:flutter_dotenv/flutter_dotenv.dart';

class KakaoMapService {
  KakaoMapService._internal();

  static final KakaoMapService _instance = KakaoMapService._internal();
  factory KakaoMapService() => _instance;

  String get javascriptKey => dotenv.env['KAKAO_MAP_JAVASCRIPT_KEY'] ?? '';
  String get nativeAppKey => dotenv.env['KAKAO_MAP_NATIVE_APP_KEY'] ?? '';
  String get restApiKey => dotenv.env['KAKAO_REST_API_KEY'] ?? '';

  bool get isConfigured => javascriptKey.isNotEmpty || nativeAppKey.isNotEmpty;
}
