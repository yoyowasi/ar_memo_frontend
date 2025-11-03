import 'package:ar_memo_frontend/providers/api_service_provider.dart';
import 'package:ar_memo_frontend/screens/splash_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // .env 파일 로드
    await dotenv.load(fileName: ".env");

    // 한국어 날짜 형식 초기화
    await initializeDateFormatting('ko_KR', null);

    // 카카오 맵 네이티브 앱 키 불러오기
    final kakaoNativeAppKey = dotenv.env['KAKAO_MAP_NATIVE_APP_KEY'];

    if (kakaoNativeAppKey == null || kakaoNativeAppKey.isEmpty) {
      throw Exception(
          "KAKAO_MAP_NATIVE_APP_KEY not found in .env file. "
              "Please check your .env file."
      );
    }

    // 카카오 맵 SDK 초기화 (v1.2.1에서는 동기 메서드)
    KakaoMapSdk.instance.initialize(kakaoNativeAppKey);

    // API 서비스 초기화
    final apiService = await createApiService();

    runApp(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(apiService),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    // 초기화 실패 시 에러 처리
    debugPrint('앱 초기화 실패: $e');

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '앱 초기화 중 오류가 발생했습니다',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlaceNote',
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
        fontFamily: 'Pretendard',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textColor,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          iconTheme: IconThemeData(color: textColor),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
