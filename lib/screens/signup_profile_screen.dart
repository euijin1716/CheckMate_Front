import 'package:flutter/material.dart';
import 'package:health_app/models/gender.dart';
import 'package:health_app/screens/signup_health_screen.dart';
// 서버 Gender.java 와 맞추기 위해 MALE/FEMALE 에서 MAN/WOMAN으로 변경했습니다.
// 만약 서버를 MALE/FEMALE로 수정하셨다면 이 부분은 원래대로 돌려주세요.
import 'package:health_app/models/gender.dart';


class SignupProfileScreen extends StatefulWidget {
  const SignupProfileScreen({super.key});

  @override
  State<SignupProfileScreen> createState() => _SignupProfileScreenState();
}

class _SignupProfileScreenState extends State<SignupProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // 비밀번호 재확인 컨트롤러 추가
  final _birthDayController = TextEditingController();
  // 서버 Gender Enum 값에 맞춤
  Gender _selectedGender = Gender.MAN;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // 비밀번호 재확인 컨트롤러 dispose 추가
    _birthDayController.dispose();
    super.dispose();
  }

  // 약관 동의 다이얼로그를 보여주는 함수 (LoginScreen으로 이동되었으므로 여기서는 제거)
  /*
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
  */
  // ===== 생년월일 Date Picker 함수 추가 =====
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // 초기 선택 날짜
      firstDate: DateTime(1920), // 선택 가능한 가장 빠른 날짜
      lastDate: DateTime.now(), // 선택 가능한 가장 마지막 날짜
    );
    if (picked != null) {
      setState(() {
        // YYYY-MM-DD 형식으로 변환하여 컨트롤러에 설정
        _birthDayController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }
  // ===================================

  void _onNextPressed() async { // async 키워드 추가
    if (_formKey.currentState!.validate()) {
      // 약관 동의는 LoginScreen에서 이미 처리되었으므로, 여기서는 다시 묻지 않음
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignupHealthScreen(
            name: _nameController.text,
            loginId: _idController.text,
            password: _passwordController.text,
            gender: _selectedGender,
            birthDay: _birthDayController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 정보 입력')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: '아이디 (이메일)'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '아이디(이메일)를 입력해주세요.';
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) {
                    return '올바른 이메일 형식을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요.';
                  }
                  if (value.length < 8 || value.length > 20) {
                    return '비밀번호는 8자 이상 20자 이하로 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController, // 비밀번호 재확인 필드
                decoration: const InputDecoration(labelText: '비밀번호 재확인'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 다시 입력해주세요.';
                  }
                  if (value != _passwordController.text) {
                    return '비밀번호가 일치하지 않습니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Gender>(
                value: _selectedGender,
                onChanged: (Gender? newValue) {
                  setState(() {
                    _selectedGender = newValue!;
                  });
                },
                items: Gender.values.map((Gender gender) {
                  return DropdownMenuItem<Gender>(
                    value: gender,
                    child: Text(gender == Gender.MAN ? '남성' : '여성'),
                  );
                }).toList(),
                decoration: const InputDecoration(labelText: '성별'),
              ),
              const SizedBox(height: 16),
              // ===== 생년월일 TextFormField 수정 =====
              TextFormField(
                controller: _birthDayController,
                readOnly: true, // 텍스트를 직접 수정하지 못하도록 설정
                decoration: const InputDecoration(
                  labelText: '생년월일',
                  suffixIcon: Icon(Icons.calendar_today), // 캘린더 아이콘 추가
                ),
                onTap: () {
                  // 탭하면 캘린더를 띄움
                  _selectDate(context);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '생년월일을 선택해주세요.';
                  }
                  return null;
                },
              ),
              // ===================================
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onNextPressed,
                child: const Text('다음'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
