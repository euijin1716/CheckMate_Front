// lib/screens/my_account_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/main.dart'; // authService 접근을 위해 main.dart 임포트

class MyAccountScreen extends StatefulWidget {
  @override
  _MyAccountScreenState createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> { // <-- 이 부분을 수정했습니다.
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  final _nameFormKey = GlobalKey<FormState>(); // 이름 변경 폼의 GlobalKey
  final _passwordFormKey = GlobalKey<FormState>(); // 비밀번호 변경 폼의 GlobalKey

  @override
  void initState() {
    super.initState();
    _nameController.text = authService.getUserName(); // 초기 사용자 이름 설정
  }

  // 사용자 이름 업데이트 처리
  Future<void> _updateUserName() async {
    if (_nameFormKey.currentState!.validate()) {
      bool success = await authService.updateUserName(_nameController.text.trim()); //
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이름이 변경되었습니다.'), backgroundColor: Colors.green));
        setState(() {}); // UI 업데이트를 위해 setState 호출
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이름 변경에 실패했습니다.'), backgroundColor: Colors.red));
      }
    }
  }

  // 비밀번호 변경 처리
  Future<void> _changePassword() async {
    if (_passwordFormKey.currentState!.validate()) {
      bool success = await authService.changePassword(_currentPasswordController.text, _newPasswordController.text); //
      if (success && mounted) {
        // 성공 시 입력 필드 초기화 및 키보드 숨기기
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('비밀번호가 변경되었습니다.'), backgroundColor: Colors.green));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('현재 비밀번호가 일치하지 않습니다.'), backgroundColor: Colors.red));
      }
    }
  }

  // 회원 탈퇴 확인 대화상자 표시 및 처리
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('회원 탈퇴'),
        content: Text('정말로 회원 탈퇴를 진행하시겠습니까? 이 작업은 되돌릴 수 없으며, 모든 데이터가 삭제됩니다.'),
        actions: <Widget>[
          TextButton(child: Text('취소'), onPressed: () => Navigator.of(context).pop()),
          TextButton(
            child: Text('탈퇴하기', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(context).pop(); // 대화상자 닫기
              bool success = await authService.deleteAccount(); // AuthService를 통해 계정 삭제
              if (success && mounted) {
                // 성공 시 로그인 화면으로 이동하고 이전 라우트 모두 제거
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('계정이 성공적으로 삭제되었습니다.')));
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('계정 삭제에 실패했습니다.')));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('내 계정 정보')),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          // 계정 정보 섹션
          Text('계정 정보', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 8),
          ListTile(leading: Icon(Icons.email_outlined), title: Text('이메일'), subtitle: Text(authService.getUserEmail())), //
          Divider(),
          // 이름 변경 폼
          Form(
            key: _nameFormKey,
            child: ListTile(
              leading: Icon(Icons.person_outline),
              title: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: '이름'),
                validator: (value) => (value == null || value.isEmpty) ? '이름을 입력해주세요.' : null,
              ),
              trailing: IconButton(icon: Icon(Icons.save_outlined), onPressed: _updateUserName, tooltip: '이름 저장'),
            ),
          ),
          Divider(),
          SizedBox(height: 20),
          // 비밀번호 변경 섹션
          Text('비밀번호 변경', style: Theme.of(context).textTheme.titleLarge),
          Form(
            key: _passwordFormKey,
            child: Column(
              children: [
                TextFormField(controller: _currentPasswordController, decoration: InputDecoration(labelText: '현재 비밀번호', prefixIcon: Icon(Icons.lock_open_outlined)), obscureText: true, validator: (value) => (value == null || value.isEmpty) ? '현재 비밀번호를 입력해주세요.' : null),
                SizedBox(height: 8),
                TextFormField(controller: _newPasswordController, decoration: InputDecoration(labelText: '새 비밀번호', prefixIcon: Icon(Icons.lock_outline)), obscureText: true, validator: (value) {
                  if (value == null || value.isEmpty) return '새 비밀번호를 입력해주세요.';
                  if (value.length < 6) return '6자 이상 입력해주세요.';
                  return null;
                }),
                SizedBox(height: 8),
                TextFormField(controller: _confirmNewPasswordController, decoration: InputDecoration(labelText: '새 비밀번호 확인', prefixIcon: Icon(Icons.check_circle_outline)), obscureText: true, validator: (value) {
                  if (value == null || value.isEmpty) return '새 비밀번호를 다시 입력해주세요.';
                  if (value != _newPasswordController.text) return '새 비밀번호가 일치하지 않습니다.';
                  return null;
                }),
                SizedBox(height: 16),
                ElevatedButton(onPressed: _changePassword, child: Text('비밀번호 변경하기'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 45))),
              ],
            ),
          ),
          Divider(height: 40),
          // 회원 탈퇴 버튼
          ListTile(leading: Icon(Icons.delete_forever_outlined, color: Colors.redAccent), title: Text('회원 탈퇴', style: TextStyle(color: Colors.redAccent)), onTap: _showDeleteAccountDialog),
        ],
      ),
    );
  }
}