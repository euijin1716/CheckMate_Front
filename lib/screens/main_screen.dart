// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/main.dart'; // authService 접근을 위해 main.dart 임포트
import 'package:health_app/screens/home_screen.dart';
import 'package:health_app/screens/status_screen.dart';
import 'package:health_app/screens/dr_chat_screen.dart';

// 설정 메뉴 아이템 정의
enum SettingsMenuItems { myAccount, appSettings, logout }

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 현재 선택된 탭 인덱스

  // 하단 내비게이션 바에 표시될 위젯 목록
  List<Widget> _buildWidgetOptions() => [
    HomeScreen(key: ValueKey('HomeScreen_$_selectedIndex')), // Key를 사용하여 상태 유지
    StatusScreen(key: ValueKey('StatusScreen_$_selectedIndex')), // Key를 사용하여 상태 유지
    DrChatScreen(),
  ];

  // 하단 내비게이션 바 아이템 탭 시 호출
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 로그아웃 확인 대화상자 및 처리
  Future<void> _performLogout() async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('로그아웃'),
          content: Text('정말로 로그아웃 하시겠습니까?'),
          actions: <Widget>[
            TextButton(child: Text('취소'), onPressed: () => Navigator.of(context).pop(false)),
            TextButton(
              child: Text('로그아웃', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (confirmLogout == true) {
      await authService.logout(); // AuthService를 통해 로그아웃
      if (!mounted) return; // 위젯이 dispose되지 않았는지 확인
      // 로그인 화면으로 이동하고 이전 라우트 모두 제거
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  // 설정 메뉴 아이템 선택 시 처리
  void _onSettingsMenuItemSelected(SettingsMenuItems item) {
    switch (item) {
      case SettingsMenuItems.myAccount:
        Navigator.pushNamed(context, '/my_account');
        break;
      case SettingsMenuItems.appSettings:
        Navigator.pushNamed(context, '/app_settings');
        break;
      case SettingsMenuItems.logout:
        _performLogout();
        break;
    }
  }

  // 현재 선택된 탭에 따라 앱바 제목 반환
  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return '홈';
      case 1:
        return '내 상태';
      case 2:
        return 'Dr. Chat';
      default:
        return '건강 관리 앱';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = _buildWidgetOptions(); // 위젯 목록 가져오기

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(_selectedIndex)), // 동적으로 앱바 제목 변경
        actions: <Widget>[
          // 설정 메뉴 팝업 버튼
          PopupMenuButton<SettingsMenuItems>(
            icon: Icon(Icons.settings_outlined),
            tooltip: '설정 더보기',
            onSelected: _onSettingsMenuItemSelected,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SettingsMenuItems>>[
              const PopupMenuItem<SettingsMenuItems>(value: SettingsMenuItems.myAccount, child: ListTile(leading: Icon(Icons.account_circle_outlined), title: Text('내 계정 정보'))),
              const PopupMenuItem<SettingsMenuItems>(value: SettingsMenuItems.appSettings, child: ListTile(leading: Icon(Icons.app_settings_alt_outlined), title: Text('앱 설정'))),
              const PopupMenuDivider(), // 구분선
              const PopupMenuItem<SettingsMenuItems>(value: SettingsMenuItems.logout, child: ListTile(leading: Icon(Icons.logout_outlined, color: Colors.redAccent), title: Text('로그아웃', style: TextStyle(color: Colors.redAccent)))),
            ],
          ),
        ],
      ),
      body: Center(child: widgetOptions.elementAt(_selectedIndex)), // 선택된 탭의 위젯 표시
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), activeIcon: Icon(Icons.fact_check), label: '내 상태'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Dr.Chat'),
        ],
        currentIndex: _selectedIndex, // 현재 선택된 인덱스
        selectedItemColor: Colors.teal[800], // 선택된 아이템 색상
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], // 선택되지 않은 아이템 색상 (테마에 따라)
        onTap: _onItemTapped, // 아이템 탭 시 호출
      ),
    );
  }
}
