import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// kakao_map_plugin 패키지에서 AuthRepository를 가져오는 것이 핵심!
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:ar_memo_frontend/screens/splash_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('ko_KR', null);

  // 카카오맵 SDK 초기화 (웹/모바일 플랫폼에 따라 다른 키 사용)
  final appKey = kIsWeb
      ? dotenv.env['KAKAO_MAP_JAVASCRIPT_KEY']
      : (Platform.isAndroid || Platform.isIOS)
          ? dotenv.env['KAKAO_MAP_NATIVE_APP_KEY']
          : dotenv.env['KAKAO_MAP_JAVASCRIPT_KEY'];

  AuthRepository.initialize(appKey: appKey ?? '');

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