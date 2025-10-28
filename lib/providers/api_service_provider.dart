import 'package:ar_memo_frontend/services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  throw UnimplementedError('apiServiceProvider must be overridden');
});

Future<ApiService> createApiService() async {
  final prefs = await SharedPreferences.getInstance();
  final baseUrl = dotenv.env['API_BASE_URL']?.trim();
  final resolvedBaseUrl =
      (baseUrl != null && baseUrl.isNotEmpty) ? baseUrl : 'http://localhost:3000';

  return ApiService(
    client: http.Client(),
    baseUrl: resolvedBaseUrl,
    sharedPreferences: prefs,
  );
}
