import 'package:flutter/material.dart';
import 'package:health_app/models/gender.dart';
import 'package:health_app/services/auth_service.dart';
import 'package:health_app/screens/login_screen.dart';
import 'package:health_app/main.dart'; // dataService 접근을 위해 main.dart 임포트

class SignupHealthScreen extends StatefulWidget {
  final String name;
  final String loginId;
  final String password;
  final Gender gender;
  final String birthDay;

  const SignupHealthScreen({
    super.key,
    required this.name,
    required this.loginId,
    required this.password,
    required this.gender,
    required this.birthDay,
  });

  @override
  State<SignupHealthScreen> createState() => _SignupHealthScreenState();
}

class _SignupHealthScreenState extends State<SignupHealthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onSignupPressed() async {
    if (_formKey.currentState!.validate()) {
      try {
        bool success = await AuthService().signUp(
          name: widget.name,
          loginId: widget.loginId,
          password: widget.password,
          gender: widget.gender,
          birthDay: widget.birthDay,
          height: double.parse(_heightController.text),
          weight: double.parse(_weightController.text),
        );

        if (success && mounted) {
          // 회원가입 성공 후 '영양제' 처방전 자동 생성 시도
          // AuthService에서 userId를 가져올 수 없으므로, DataService에 userId를 전달하는 방식으로 변경
          // 또는 백엔드에서 회원가입 시 자동으로 '영양제' 처방전을 생성하도록 로직 변경
          // 여기서는 DataService에 userId를 전달하는 방식으로 구현하겠습니다.
          final int? newUserId = authService.getUserId(); // 새로 가입된 사용자의 ID를 가져옴
          if (newUserId != null) {
            await dataService.ensureNutrientPrescriptionExists(newUserId);
            print('영양제 처방전 자동 생성 시도 완료 (회원가입 시).');
          } else {
            print('새로 가입된 사용자 ID를 가져올 수 없어 영양제 처방전 자동 생성을 건너뜁니다.');
          }


          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해주세요.')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입에 실패했습니다. 입력 정보를 확인해주세요.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('건강 정보 입력')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: '키 (cm)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '키를 입력해주세요.';
                  }
                  final height = double.tryParse(value);
                  if (height == null) {
                    return '유효한 숫자를 입력해주세요.';
                  }
                  if (height < 50.0 || height > 250.0) {
                    return '키는 50cm에서 250cm 사이여야 합니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: '몸무게 (kg)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '몸무게를 입력해주세요.';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null) {
                    return '유효한 숫자를 입력해주세요.';
                  }
                  if (weight < 30.0 || weight > 200.0) {
                    return '몸무게는 30kg에서 200kg 사이여야 합니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onSignupPressed,
                child: const Text('완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
