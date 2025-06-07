// lib/services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:health_app/models/gender.dart'; //

class AuthService {
  String? _accessToken;
  static const String _tokenKey = 'accessToken';
  String _userName = "사용자";
  String _userLoginId = "";
  int? _userId;
  double _userHeight = 0.0; // 사용자 키 필드
  double _userWeight = 0.0; // 사용자 몸무게 필드

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);
    if (_accessToken != null) {
      _userName = prefs.getString('userName') ?? "돌아온 사용자";
      _userLoginId = prefs.getString('userLoginId') ?? "";
      _userId = prefs.getInt('userId');
      _userHeight = prefs.getDouble('userHeight') ?? 0.0; // 키 로드
      _userWeight = prefs.getDouble('userWeight') ?? 0.0; // 몸무게 로드
      print("토큰 로드됨: $_accessToken, 사용자: $_userName, ID: $_userId, 키: $_userHeight, 몸무게: $_userWeight");
    }
    // 앱 시작 시 항상 최신 사용자 정보를 서버에서 가져오도록 변경
    await fetchAndSetUserInfo();
  }

  //
  static String get _apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else {
      return 'http://10.0.2.2:8080';
    }
  }

  //aws 서버 주소
  // static String get _apiBaseUrl {
  //   if (kIsWeb) {
  //     return 'https://api.ssucheckmate.com';
  //   } else {
  //     return 'https://api.ssucheckmate.com';
  //   }
  // }


  // 로그인 처리
  Future<bool> login(String loginId, String password) async {
    final String loginUrl = '$_apiBaseUrl/members/login';
    print('로그인 시도: $loginUrl, ID: $loginId');

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'loginId': loginId,
          'password': password,
        }),
      );

      print('로그인 응답 상태 코드: ${response.statusCode}');
      print('로그인 응답 본문: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['accessToken'] != null) {
          _accessToken = data['accessToken'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _accessToken!);

          _userLoginId = data['loginId'];
          _userName = data['name'] ?? "로그인 사용자";
          _userId = (data['id'] as num).toInt();

          // 백엔드 로그인 응답에 height, weight가 직접 포함되지 않으므로, 이 부분은 제거
          // 하지만 로그인 후 바로 사용자 정보를 조회하여 키와 몸무게를 업데이트할 수 있도록 변경

          await prefs.setString('userLoginId', _userLoginId);
          await prefs.setString('userName', _userName);
          await prefs.setInt('userId', _userId!);

          // 로그인 성공 후 사용자 상세 정보를 바로 가져와서 키와 몸무게를 업데이트
          await fetchAndSetUserInfo(); // 이 부분을 추가 또는 활성화합니다.

          print('로그인 성공. 토큰: $_accessToken, 사용자 ID: $_userId, 키: $_userHeight, 몸무게: $_userWeight');
          return true;
        } else {
          print('로그인 실패: 응답 본문에 accessToken 없음');
          return false;
        }
      } else {
        print('로그인 실패: 상태 코드 ${response.statusCode}, 응답: ${utf8.decode(response.bodyBytes)}');
        return false;
      }
    } catch (e) {
      print('로그인 중 네트워크 또는 기타 오류 발생: $e');
      return false;
    }
  }

  // 회원가입 처리
  Future<bool> signUp({
    required String name,
    required String loginId,
    required String password,
    required Gender gender,
    required String birthDay,
    required double height,
    required double weight,
  }) async {
    final String registerUrl = '$_apiBaseUrl/members'; // 회원가입은 /members 사용
    print('회원가입 시도: $registerUrl, 이름: $name, 아이디(loginId): $loginId');

    final Map<String, dynamic> requestBody = {
      'name': name,
      'loginId': loginId,
      'password': password,
      'gender': gender.name, // MAN 또는 WOMAN
      'birthDay': birthDay,
      'height': height,
      'weight': weight,
    };

    print('회원가입 요청 본문: ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      print('회원가입 응답 상태 코드: ${response.statusCode}');
      print('회원가입 응답 본문: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        print('회원가입 성공');
        // 회원가입 성공 시 키와 몸무게를 로컬에 저장
        _userHeight = height;
        _userWeight = weight;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('userHeight', _userHeight);
        await prefs.setDouble('userWeight', _userWeight);
        return true;
      } else {
        print('회원가입 실패: 상태 코드 ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('회원가입 중 네트워크 또는 기타 오류 발생: $e');
      return false;
    }
  }

  // 로그아웃 처리
  Future<void> logout() async {
    _accessToken = null;
    _userLoginId = "";
    _userName = "사용자";
    _userId = null;
    _userHeight = 0.0; // 로그아웃 시 키 초기화
    _userWeight = 0.0; // 로그아웃 시 몸무게 초기화
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('로그아웃됨. 토큰 및 모든 사용자 정보 삭제.');
  }

  // 로그인 상태 확인
  bool isLoggedIn() => _accessToken != null;

  // 액세스 토큰 가져오기
  String? getAccessToken() => _accessToken;

  // 사용자 이름 가져오기
  String getUserName() => _userName;

  // 사용자 이메일 (로그인 ID) 가져오기
  String getUserEmail() => _userLoginId.isNotEmpty ? _userLoginId : "이메일 정보 없음";

  // 사용자 ID 가져오기
  int? getUserId() => _userId;

  // 사용자 키 가져오기
  double getUserHeight() => _userHeight;

  // 사용자 몸무게 가져오기
  double getUserWeight() => _userWeight;

  // 사용자 이름 업데이트 (백엔드 연동)
  Future<bool> updateUserName(String newName) async {
    if (_userId == null) {
      print("사용자 ID가 없어 이름을 업데이트할 수 없습니다.");
      return false;
    }
    final String updateUrl = '$_apiBaseUrl/members/$_userId';
    try {
      final response = await http.patch(
        Uri.parse(updateUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode(<String, String>{'name': newName}),
      );
      if (response.statusCode == 200) {
        _userName = newName;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _userName);
        print('사용자 이름 변경 성공: $_userName');
        return true;
      } else {
        print('사용자 이름 변경 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('사용자 이름 변경 중 오류 발생: $e');
      return false;
    }
  }

  // 비밀번호 변경 (백엔드 연동)
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_userId == null) {
      print("사용자 ID가 없어 비밀번호를 변경할 수 없습니다.");
      return false;
    }
    final String updateUrl = '$_apiBaseUrl/members/$_userId';
    try {
      final response = await http.patch(
        Uri.parse(updateUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode(<String, String>{
          'password': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        print('비밀번호 변경 성공');
        return true;
      } else {
        print('비밀번호 변경 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('비밀번호 변경 중 오류 발생: $e');
      return false;
    }
  }

  // 계정 삭제 (백엔드 연동)
  Future<bool> deleteAccount() async {
    if (_userId == null) {
      print("사용자 ID가 없어 계정을 삭제할 수 없습니다.");
      return false;
    }
    // _userId를 사용하여 올바른 DELETE 요청 URL을 생성
    final String deleteUrl = '$_apiBaseUrl/members/$_userId';
    try {
      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: <String, String>{
          'Authorization': 'Bearer $_accessToken',
        },
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        print('계정 삭제 성공');
        await logout();
        return true;
      } else {
        print('계정 삭제 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('계정 삭제 중 오류 발생: $e');
      return false;
    }
  }

  // 사용자 키 정보 업데이트 (백엔드 연동)
  Future<bool> updateUserHeight(double newHeight) async {
    if (_userId == null) {
      print("사용자 ID가 없어 키를 업데이트할 수 없습니다.");
      return false;
    }
    final String updateUrl = '$_apiBaseUrl/members/$_userId';
    try {
      final response = await http.patch(
        Uri.parse(updateUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode(<String, dynamic>{'height': newHeight}),
      );
      if (response.statusCode == 200) {
        _userHeight = newHeight;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('userHeight', _userHeight);
        print('사용자 키 변경 성공: $_userHeight');
        return true;
      } else {
        print('사용자 키 변경 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('사용자 키 변경 중 오류 발생: $e');
      return false;
    }
  }

  // 사용자 몸무게 정보 업데이트 (백엔드 연동)
  Future<bool> updateUserWeight(double newWeight) async {
    if (_userId == null) {
      print("사용자 ID가 없어 몸무게를 업데이트할 수 없습니다.");
      return false;
    }
    final String updateUrl = '$_apiBaseUrl/members/$_userId';
    try {
      final response = await http.patch(
        Uri.parse(updateUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode(<String, dynamic>{'weight': newWeight}),
      );
      if (response.statusCode == 200) {
        _userWeight = newWeight;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('userWeight', _userWeight);
        print('사용자 몸무게 변경 성공: $_userWeight');
        return true;
      } else {
        print('사용자 몸무게 변경 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('사용자 몸무게 변경 중 오류 발생: $e');
      return false;
    }
  }

  // 백엔드에서 사용자 상세 정보를 가져오는 메서드 추가
  Future<void> fetchAndSetUserInfo() async {
    if (_userId == null || _accessToken == null) {
      print("사용자 ID 또는 Access Token이 없어 사용자 정보를 가져올 수 없습니다.");
      return;
    }

    final String userInfoUrl = '$_apiBaseUrl/members/$_userId'; // 특정 멤버 정보 조회 API
    try {
      final response = await http.get(
        Uri.parse(userInfoUrl),
        headers: <String, String>{
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('사용자 상세 정보 조회 성공: $data');

        // 받아온 정보를 _AuthService 변수에 업데이트하고 SharedPreferences에 저장
        _userLoginId = data['loginId'] ?? _userLoginId;
        _userName = data['name'] ?? _userName;
        _userHeight = (data['height'] as num?)?.toDouble() ?? 0.0;
        _userWeight = (data['weight'] as num?)?.toDouble() ?? 0.0;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userLoginId', _userLoginId);
        await prefs.setString('userName', _userName);
        await prefs.setDouble('userHeight', _userHeight);
        await prefs.setDouble('userWeight', _userWeight);
      } else {
        print('사용자 상세 정보 조회 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('사용자 상세 정보 조회 중 오류 발생: $e');
    }
  }
}