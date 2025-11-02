import 'package:flutter_dotenv/flutter_dotenv.dart';

final String _envBaseUrl = dotenv.env['API_BASE_URL']?.trim() ?? '';
final String _rawBaseUrl =
_envBaseUrl.isNotEmpty ? _envBaseUrl : 'http://localhost:3000';
final String apiBase =
_rawBaseUrl.endsWith('/') ? _rawBaseUrl.substring(0, _rawBaseUrl.length - 1) : _rawBaseUrl;

// origin 부분만 추출 (ex: http://localhost:3000)
final String apiOrigin = apiBase.replaceAll(RegExp(r'/api/?$'), '');
