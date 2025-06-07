// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/main.dart'; // authService 접근을 위해 main.dart 임포트

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 약관 동의 다이얼로그를 보여주는 함수 (SignupHealthScreen에서 이동)
  Future<bool> _showTermsAndConditionsDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 사용자가 다이얼로그 바깥을 탭하여 닫는 것을 막음
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('서비스 이용 약관 동의'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('이 앱은 건강 관리 및 정보 제공을 목적으로 합니다.'),
                SizedBox(height: 10),
                Text('제공되는 정보는 의료 전문가의 진단을 대체할 수 없습니다.'),
                SizedBox(height: 10),
                Text('정확한 진단 및 치료를 위해서는 반드시 의사와 상담하세요.'),
                SizedBox(height: 10),
                Text('개인정보는 관련 법령에 따라 안전하게 보호됩니다.'),
                SizedBox(height: 10),
                Text('자세한 내용은 개인정보 처리방침을 참조해주세요.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(false); // 동의하지 않음을 반환
              },
            ),
            ElevatedButton(
              child: const Text('동의'),
              onPressed: () {
                Navigator.of(context).pop(true); // 동의함을 반환
              },
            ),
          ],
        );
      },
    ) ?? false; // null이 반환될 경우 (예: 뒤로가기 버튼) false로 처리
  }

  // 사용자 로그인 처리
  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      bool success = await authService.login(
        _loginIdController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return; // 위젯이 dispose되지 않았는지 확인
      setState(() {
        _isLoading = false;
      });
      if (success) {
        // 로그인 성공 시 메인 화면으로 이동하고 이전 라우트 모두 제거
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (Route<dynamic> route) => false);
      } else {
        // 로그인 실패 시 스낵바 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인에 실패했습니다. 아이디 또는 비밀번호를 확인해주세요.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 앱 아이콘
                  Icon(Icons.health_and_safety_outlined, size: 80, color: Theme.of(context).primaryColor),
                  SizedBox(height: 16),
                  // 앱 제목
                  Text('내 손안의 건강 비서', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                  SizedBox(height: 40),
                  // 아이디 입력 필드
                  TextFormField(
                    controller: _loginIdController,
                    decoration: InputDecoration(hintText: '아이디 (이메일 형식)', prefixIcon: Icon(Icons.person_outline)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return '아이디를 입력해주세요.';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  // 비밀번호 입력 필드
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: '비밀번호',
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    validator: (value) => (value == null || value.isEmpty) ? '비밀번호를 입력해주세요.' : null,
                  ),
                  SizedBox(height: 24),
                  // 로그인 버튼 또는 로딩 인디케이터
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _loginUser,
                    child: Text('로그인'),
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16.0), textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 16),
                  // 회원가입 유도 텍스트 및 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('계정이 없으신가요?'),
                      TextButton(
                        onPressed: _isLoading ? null : () async {
                          // 회원가입 버튼 클릭 시 약관 동의 다이얼로그 먼저 표시
                          bool termsAccepted = await _showTermsAndConditionsDialog();
                          if (!mounted) return;
                          if (termsAccepted) {
                            Navigator.pushNamed(context, '/signup');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('약관에 동의해야 회원가입을 진행할 수 있습니다.')),
                            );
                          }
                        },
                        child: Text('회원가입', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
