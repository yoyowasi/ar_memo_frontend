import 'package:kakao_map_sdk/kakao_map_sdk.dart'; // KakaoMap SDK import

import 'package:ar_memo_frontend/repositories/auth_repository.dart'; // AuthRepository import 추가
import 'package:ar_memo_frontend/providers/auth_provider.dart';
import 'package:ar_memo_frontend/screens/auth_gate_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('ko_KR', null);

  // --- SDK 초기화 변경 ---
  await KakaoMapSdk.instance.initialize(dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '');
  // ---------------------

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'AR 저널 앱',
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textColor,
          elevation: 0,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          iconTheme: IconThemeData(color: textColor),
          
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      home: const AuthGateScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}