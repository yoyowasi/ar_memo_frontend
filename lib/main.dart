import 'package:ar_memo_frontend/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:intl/date_symbol_data_local.dart';
// import 'package:kakao_map_plugin/kakao_map_plugin.dart'; // 이 import도 삭제하거나 주석 처리하세요.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('ko_KR', null);

  // ⚠️ 아래 라인이 남아있다면 반드시 삭제하거나 주석 처리해야 합니다. ⚠️
  // AuthRepository.initialize(appKey: dotenv.env['KAKAO_MAP_JAVASCRIPT_KEY'] ?? '');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// 이하 MyApp 클래스는 그대로 유지
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