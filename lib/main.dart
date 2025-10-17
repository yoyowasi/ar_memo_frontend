import 'package:ar_memo_frontend/screens/splash_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:flutter/foundation.dart'; // ✅ kIsWeb 사용을 위해 추가
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart'; // import 문 추가

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('ko_KR', null);

  // ✅ 플랫폼(웹/앱)에 맞는 키로 카카오맵 SDK를 한 번만 초기화합니다.
  String kakaoMapKey = kIsWeb
      ? dotenv.env['KAKAO_MAP_JAVASCRIPT_KEY'] ?? ''
      : dotenv.env['KAKAO_MAP_NATIVE_APP_KEY'] ?? '';
  AuthRepository.initialize(appKey: kakaoMapKey);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Memo',
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}