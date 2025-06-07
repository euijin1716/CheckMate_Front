// lib/services/data_service.dart

import 'package:health_app/models/medication.dart';
import 'package:health_app/models/concerned_disease.dart';
import 'package:health_app/models/diagnosed_disease.dart'; // 올바른 DiagnosedDisease 모델 임포트
import 'package:health_app/models/chat_message.dart';
import 'package:health_app/models/potential_disease_memo.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart'; // TimeOfDay를 위해 필요합니다.
import 'package:health_app/services/auth_service.dart'; // AuthService를 직접 임포트
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 임포트 추가

class DataService {
  final List<Medication> _medications = [];
  final List<ConcernedDisease> _concernedDiseases = [];
  final List<DiagnosedDisease> _diagnosedDiseases = [];
  final List<ChatMessage> _chatMessages = [];
  final List<PotentialDiseaseMemo> _potentialDiseaseMemos = [];

  //local 서버 주소
  final String _baseUrl = 'http://10.0.2.2:8080';

  //aws 서버 주소
  // final String _baseUrl = 'https://api.ssucheckmate.com';

  // AuthService 인스턴스를 받기 위한 필드 추가
  final AuthService _authService;

  // 생성자를 통해 AuthService 인스턴스를 주입받음
  DataService(this._authService);

  List<Medication> getMedications() {
    return _medications;
  }

  void addOrUpdateMedication(Medication medication) {
    int index = _medications.indexWhere((m) => m.id == medication.id);
    if (index != -1) {
      _medications[index] = medication;
    } else {
      _medications.add(medication); // 'medation'을 'medication'으로 수정
    }
  }

  void deleteMedication(String id) {
    _medications.removeWhere((m) => m.id == id);
  }

  List<ConcernedDisease> getConcernedDiseaseList() {
    return _concernedDiseases;
  }

  void addOrUpdateConcernedDisease(ConcernedDisease disease) {
    int index = _concernedDiseases.indexWhere((d) => d.id == disease.id);
    if (index != -1) {
      _concernedDiseases[index] = disease;
    } else {
      _concernedDiseases.add(disease);
    }
  }

  void deleteConcernedDisease(String id) {
    _concernedDiseases.removeWhere((d) => d.id == id);
  }

  List<DiagnosedDisease> getDiagnosedDiseases() {
    return _diagnosedDiseases;
  }

  void addDiagnosedDisease(DiagnosedDisease disease) {
    addOrUpdateDiagnosedDisease(disease);
  }

  void addOrUpdateDiagnosedDisease(DiagnosedDisease disease) {
    int index = _diagnosedDiseases.indexWhere((d) => d.id == disease.id);
    if (index != -1) {
      _diagnosedDiseases[index] = disease;
    } else {
      _diagnosedDiseases.add(disease);
    }
    // 혈압/심박수 정보가 포함된 DiagnosedDisease인 경우 로컬에 저장
    _saveVitalSignsLocally(disease);
  }

  // 새로운 메서드: 혈압/심박수 정보를 SharedPreferences에 저장
  Future<void> _saveVitalSignsLocally(DiagnosedDisease disease) async {
    if (disease.systolicBloodPressure != null || disease.diastolicBloodPressure != null || disease.heartRate != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastSystolicBloodPressure', disease.systolicBloodPressure ?? 0);
      await prefs.setInt('lastDiastolicBloodPressure', disease.diastolicBloodPressure ?? 0);
      await prefs.setInt('lastHeartRate', disease.heartRate ?? 0);
      print('Vital signs saved locally: ${disease.systolicBloodPressure}/${disease.diastolicBloodPressure}, ${disease.heartRate}');
    }
  }

