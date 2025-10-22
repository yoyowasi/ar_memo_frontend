import 'package:ar_memo_frontend/screens/splash_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
// kakao_map_sdk.dart 가 아닌 kakao_sdk.dart 를 import 해야 할 수 있습니다.
// KakaoSdk.init 이 정의된 파일을 정확히 import 해야 합니다.
// 만약 kakao_map_sdk 패키지 내 다른 파일에 있다면 해당 파일을 import 하세요.
// 일반적으로는 최상위 kakao_map_sdk.dart 를 import 합니다.
// Removed KakaoSdk.init and javascriptAppKey logic
// The native app keys configured in AndroidManifest.xml and Info.plist should be sufficient.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // .env 파일 로드
  await initializeDateFormatting('ko_KR', null);

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