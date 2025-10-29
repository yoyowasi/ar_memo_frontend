import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Converts a potentially relative [url] to an absolute URL using the
/// `API_BASE_URL` defined in the `.env` file.
///
/// When [url] is already absolute it is returned as-is. If no base URL can be
/// resolved the function falls back to `http://localhost:3000` to keep the
/// previous behaviour in development environments.
String toAbsoluteUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return trimmed;
  }

  final envBase = dotenv.env['API_BASE_URL']?.trim();
  final baseUrl = (envBase != null && envBase.isNotEmpty)
      ? envBase
      : 'http://localhost:3000';
  final baseUri = Uri.parse(baseUrl);
  return baseUri.resolve(trimmed).toString();
}
