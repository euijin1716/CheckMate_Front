// lib/screens/app_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_app/main.dart'; // themeNotifier 접근을 위해 main.dart 임포트

class AppSettingsScreen extends StatefulWidget {
  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _notificationsEnabled = true; // 알림 활성화 여부
  ThemeMode _selectedThemeMode = ThemeMode.system; // 선택된 테마 모드

  @override
  void initState() {
    super.initState();
    _loadSettings(); // 초기 설정 로드
  }

  // SharedPreferences에서 설정 값 로드
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return; // 위젯이 dispose되지 않았는지 확인
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true; // 알림 설정 로드 (기본값 true)
      String? themeModeName = prefs.getString('themeMode'); // 테마 모드 로드
      if (themeModeName == 'dark') {
        _selectedThemeMode = ThemeMode.dark;
      } else if (themeModeName == 'light') {
        _selectedThemeMode = ThemeMode.light;
      } else {
        _selectedThemeMode = ThemeMode.system;
      }
    });
  }

  // 알림 설정 변경 및 저장
  Future<void> _setNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value); // SharedPreferences에 저장
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('알림 설정이 ${value ? "활성화" : "비활성화"}되었습니다.')));
  }

  // 테마 선택 다이얼로그 표시
  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('앱 테마 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // 라이트 모드 선택
              RadioListTile<ThemeMode>(
                title: const Text('라이트 모드'),
                value: ThemeMode.light,
                groupValue: _selectedThemeMode,
                onChanged: (ThemeMode? value) async {
                  if (value != null) {
                    setDialogState(() => _selectedThemeMode = value);
                    themeNotifier.value = value; // 전역 themeNotifier 업데이트
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('themeMode', value.name); // SharedPreferences에 저장
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                  }
                },
              ),
              // 다크 모드 선택
              RadioListTile<ThemeMode>(
                title: const Text('다크 모드'),
                value: ThemeMode.dark,
                groupValue: _selectedThemeMode,
                onChanged: (ThemeMode? value) async {
                  if (value != null) {
                    setDialogState(() => _selectedThemeMode = value);
                    themeNotifier.value = value;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('themeMode', value.name);
                    Navigator.of(context).pop();
                  }
                },
              ),
              // 시스템 설정 따름 선택
              RadioListTile<ThemeMode>(
                title: const Text('시스템 설정 따름'),
                value: ThemeMode.system,
                groupValue: _selectedThemeMode,
                onChanged: (ThemeMode? value) async {
                  if (value != null) {
                    setDialogState(() => _selectedThemeMode = value);
                    themeNotifier.value = value;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('themeMode', value.name);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('앱 설정')),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          // 푸시 알림 설정 스위치
          SwitchListTile(secondary: Icon(Icons.notifications_outlined), title: Text('푸시 알림 받기'), value: _notificationsEnabled, onChanged: _setNotificationPreference),
          Divider(),
          // 앱 테마 설정 항목
          ListTile(
            leading: Icon(Icons.color_lens_outlined),
            title: Text('앱 테마 설정'),
            subtitle: Text(_selectedThemeMode == ThemeMode.light ? '라이트 모드' : (_selectedThemeMode == ThemeMode.dark ? '다크 모드' : '시스템 설정 따름')),
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: _showThemeDialog,
          ),
          Divider(),
          // 앱 버전 정보
          ListTile(leading: Icon(Icons.info_outline), title: Text('앱 버전'), subtitle: Text('1.0.1 (개선됨)')),
          Divider(),
          // 서비스 이용 약관 링크
          ListTile(leading: Icon(Icons.description_outlined), title: Text('서비스 이용 약관'), trailing: Icon(Icons.keyboard_arrow_right), onTap: () => Navigator.pushNamed(context, '/terms_of_service')),
          Divider(),
          // 개인정보 처리방침 링크
          ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('개인정보 처리방침'), trailing: Icon(Icons.keyboard_arrow_right), onTap: () => Navigator.pushNamed(context, '/privacy_policy')),
        ],
      ),
    );
  }
}