  // 새로운 메서드: SharedPreferences에서 혈압/심박수 정보를 로드
  Future<Map<String, int?>> loadVitalSignsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'systolic': prefs.getInt('lastSystolicBloodPressure'),
      'diastolic': prefs.getInt('lastDiastolicBloodPressure'),
      'heartRate': prefs.getInt('lastHeartRate'),
    };
  }

  Future<List<DiagnosedDisease>> fetchDiagnosedDiseasesFromServer() async {
    // _authService를 통해 userId와 accessToken에 접근
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final url = Uri.parse('$_baseUrl/members/$userId/prescriptions');
    final headers = {
      'Authorization': 'Bearer ${_authService.getAccessToken()}',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        _diagnosedDiseases.clear();

        for (var jsonItem in jsonList) {
          if (jsonItem['disease'] != null) {
            final diseaseName = jsonItem['disease']['name'];
            // 서버에서 prescriptionDate 필드를 가져와 사용
            final String? prescriptionDateStr = jsonItem['prescriptionDate'];
            final diagnosedDate = prescriptionDateStr != null ? DateTime.parse(prescriptionDateStr) : DateTime.now();

            _diagnosedDiseases.add(DiagnosedDisease(
              id: jsonItem['id'].toString(),
              name: diseaseName,
              diagnosedDate: diagnosedDate,
            ));
          }
        }
        print('서버에서 진단 질환 목록 로드 성공: ${_diagnosedDiseases.length}개'); //
        return _diagnosedDiseases;
      } else {
        print('서버에서 진단 질환 목록 로드 실패: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to load diagnosed diseases from server: ${response.statusCode}');
      }
    } catch (e) {
      print('서버 통신 오류: $e');
      throw Exception('Failed to connect to server to fetch diagnosed diseases.');
    }
  }

  Future<List<Medication>> fetchMedicationsFromServer() async {
    // _authService를 통해 userId와 accessToken에 접근
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final url = Uri.parse('$_baseUrl/members/$userId/prescriptions');
    final headers = {
      'Authorization': 'Bearer ${_authService.getAccessToken()}',
    };

    try {
      final response = await http.get(url, headers: headers);

      print('fetchMedicationsFromServer URL: $url');
      print('fetchMedicationsFromServer Status Code: ${response.statusCode}');
      print('fetchMedicationsFromServer Response Body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        _medications.clear();

        for (var prescriptionJson in jsonList) {
          final String? diseaseName = prescriptionJson['disease']?['name'];
          // Prescription의 numPerDay, alarmTimer 값 가져오기
          final int? prescriptionNumPerDay = prescriptionJson['numPerDay'];
          final String? alarmTimer1Str = prescriptionJson['alarmTimer1'];
          final String? alarmTimer2Str = prescriptionJson['alarmTimer2'];
          final String? alarmTimer3Str = prescriptionJson['alarmTimer3'];
          final String? alarmTimer4Str = prescriptionJson['alarmTimer4'];


          if (prescriptionJson['prescriptionMedicines'] != null) {
            for (var pmJson in prescriptionJson['prescriptionMedicines']) {
              if (pmJson['medicine'] != null) {
                var medicineJson = pmJson['medicine'];

                // PrescriptionMedicine의 상세 필드 사용
                final String? startDateStr = pmJson['startDate'];
                final String? endDateStr = pmJson['endDate'];
                // final int? numPerDay = pmJson['numPerDay']; // 이 값은 PrescriptionMedicine에서 가져오지 않습니다.

                // 추가된 필드: dose, doseType
                final int? dose = pmJson['dose'];
                final String? doseType = pmJson['doseType'];

                final DateTime startDate = startDateStr != null ? DateTime.parse(startDateStr) : DateTime.now();
                final DateTime? endDate = endDateStr != null ? DateTime.parse(endDateStr) : null;

                // 알람 시간 파싱 및 TimeOfDay 변환 (Medication 모델에서 직접 사용되지 않지만, 디버깅을 위해 유지)
                TimeOfDay? parseTime(String? timeStr) {
                  if (timeStr == null) return null;
                  final parts = timeStr.split(':');
                  if (parts.length >= 2) {
                    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                  }
                  return null;
                }

                // 복용량 및 빈도 문자열 생성
                String frequencyText = prescriptionNumPerDay != null ? '1일 $prescriptionNumPerDay회' : '정보 없음'; // Prescription의 numPerDay 사용


                print('Found medicine: ${medicineJson['medicineName']} for disease: $diseaseName');

                _medications.add(Medication(
                  id: pmJson['id'].toString(), // PrescriptionMedicine의 ID 사용
                  name: medicineJson['medicineName'],
                  dosage: '', // 사용하지 않음 (요구사항)
                  frequency: frequencyText, // 새로운 형식의 frequency
                  startDate: startDate,
                  endDate: endDate,
                  // reminderEnabled, reminderTime 삭제
                  associatedDiseaseName: diseaseName,
                  dose: dose, // dose 필드 추가
                  doseType: doseType, // doseType 필드 추가
                  numPerDayValue: prescriptionNumPerDay, // Prescription의 numPerDay 값을 Medication에 저장
                ));
              }
            }
          }
        }
        print('서버에서 복약 정보 목록 로드 성공: ${_medications.length}개');
        return _medications;
      } else {
        print('서버에서 복약 정보 목록 로드 실패: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to load medications from server: ${response.statusCode}');
      }
    } catch (e) {
      print('서버 통신 오류: $e');
      throw Exception('Failed to connect to server to fetch medications.');
    }
  }

  List<ChatMessage> getChatMessages() {
    return _chatMessages;
  }

  void addChatMessage(ChatMessage message) {
    _chatMessages.add(message);
  }

  // PotentialDiseaseMemo 관련 메서드 수정 (DB 연동)
  Future<List<PotentialDiseaseMemo>> fetchPotentialDiseaseMemosFromServer() async {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final url = Uri.parse('$_baseUrl/members/$userId/memos');
    final headers = {
      'Authorization': 'Bearer ${_authService.getAccessToken()}',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        _potentialDiseaseMemos.clear();
        // Corrected: Ensure the map result is correctly cast to List<PotentialDiseaseMemo>
        _potentialDiseaseMemos.addAll(jsonList.map((json) => PotentialDiseaseMemo.fromJson(json)).toList().cast<PotentialDiseaseMemo>());
        print('서버에서 잠재 질병 메모 로드 성공: ${_potentialDiseaseMemos.length}개');
        return _potentialDiseaseMemos;
      } else {
        print('서버에서 잠재 질병 메모 로드 실패: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to load potential disease memos from server: ${response.statusCode}');
      }
    } catch (e) {
      print('서버 통신 오류: $e');
      throw Exception('Failed to connect to server to fetch potential disease memos.');
    }
  }

  Future<void> savePotentialDiseaseMemoToServer(PotentialDiseaseMemo memo) async {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer ${_authService.getAccessToken()}',
    };

    final url = Uri.parse('$_baseUrl/members/$userId/memos');
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(memo.toJson()), // Use toJson() method
      );

      if (response.statusCode == 200) {
        print('잠재 질병 메모 저장 성공');
        await fetchPotentialDiseaseMemosFromServer(); // 저장 후 목록 새로고침
      } else {
        print('잠재 질병 메모 저장 실패: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to save potential disease memo: ${response.statusCode}');
      }
    } catch (e) {
      print('서버 통신 오류: $e');
      throw Exception('Failed to connect to server to save potential disease memo.');
    }
  }

  Future<void> updatePotentialDiseaseMemoToServer(PotentialDiseaseMemo memo) async {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer ${_authService.getAccessToken()}',
    };

    final url = Uri.parse('$_baseUrl/members/$userId/memos/${memo.id}');
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(memo.toJson()), // Use toJson() method
      );

      if (response.statusCode == 200) {
        print('잠재 질병 메모 업데이트 성공');
        await fetchPotentialDiseaseMemosFromServer(); // 업데이트 후 목록 새로고침
      } else {
        print('잠재 질병 메모 업데이트 실패: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to update potential disease memo: ${response.statusCode}');
      }
    } catch (e) {
      print('서버 통신 오류: $e');
      throw Exception('Failed to connect to server to update potential disease memo.');
    }
  }

  Future<void> deletePotentialDiseaseMemoFromServer(String memoId) async {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final url = Uri.parse('$_baseUrl/members/$userId/memos/$memoId');
    final headers = {
      'Authorization': 'Bearer ${_authService.getAccessToken()}',
    };

    try {
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 204 || response.statusCode == 200) {
        print('잠재 질병 메모 삭제 성공: $memoId');
        await fetchPotentialDiseaseMemosFromServer(); // 삭제 후 목록 새로고침
      } else {
        print('잠재 질병 메모 삭제 실패: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to delete potential disease memo: ${response.statusCode}');
      }
    } catch (e) {
      print('서버 통신 오류: $e');
      throw Exception('Failed to connect to server to delete potential disease memo.');
    }
  }


  Future<String> getAiResponse(String prompt) async {
    await Future.delayed(const Duration(seconds: 1));
    return "AI 응답: '$prompt'에 대해 궁금하시군요. 더 자세한 정보가 필요하시면 말씀해주세요.";
  }

  // 질병 및 복약 정보 등록 (기존 AddDiagnosedDiseaseScreen에서 사용)
  // 이 메서드는 이제 새로운 처방전 ID를 반환하도록 수정됩니다.
  Future<int> registerDiseaseAndMedications(
      DiagnosedDisease disease,
      List<Medication> medications,
      {int? numPerDayForPrescription, List<TimeOfDay?>? alarmTimesForPrescription}) async {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer ${_authService.getAccessToken()}',
    };

    // 1. 빈 처방전 생성
    // 쿼리 파라미터로 numPerDay와 alarmTimer들을 추가합니다.
    final Map<String, dynamic> queryParams = {
      'prescriptionDate': disease.diagnosedDate.toIso8601String().split('T')[0],
    };

    if (numPerDayForPrescription != null) {
      queryParams['numPerDay'] = numPerDayForPrescription.toString();
    }
    if (alarmTimesForPrescription != null) {
      for (int i = 0; i < alarmTimesForPrescription.length; i++) {
        if (alarmTimesForPrescription[i] != null) {
          queryParams['alarmTimer${i + 1}'] =
          '${alarmTimesForPrescription[i]!.hour.toString().padLeft(2, '0')}:${alarmTimesForPrescription[i]!.minute.toString().padLeft(2, '0')}:00';
        }
      }
    }

    final emptyPrescriptionUrl = Uri.parse('$_baseUrl/members/$userId/prescriptions/empty').replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));

    print('빈 처방전 생성 요청 URL: $emptyPrescriptionUrl');
    final emptyPrescriptionResponse = await http.post(emptyPrescriptionUrl, headers: headers);

    if (emptyPrescriptionResponse.statusCode != 200) {
      print('빈 처방전 생성 실패: ${emptyPrescriptionResponse.statusCode}, ${emptyPrescriptionResponse.body}');
      throw Exception('Failed to create empty prescription: ${emptyPrescriptionResponse.statusCode}');
    }

    final int prescriptionId = jsonDecode(emptyPrescriptionResponse.body); // 백엔드에서 Long을 int로 받음
    print('빈 처방전 생성 성공. Prescription ID: $prescriptionId');

    // 2. 생성된 처방전에 질병 정보 추가 (PATCH 요청)
    final addDiseaseUrl = Uri.parse('$_baseUrl/members/$userId/prescriptions/$prescriptionId/disease?diseaseName=${Uri.encodeQueryComponent(disease.name)}');
    print('질병 추가 요청 URL: $addDiseaseUrl');

    final addDiseaseResponse = await http.patch(addDiseaseUrl, headers: headers);

    if (addDiseaseResponse.statusCode != 200) {
      print('질병 추가 실패: ${addDiseaseResponse.statusCode}, ${addDiseaseResponse.body}');
      throw Exception('Failed to add disease to prescription: ${addDiseaseResponse.statusCode}');
    }
    print('질병 추가 성공.');

    // 3. 각 약 정보를 처방전에 추가 (PATCH 요청, JSON 본문으로 데이터 전송)
    for (var medication in medications) {
      await addMedicineToPrescriptionForExistingId(prescriptionId.toString(), medication);
    }

    print('질병 및 복약 정보 등록 및 로컬 업데이트 완료. 데이터 새로고침 필요.');
    return prescriptionId; // 생성된 prescriptionId 반환
  }

  // 특정 Prescription ID에 약 정보만 추가하는 새로운 메서드
  Future<void> addMedicineToPrescriptionForExistingId(String prescriptionId, Medication medication) async {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer ${_authService.getAccessToken()}',
    };

    final addMedicineUrl = Uri.parse('$_baseUrl/members/$userId/prescriptions/$prescriptionId/medicine');
    print('약 추가 요청 URL: $addMedicineUrl');

    final Map<String, dynamic> medicineRequestBody = {
      'medicineName': medication.name,
      'startDate': medication.startDate.toIso8601String().split('T')[0],
      'endDate': medication.endDate?.toIso8601String().split('T')[0],
      'numPerDay': medication.numPerDayValue, // Medication의 numPerDayValue 사용
      'dose': medication.dose,
      'doseType': medication.doseType,
      // alarmTimer 필드는 Prescription 레벨로 이동했으므로 여기서는 제거합니다.
      // 'alarmTimer1': medication.reminderTime != null ? '${medication.reminderTime!.hour.toString().padLeft(2, '0')}:${medication.reminderTime!.minute.toString().padLeft(2, '0')}:00' : null,
      // 'alarmTimer2': null,
      // 'alarmTimer3': null,
      // 'alarmTimer4': null,
    };

    final addMedicineResponse = await http.patch(
      addMedicineUrl,
      headers: headers,
      body: jsonEncode(medicineRequestBody),
    );

    if (addMedicineResponse.statusCode != 200) {
      print('약 추가 실패: ${addMedicineResponse.statusCode}, ${addMedicineResponse.body}');
      throw Exception('Failed to add medicine to prescription: ${addMedicineResponse.statusCode}'); //
    }
    print('약 추가 성공: ${medication.name} (Prescription ID: $prescriptionId)');
  }

  // 회원가입 시 '영양제' 처방전을 자동으로 생성하거나 확인하는 메서드
  Future<void> ensureNutrientPrescriptionExists(int userId) async {
    final String nutrientDiseaseName = '영양제';
    final String accessToken = _authService.getAccessToken() ?? '';

    if (accessToken.isEmpty) {
      print('Access Token이 없어 영양제 처방전 생성을 건너킵니다.');
      return;
    }

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json; charset=UTF-8',
    };

    try {
      // 1. '영양제' 질병이 있는지 확인하고 없으면 생성
      final checkDiseaseUrl = Uri.parse('$_baseUrl/diseases?query=${Uri.encodeQueryComponent(nutrientDiseaseName)}');
      final diseaseResponse = await http.get(checkDiseaseUrl, headers: headers);

      String diseaseId;
      if (diseaseResponse.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(utf8.decode(diseaseResponse.bodyBytes));
        if (jsonList.isNotEmpty) {
          // 이미 '영양제' 질병이 존재
          diseaseId = jsonList.first['id'].toString();
          print('Existing "영양제" disease found with ID: $diseaseId');
        } else {
          // '영양제' 질병이 없으면 생성 (백엔드에 질병 생성 API가 필요)
          // 현재 DiseaseController에 질병 생성 API가 없으므로, 이 부분은 백엔드 구현이 필요합니다.
          // 임시로, 질병 검색 API가 없으면 처방전 생성 시 질병 이름으로 자동 생성되도록 백엔드 로직을 믿습니다.
          // 또는, 백엔드에 DiseaseController에 POST /diseases 엔드포인트를 추가해야 합니다.
          // 여기서는 백엔드에서 처방전 생성 시 질병 이름으로 자동 생성되는 로직을 가정합니다.
          print('"영양제" 질병이 없어 새로 생성될 예정입니다.');
          // diseaseId는 직접 생성하지 않고, 처방전 생성 시 백엔드에서 처리되도록 합니다.
        }
      } else {
        print('Failed to check "영양제" disease: ${diseaseResponse.statusCode}, ${diseaseResponse.body}');
        // 오류 발생 시 처방전 생성 로직을 중단하지 않고 진행 (백엔드에서 처리될 수 있도록)
      }

      // 2. 해당 사용자에 대한 '영양제' 처방전이 있는지 확인
      final checkPrescriptionUrl = Uri.parse('$_baseUrl/members/$userId/prescriptions/byDiseaseName?diseaseName=${Uri.encodeQueryComponent(nutrientDiseaseName)}');
      final prescriptionResponse = await http.get(checkPrescriptionUrl, headers: headers);

      if (prescriptionResponse.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(utf8.decode(prescriptionResponse.bodyBytes));
        if (jsonList.isNotEmpty) {
          print('Existing "영양제" prescription found for user $userId.');
          return; // 이미 존재하면 더 이상 작업 불필요
        }
      } else {
        print('Failed to check "영양제" prescription: ${prescriptionResponse.statusCode}, ${prescriptionResponse.body}');
        // 오류 발생 시 처방전 생성 로직을 중단하지 않고 진행
      }

      // 3. '영양제' 처방전이 없으면 새로 생성
      print('Creating new "영양제" prescription for user $userId.');
      final createPrescriptionUrl = Uri.parse('$_baseUrl/members/$userId/prescriptions');
      final createPrescriptionBody = jsonEncode({
        'diseaseName': nutrientDiseaseName,
        'prescriptionDate': DateTime.now().toIso8601String().split('T')[0],
        // 회원가입 시에는 알람 및 횟수 설정하지 않으므로 null
        'numPerDay': null,
        'alarmTimer1': null,
        'alarmTimer2': null,
        'alarmTimer3': null,
        'alarmTimer4': null,
      });

      final createResponse = await http.post(createPrescriptionUrl, headers: headers, body: createPrescriptionBody);

      if (createResponse.statusCode == 200) {
        final int newPrescriptionId = jsonDecode(createResponse.body);
        print('Successfully created "영양제" prescription with ID: $newPrescriptionId for user $userId.');
      } else {
        print('Failed to create "영양제" prescription: ${createResponse.statusCode}, ${createResponse.body}');
        throw Exception('Failed to create "영양제" prescription for user $userId.');
      }
    } catch (e) {
      print('Error ensuring "영양제" prescription: $e');
      // 오류를 다시 던지거나, 사용자에게 알림을 표시할 수 있습니다.
    }
  }


  // 질병 검색 API 호출
  Future<List<Map<String, String>>> searchDiseases(String query) async {
    final url = Uri.parse('$_baseUrl/diseases?query=$query');
    final headers = {
      'Authorization': 'Bearer ${_authService.getAccessToken()}', // JWT 토큰 추가
    };
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        // 각 질병 정보를 Map<String, String> 형태로 변환하여 반환
        return jsonList.map((item) => {
          'name': item['name'] as String,
          'explain': item['explain'] as String? ?? '설명 없음', // null인 경우 '설명 없음'으로 처리
        }).toList().cast<Map<String, String>>();
      } else {
        print('Failed to search diseases: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to search diseases: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during disease search API call: $e');
      throw Exception('Failed to connect to server for disease search.');
    }
  }

  // 약 검색 API 호출 (수정됨: List<Map<String, String>> 반환)
  Future<List<Map<String, String>>> searchMedicines(String query) async {
    final url = Uri.parse('$_baseUrl/medicines?query=$query');
    final headers = {
      'Authorization': 'Bearer ${_authService.getAccessToken()}', // JWT 토큰 추가
    };
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        // 각 약 정보를 Map<String, String> 형태로 변환하여 반환
        return jsonList.map((item) => {
          'medicineName': item['medicineName'] as String,
          'efficient': item['efficient'] as String? ?? '정보 없음',
          'useMethod': item['useMethod'] as String? ?? '정보 없음',
          'acquire': item['acquire'] as String? ?? '정보 없음',
          'warning': item['warning'] as String? ?? '정보 없음',
        }).toList().cast<Map<String, String>>();
      } else {
        print('Failed to search medicines: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to search medicines: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during medicine search API call: $e');
      throw Exception('Failed to connect to server for medicine search.');
    }
  }
  // 새롭게 추가되는 메서드: 서버에서 진단 질환 삭제
  Future<void> deleteDiagnosedDiseaseFromServer(String prescriptionId) async {
    final userId = _authService.getUserId();
    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    final url = Uri.parse('$_baseUrl/members/$userId/prescriptions/$prescriptionId');
    final headers = {
      'Authorization': 'Bearer ${_authService.getAccessToken()}',
    };

    try {
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('서버에서 진단 질환(처방전) 삭제 성공: $prescriptionId');
        // 로컬 목록에서도 삭제 (선택 사항, 서버가 성공하면 로컬에서도 삭제)
        _diagnosedDiseases.removeWhere((d) => d.id == prescriptionId);
      } else {
        print('서버에서 진단 질환 삭제 실패: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to delete diagnosed disease from server: ${response.statusCode}');
      }
    } catch (e) {
      print('서버 통신 오류: $e');
      throw Exception('Failed to connect to server to delete diagnosed disease.');
    }
  }
}