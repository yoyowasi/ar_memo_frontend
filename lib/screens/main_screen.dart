import 'package:flutter/material.dart';
import 'package:ar_memo_frontend/screens/home_screen.dart'; // 홈(지도) 스크린
import 'package:ar_memo_frontend/screens/ar_viewer_screen.dart'; // AR 뷰어 스크린
import 'package:ar_memo_frontend/screens/trip_record_list_screen.dart'; // 여행 기록(일기) 스크린
import 'package:ar_memo_frontend/screens/my_page_screen.dart'; // 프로필 스크린
import 'package:ar_memo_frontend/theme/colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 탭 변경: 홈(지도), AR 뷰어, 여행 기록(일기), 프로필
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ArViewerScreen(),
    TripRecordListScreen(),
    MyPageScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // 화면 전환 시 상태 유지를 위해 IndexedStack 사용
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        // 시안 디자인과 유사하게 약간의 그림자 및 상단 경계선 추가
        decoration: BoxDecoration(
          color: surfaceColor, // 흰색 배경
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 0.5)), // 연한 회색 경계선
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2), // 위쪽으로 그림자
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // 항상 레이블 표시
          backgroundColor: surfaceColor, // 배경색
          elevation: 0, // 컨테이너에서 그림자를 처리하므로 네비게이션 자체 elevation은 0
          selectedItemColor: primaryColor, // 선택된 아이템 색상 (주황)
          unselectedItemColor: subTextColor, // 선택되지 않은 아이템 색상 (회색)
          selectedFontSize: 12, // 선택된 폰트 크기
          unselectedFontSize: 12, // 선택되지 않은 폰트 크기
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            // 홈 (지도) 탭
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: '홈',
            ),
            // AR 뷰어 탭
            BottomNavigationBarItem(
              icon: Icon(Icons.view_in_ar_outlined), // AR 아이콘 사용
              activeIcon: Icon(Icons.view_in_ar),
              label: 'AR', // 시안대로 'AR'
            ),
            // 여행 기록 (일기 리스트) 탭
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined), // 문서/일기 아이콘 사용
              activeIcon: Icon(Icons.article),
              label: '일기', // 시안대로 '일기'
            ),
            // 프로필 탭
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '프로필', // 시안대로 '프로필'
            ),
          ],
        ),
      ),
    );
  }
}