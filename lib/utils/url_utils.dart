import 'package:flutter_dotenv/flutter_dotenv.dart';

final String _envBaseUrl = dotenv.env['API_BASE_URL']?.trim() ?? '';
final String _rawBaseUrl =
_envBaseUrl.isNotEmpty ? _envBaseUrl : 'http://localhost:3000';
final String apiBase =
_rawBaseUrl.endsWith('/') ? _rawBaseUrl.substring(0, _rawBaseUrl.length - 1) : _rawBaseUrl;

// origin 부분만 추출 (ex: http://localhost:3000)
final String apiOrigin = apiBase.replaceAll(RegExp(r'/api/?$'), '');

String toAbsoluteUrl(String url) {
  if (url.isEmpty) return url;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;

  // ✅ 삭제: '/uploads/' 특별 취급 로직이 제거되었습니다.

  // 그 외 API 경로는 /api 붙이기
  if (url.startsWith('/')) {
    // .env 파일의 API_BASE_URL (예: http://서버주소)와
    // url (예: /api/uploads/image.jpg 또는 /api/memories)이 합쳐집니다.
    return '$apiBase$url';
  }

  return '$apiBase/$url';
}