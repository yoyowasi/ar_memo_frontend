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

  // ✅ 업로드 파일 경로는 정적 서빙이므로 /api를 붙이지 않는다.
  if (url.startsWith('/uploads/')) {
    return '$apiOrigin$url';
  }

  // 그 외 API 경로는 /api 붙이기
  if (url.startsWith('/')) {
    return '$apiBase$url';
  }

  return '$apiBase/$url';
}
