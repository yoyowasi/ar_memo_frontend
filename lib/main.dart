import 'package:ar_memo_frontend/screens/splash_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
// --- import 수정 ---
// import 'package:kakao_map_plugin/kakao_map_plugin.dart'; // <- 삭제
import 'package:kakao_map_plugin/kakao_map_plugin.dart'; // <- 공식 SDK import
// -----------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('ko_KR', null);

  // --- kakao_map_plugin 초기화 ---
  AuthRepository.initialize(appKey: dotenv.env['KAKAO_MAP_JAVASCRIPT_KEY'] ?? '');
  // ---------------------------

  // --- AuthRepository.initialize 제거 ---
  // AuthRepository.initialize(appKey: kakaoMapKey); // <- 삭제
  // ----------------------------------

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
        appBarTheme: const AppBarTheme( // 테마 일관성
          backgroundColor: Colors.white,
          foregroundColor: textColor,
          elevation: 0,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          iconTheme: IconThemeData(color: textColor),

        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}