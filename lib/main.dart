import 'package:flutter/material.dart';
import 'package:ar_memo_frontend/screens/home_screen.dart'; // 지도 화면이 될 홈 화면
import 'package:ar_memo_frontend/screens/my_page_screen.dart';
import 'package:ar_memo_frontend/theme/colors.dart';

/// 앱 실행 진입점
void main() {
  runApp(const MyApp());
}

/// 전체 앱을 감싸는 최상위 위젯
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AR Memo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(), // 시작 화면을 MainScreen으로 지정
    );
  }
}

/// AR 화면을 위한 임시 Placeholder 위젯
class ARScreen extends StatelessWidget {
  const ARScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'AR 카메라 화면 (구현 예정)',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

/// 하단 네비게이션을 가진 메인 화면
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 네비게이션 탭에 맞춰 위젯 변경
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),    // 0: 지도
    ARScreen(),      // 1: AR
    MyPageScreen(),  // 2: 프로필
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: surfaceColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: surfaceColor,
          elevation: 0,
          selectedItemColor: textColor,
          unselectedItemColor: subTextColor,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: '지도',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'AR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '프로필',
            ),
          ],
        ),
      ),
    );
  }
}
