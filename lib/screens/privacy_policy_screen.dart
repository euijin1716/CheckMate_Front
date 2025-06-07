// lib/screens/privacy_policy_screen.dart

import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('개인정보 처리방침')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
            '개인정보 처리방침\n\n건강관리 앱(이하 "회사")은 개인정보보호법 등 관련 법령상의 개인정보보호 규정을 준수하며, 관련 법령에 의거한 개인정보처리방침을 정하여 이용자 권익 보호에 최선을 다하고 있습니다...\n\n1. 개인정보의 수집 및 이용 목적...\n2. 수집하는 개인정보의 항목...\n\n(이하 방침 내용 생략 - 실제 내용을 채워주세요)'),
      ),
    );
  }
}
