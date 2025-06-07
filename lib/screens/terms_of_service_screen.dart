// lib/screens/terms_of_service_screen.dart

import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('서비스 이용 약관')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
            '제1조 (목적)\n이 약관은 건강관리 앱 서비스 이용과 관련하여 회사와 회원 간의 권리, 의무 및 책임사항 등을 규정함을 목적으로 합니다.\n\n제2조 (정의)\n이 약관에서 사용하는 용어의 정의는 다음과 같습니다...\n\n(이하 약관 내용 생략 - 실제 내용을 채워주세요)'),
      ),
    );
  }
}
