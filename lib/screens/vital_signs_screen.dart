// lib/screens/vital_signs_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/main.dart'; // authService, dataService 접근
import 'package:health_app/models/diagnosed_disease.dart'; // 올바른 DiagnosedDisease 모델 임포트

class VitalSignsScreen extends StatefulWidget {
  @override
  _VitalSignsScreenState createState() => _VitalSignsScreenState();
}

class _VitalSignsScreenState extends State<VitalSignsScreen> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _heightController = TextEditingController(); // 키 입력을 위한 컨트롤러
  final _weightController = TextEditingController(); // 몸무게 입력을 위한 컨트롤러

  double _height = 0;
  double _weight = 0;
  List<DiagnosedDisease> _diagnosedDiseases = [];
  bool _isEditingVitalSigns = true; // 혈압/심박수 입력/표시 모드 전환

  bool _isEditingHeight = false; // 키 수정 모드
  bool _isEditingWeight = false; // 몸무게 수정 모드

  DiagnosedDisease? _vitalSignsDisease; // 혈압/심박수 정보를 담을 DiagnosedDisease 객체

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _initializeVitalSignsAndDiseases(); // 초기 로드 및 상태 설정 통합
  }

  // 사용자 정보 로드 (키, 몸무게)
  void _loadUserInfo() async {
    if (!mounted) return;
    await authService.fetchAndSetUserInfo(); // 서버에서 최신 사용자 정보 가져와서 저장
    setState(() {
      _height = authService.getUserHeight();
      _weight = authService.getUserWeight();
      // 값이 0일 경우 빈 문자열로 표시하여 0.0이 보이지 않도록 함
      _heightController.text = _height == 0.0 ? '' : _height.toString();
      _weightController.text = _weight == 0.0 ? '' : _weight.toString();
    });
  }

  // 진단 질환 정보 로드 및 혈압/심박수 초기 설정
  Future<void> _initializeVitalSignsAndDiseases() async {
    // 1. 서버에서 진단 질환 로드
    final fetchedDiseases = await dataService.fetchDiagnosedDiseasesFromServer();

    // 2. 로컬(SharedPreferences)에서 혈압/심박수 로드
    final localVitalSigns = await dataService.loadVitalSignsLocally();
    final localSystolic = localVitalSigns['systolic'];
    final localDiastolic = localVitalSigns['diastolic'];
    final localHeartRate = localVitalSigns['heartRate'];

    if (mounted) {
      setState(() {
        _diagnosedDiseases = fetchedDiseases;

        // 3. _vitalSignsDisease 객체 설정 (로컬 데이터 우선)
        if (localSystolic != null && localDiastolic != null && localHeartRate != null &&
            localSystolic != 0 && localDiastolic != 0 && localHeartRate != 0) {
          _vitalSignsDisease = DiagnosedDisease(
            id: 'local_vital_signs', // 로컬 저장을 위한 고유 ID
            name: '최근 건강 측정',
            diagnosedDate: DateTime.now(),
            systolicBloodPressure: localSystolic,
            diastolicBloodPressure: localDiastolic,
            heartRate: localHeartRate,
          );
          _isEditingVitalSigns = false; // 로컬 데이터 있으면 표시 모드
        } else if (_diagnosedDiseases.isNotEmpty && _diagnosedDiseases.first.systolicBloodPressure != null) {
          // 서버에서 가져온 첫 번째 질환에 혈압/심박수 데이터가 있다면 사용
          _vitalSignsDisease = _diagnosedDiseases.first;
          _isEditingVitalSigns = false; // 서버 데이터 있으면 표시 모드
        } else {
          _isEditingVitalSigns = true; // 데이터 없으면 입력 모드
        }

        // 입력 모드일 경우 기존 값으로 컨트롤러 초기화
        if (_isEditingVitalSigns && _vitalSignsDisease != null) {
          _systolicController.text = _vitalSignsDisease!.systolicBloodPressure?.toString() ?? '';
          _diastolicController.text = _vitalSignsDisease!.diastolicBloodPressure?.toString() ?? '';
          _heartRateController.text = _vitalSignsDisease!.heartRate?.toString() ?? '';
        }
      });
    }
  }

  void _saveVitalSigns() async {
    if (_systolicController.text.isEmpty || _diastolicController.text.isEmpty || _heartRateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('혈압, 심박수를 모두 입력해주세요.'), backgroundColor: Colors.orange));
      return;
    }

    final systolic = int.tryParse(_systolicController.text);
    final diastolic = int.tryParse(_diastolicController.text);
    final heartRate = int.tryParse(_heartRateController.text);

    if (systolic == null || diastolic == null || heartRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('유효한 숫자를 입력해주세요.'), backgroundColor: Colors.orange));
      return;
    }

    // _vitalSignsDisease가 null이거나 로컬 저장용 ID를 가지고 있으면 새로 생성/업데이트
    if (_vitalSignsDisease == null || _vitalSignsDisease!.id == 'local_vital_signs') {
      _vitalSignsDisease = DiagnosedDisease(
        id: 'local_vital_signs', // 로컬 저장을 위한 고유 ID
        name: '최근 건강 측정',
        diagnosedDate: DateTime.now(),
        systolicBloodPressure: systolic,
        diastolicBloodPressure: diastolic,
        heartRate: heartRate,
      );
    } else {
      // 기존 진단 질환 객체에 업데이트 (현재는 첫 번째 질환에 저장하는 로직이므로, 이 부분은 _vitalSignsDisease가 실제 서버 질환일 경우를 대비)
      _vitalSignsDisease!.systolicBloodPressure = systolic;
      _vitalSignsDisease!.diastolicBloodPressure = diastolic;
      _vitalSignsDisease!.heartRate = heartRate;
    }

    try {
      // dataService의 addOrUpdateDiagnosedDisease를 호출하여 로컬 저장 로직을 트리거
      dataService.addOrUpdateDiagnosedDisease(_vitalSignsDisease!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('건강 상태가 저장되었습니다.'), backgroundColor: Colors.green));

      // 입력 필드 초기화
      _systolicController.clear();
      _diastolicController.clear();
      _heartRateController.clear();

      await _initializeVitalSignsAndDiseases(); // 업데이트된 데이터 다시 로드 및 UI 상태 갱신
      if (mounted) {
        setState(() {
          _isEditingVitalSigns = false; // 표시 모드로 전환
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('건강 상태 저장에 실패했습니다: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // 키 저장 함수
  void _saveHeight() async {
    if (_heightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('키를 입력해주세요.'), backgroundColor: Colors.orange));
      return;
    }

    final newHeight = double.tryParse(_heightController.text);
    if (newHeight == null || newHeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('유효한 키를 입력해주세요.'), backgroundColor: Colors.orange));
      return;
    }

    bool success = await authService.updateUserHeight(newHeight);
    if (success && mounted) {
      setState(() {
        _height = newHeight;
        _isEditingHeight = false; // 저장 후 표시 모드로 전환
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('키가 저장되었습니다.'), backgroundColor: Colors.green));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('키 저장에 실패했습니다.'), backgroundColor: Colors.red));
    }
  }

  // 몸무게 저장 함수
  void _saveWeight() async {
    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('몸무게를 입력해주세요.'), backgroundColor: Colors.orange));
      return;
    }

    final newWeight = double.tryParse(_weightController.text);
    if (newWeight == null || newWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('유효한 몸무게를 입력해주세요.'), backgroundColor: Colors.orange));
      return;
    }

    bool success = await authService.updateUserWeight(newWeight);
    if (success && mounted) {
      setState(() {
        _weight = newWeight;
        _isEditingWeight = false; // 저장 후 표시 모드로 전환
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('몸무게가 저장되었습니다.'), backgroundColor: Colors.green));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('몸무게 저장에 실패했습니다.'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 혈압/심박수 표시를 위한 객체 (로컬 또는 서버에서 로드된 것)
    final DiagnosedDisease? displayVitalSigns = _vitalSignsDisease;

    return Scaffold(
      appBar: AppBar(title: Text('나의 건강 상태')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            Text('신체 정보', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 10),
            // 키 정보 표시 및 수정
            Card(
              margin: EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.height_outlined, color: Theme.of(context).primaryColor),
                    SizedBox(width: 16),
                    Expanded(
                      child: _isEditingHeight
                          ? TextField(
                        controller: _heightController,
                        decoration: InputDecoration(
                          labelText: '키 (cm)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('키', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(_height == 0.0 ? '정보 없음' : '${_height} cm', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    _isEditingHeight
                        ? IconButton(
                      icon: Icon(Icons.save_outlined),
                      onPressed: _saveHeight,
                      tooltip: '키 저장',
                    )
                        : IconButton(
                      icon: Icon(Icons.edit_outlined),
                      onPressed: () {
                        setState(() {
                          _isEditingHeight = true;
                          _heightController.text = _height == 0.0 ? '' : _height.toString(); // 현재 값으로 컨트롤러 초기화
                        });
                      },
                      tooltip: '키 수정',
                    ),
                  ],
                ),
              ),
            ),
            // 몸무게 정보 표시 및 수정
            Card(
              margin: EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.line_weight_outlined, color: Theme.of(context).primaryColor),
                    SizedBox(width: 16),
                    Expanded(
                      child: _isEditingWeight
                          ? TextField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          labelText: '몸무게 (kg)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('몸무게', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(_weight == 0.0 ? '정보 없음' : '${_weight} kg', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    _isEditingWeight
                        ? IconButton(
                      icon: Icon(Icons.save_outlined),
                      onPressed: _saveWeight,
                      tooltip: '몸무게 저장',
                    )
                        : IconButton(
                      icon: Icon(Icons.edit_outlined),
                      onPressed: () {
                        setState(() {
                          _isEditingWeight = true;
                          _weightController.text = _weight == 0.0 ? '' : _weight.toString(); // 현재 값으로 컨트롤러 초기화
                        });
                      },
                      tooltip: '몸무게 수정',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('혈압 및 심박수', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 10),
            // 혈압/심박수 입력 또는 표시 UI 조건부 렌더링
            if (_isEditingVitalSigns) // _isEditingVitalSigns 상태에 따라 입력/표시 전환
            // 입력 모드
              Column(
                children: [
                  TextField(
                    controller: _systolicController,
                    decoration: InputDecoration(labelText: '수축기 혈압 (mmHg)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _diastolicController,
                    decoration: InputDecoration(labelText: '이완기 혈압 (mmHg)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _heartRateController,
                    decoration: InputDecoration(labelText: '심박수 (bpm)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveVitalSigns,
                    child: Text('저장'),
                  ),
                ],
              )
            else
            // 표시 모드
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('최근 측정 값', style: TextStyle(fontWeight: FontWeight.bold)),
                  // null-safe 접근 (?. ) 및 null 병합 연산자 (??) 사용
                  Text('혈압: ${displayVitalSigns?.systolicBloodPressure ?? '--'}/${displayVitalSigns?.diastolicBloodPressure ?? '--'} mmHg'),
                  Text('심박수: ${displayVitalSigns?.heartRate ?? '--'} bpm'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditingVitalSigns = true; // 편집 모드로 전환
                        // 기존 값으로 컨트롤러 초기화
                        _systolicController.text = displayVitalSigns?.systolicBloodPressure?.toString() ?? '';
                        _diastolicController.text = displayVitalSigns?.diastolicBloodPressure?.toString() ?? '';
                        _heartRateController.text = displayVitalSigns?.heartRate?.toString() ?? '';
                      });
                    },
                    child: Text('수정'),
                  ),
                ],
              ),
            SizedBox(height: 20),
            // '나의 질환 정보' 섹션이 제거됨
          ],
        ),
      ),
    );
  }
}