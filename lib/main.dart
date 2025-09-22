import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 임시 홈 화면 (나중에 실제 화면으로 교체)
import 'package:ar_memo_frontend/screens/auth_gate_screen.dart';

void main() async {
  // main 함수에서 비동기 작업을 수행하기 위해 필요
  WidgetsFlutterBinding.ensureInitialized();
  // .env 파일 로드
  await dotenv.load(fileName: ".env");

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 앱 시작 시 로그인 상태를 확인하는 화면으로 시작
      home: const AuthGateScreen(),
    );
  }
}