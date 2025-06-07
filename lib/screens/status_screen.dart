// lib/screens/status_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/main.dart'; // dataService 접근을 위해 main.dart 임포트
import 'package:health_app/models/medication.dart'; // 모델 임포트
import 'package:health_app/models/concerned_disease.dart'; // 모델 임포트
import 'package:health_app/models/diagnosed_disease.dart'; // 모델 임포트
import 'package:health_app/screens/add_diagnosed_disease_screen.dart'; // 새로 생성할 화면 임포트
import 'package:health_app/screens/add_medication_screen.dart'; // AddMedicationScreen 임포트 추가

class StatusScreen extends StatefulWidget {
  const StatusScreen({Key? key}) : super(key: key);
  @override
  _StatusScreenState createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  List<Medication> _allMedications = []; // 서버에서 가져온 모든 복약 정보
  List<Medication> _filteredMedications = []; // 현재 필터링된 복약 정보
  late List<ConcernedDisease> _concernedDiseases; // 관심 질환 목록
  late List<DiagnosedDisease> _diagnosedDiseases; // 진단 질환 목록

  String _selectedFilter = '전체'; // 선택된 필터 (기본값 '전체')
  List<String> _filterOptions = ['전체', '영양제']; // 필터 옵션 목록 (초기값)

  @override
  void initState() {
    super.initState();
    _loadAllData(); // 모든 데이터 초기 로드
  }

  // 모든 데이터를 다시 로드하는 함수
  Future<void> _loadAllData() async {
    if (!mounted) return; // 위젯이 dispose되지 않았는지 확인

    // 데이터 로드 전에 UI를 초기화하거나 로딩 상태를 표시
    setState(() {
      _allMedications = [];
      _filteredMedications = [];
      _concernedDiseases = [];
      _diagnosedDiseases = [];
      _filterOptions = ['전체', '영양제']; // 필터 옵션 초기화
    });

    try {
      // 서버에서 복약 정보 로드
      final fetchedMedications = await dataService.fetchMedicationsFromServer();
      // 서버에서 진단 질환 로드
      final fetchedDiagnosedDiseases = await dataService.fetchDiagnosedDiseasesFromServer();

      if (!mounted) return;
      setState(() {
        _allMedications = fetchedMedications; // 모든 복약 정보 저장
        _diagnosedDiseases = fetchedDiagnosedDiseases; // 진단 질환 정보 저장
        _concernedDiseases = dataService.getConcernedDiseaseList(); // DataService에서 관심 질환 목록 가져오기

        // 진단 질환 목록을 필터 옵션에 추가
        for (var disease in _diagnosedDiseases) {
          if (!_filterOptions.contains(disease.name)) {
            _filterOptions.add(disease.name);
          }
        }
        _applyFilter(_selectedFilter); // 현재 선택된 필터 적용
      });
    } catch (e) {
      print('데이터 로드 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터를 불러오는 데 실패했습니다: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // 필터 적용 함수
  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == '전체') {
        _filteredMedications = List.from(_allMedications);
      } else if (filter == '영양제') {
        // "영양제"로 분류할 명확한 기준이 없으므로, 약 이름에 '영양제'가 포함된 경우로 임시 가정
        _filteredMedications = _allMedications.where((med) => med.name.contains('영양제')).toList();
      } else {
        // 선택된 질병명과 연관된 복약 정보 필터링
        _filteredMedications = _allMedications.where((med) =>
        med.associatedDiseaseName == filter // Medication 모델의 associatedDiseaseName 활용
        ).toList();
      }
    });
  }


  // 복약 추가/수정 화면으로 이동하는 함수 (medicationToEdit 파라미터 제거)
  Future<void> _navigateToAddMedication({String? selectedDiseaseName}) async { // medicationToEdit 제거
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(
          initialDiseaseName: selectedDiseaseName, // 필터에서 선택된 질병명 전달
        ),
      ),
    );
    if (result == true) _loadAllData(); // 화면에서 돌아왔을 때 데이터 새로고침
  }

  // 관심 질환 관리 화면으로 이동하는 함수
  Future<void> _navigateToManageConcernedDiseases() async {
    final result = await Navigator.pushNamed(context, '/manage_concerned_diseases');
    if (result == true) _loadAllData(); // 화면에서 돌아왔을 때 데이터 새로고침
  }

  // 진단 질환 관리 화면으로 이동하는 함수
  Future<void> _navigateToManageDiagnosedDiseases() async {
    final result = await Navigator.pushNamed(context, '/manage_diagnosed_diseases');
    if (result == true) _loadAllData(); // 화면에서 돌아왔을 때 데이터 새로고침
  }

  // 새로운 진단 질환 및 복약 정보 등록 화면으로 이동하는 함수
  Future<void> _navigateToAddDiagnosedDisease() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddDiagnosedDiseaseScreen()),
    );
    if (result == true) _loadAllData(); // 화면에서 돌아왔을 때 데이터 새로고침
  }

  // 복약 정보 삭제 확인 대화상자 표시 및 처리
  void _deleteMedication(String id, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('복약 정보 삭제'),
        content: Text("'$name' 복약 정보를 삭제하시겠습니까?"),
        actions: <Widget>[
          TextButton(child: Text('취소'), onPressed: () => Navigator.of(context).pop()),
          TextButton(
            child: Text('삭제', style: TextStyle(color: Colors.red)),
            onPressed: () {
              dataService.deleteMedication(id); // DataService를 통해 복약 정보 삭제
              _loadAllData(); // 데이터 새로고침
              Navigator.of(context).pop(); // 대화상자 닫기
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$name' 복약 정보가 삭제되었습니다.")));
            },
          ),
        ],
      ),
    );
  }

  // 복약 정보 상세 보기 다이얼로그 (새로 추가된 메서드)
  void _showMedicationInfoDialog(Medication medication) async {
    String efficient = '정보 없음';
    String warning = '정보 없음';
    String useMethod = '정보 없음';
    String acquire = '정보 없음';

    try {
      // 약 이름으로 상세 정보 검색
      // dataService.searchMedicines가 이제 List<Map<String, String>>을 반환합니다.
      final results = await dataService.searchMedicines(medication.name);
      if (results.isNotEmpty) {
        final medicineDetail = results.first; // 첫 번째 결과 사용
        efficient = medicineDetail['efficient'] ?? '정보 없음';
        warning = medicineDetail['warning'] ?? '정보 없음';
        useMethod = medicineDetail['useMethod'] ?? '정보 없음';
        acquire = medicineDetail['acquire'] ?? '정보 없음';
      }
    } catch (e) {
      print('약 상세 정보 로드 중 오류 발생: $e');
      // 오류 발생 시에도 기본 '정보 없음'으로 표시
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(medication.name, style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('효능:', efficient),
                _buildInfoRow('사용법:', useMethod),
                _buildInfoRow('주의사항:', warning),
                _buildInfoRow('복용 시 주의사항:', acquire),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 정보 표시를 위한 헬퍼 위젯
  Widget _buildInfoRow(String label, String content) {
    // Check if content is literally the string "null" (case-insensitive) or empty
    String displayContent = (content.toLowerCase() == 'null' || content.isEmpty) ? '정보 없음' : content;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          SizedBox(height: 4),
          Text(displayContent, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }


  // 관심 질환 상세 정보 표시 다이얼로그
  void _showDiseaseDetailsDialog(ConcernedDisease disease) async {
    String description = '등록된 설명이 없습니다.'; // 기본 설명 메시지

    try {
      final results = await dataService.searchDiseases(disease.name);
      if (results.isNotEmpty) {
        // 첫 번째 결과의 설명을 가져옴 (일반적으로 검색 결과는 관련도가 높은 순으로 정렬됨)
        description = results.first['explain']!; // 'explain' 키를 사용하여 설명 가져오기
      }
    } catch (e) {
      print('질병 설명 로드 중 오류 발생: $e');
      description = '질병 설명을 불러오는 데 실패했습니다.';
    }

    if (!mounted) return; // 위젯이 dispose되지 않았는지 확인

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(disease.name),
        content: Text(description),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('닫기'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAllData(); // 당겨서 새로고침 시 모든 데이터 로드
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: <Widget>[
              // 나의 복약 정보 섹션
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('나의 복약 정보', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  // 필터 드롭다운 추가
                  DropdownButton<String>(
                    value: _selectedFilter,
                    icon: const Icon(Icons.filter_list),
                    elevation: 16,
                    style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _applyFilter(newValue); // 필터 적용 함수 호출
                      }
                    },
                    items: _filterOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(height: 10),
              // 복약 정보 목록
              _filteredMedications.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text('필터링된 복약 정보가 없습니다.')))
                  : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _filteredMedications.length,
                  itemBuilder: (context, index) {
                    final med = _filteredMedications[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.medication_liquid_outlined, color: Theme.of(context).primaryColor, size: 30),
                        title: Text(med.name, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${med.dose ?? ''}${med.doseType ?? ''} / ${med.frequency}\n시작: ${med.startDate.year}-${med.startDate.month}-${med.startDate.day}${med.associatedDiseaseName != null ? "\n(${med.associatedDiseaseName})" : ""}'), // 질병명 추가
                        // 복약 알림 스위치 제거
                        // trailing: Switch(
                        //   value: med.reminderEnabled,
                        //   onChanged: (bool value) {
                        //     setState(() {
                        //       med.reminderEnabled = value;
                        //       if (!value) med.reminderTime = null; // 알림 해제 시 시간 초기화
                        //       dataService.addOrUpdateMedication(med); // 변경 사항 저장
                        //     });
                        //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${med.name} 알림 ${value ? "켬" : "끔"}')));
                        //   },
                        // ),
                        isThreeLine: true,
                        // onTap에서 medicationToEdit 파라미터 제거
                        onTap: () => _showMedicationInfoDialog(med), // 약 정보 다이얼로그 표시로 변경
                        onLongPress: () => _deleteMedication(med.id, med.name), // 길게 누르면 삭제 확인
                      ),
                    );
                  }),
              SizedBox(height: 10),
              // 새로운 복약 정보 등록 버튼
              ElevatedButton.icon(
                  icon: Icon(Icons.add_box_outlined),
                  onPressed: () => _navigateToAddMedication(selectedDiseaseName: _selectedFilter), // 선택된 필터 값을 전달
                  label: Text('새로운 복약 정보 등록'),
                  style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50))
              ),
              SizedBox(height: 30),
              // 나의 질환 정보 섹션
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('나의 질환 정보', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  // 새로운 질환 정보 등록 버튼 추가
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor, size: 30),
                    onPressed: _navigateToAddDiagnosedDisease,
                    tooltip: '새로운 진단 질환 등록',
                  ),
                ],
              ),
              SizedBox(height: 10),
              // 현재 진단 질환 요약 및 관리 버튼
              _buildStatusItem(context, '현재 진단 질환', _diagnosedDiseases.isEmpty ? '등록된 진단 질환 없음' : _diagnosedDiseases.map((d) => d.name).join(', '), Icons.local_hospital_outlined, onTap: _navigateToManageDiagnosedDiseases),
              SizedBox(height: 20),
              // 나의 관심 질환 섹션
              Text('나의 관심 질환', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              // 관심 질환 목록
              _concernedDiseases.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text('등록된 관심 질환이 없습니다.')))
                  : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _concernedDiseases.length,
                  itemBuilder: (context, index) {
                    final disease = _concernedDiseases[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.star_border_purple500_outlined, color: Colors.amber[700]),
                        title: Text(disease.name),
                        trailing: Icon(Icons.arrow_forward_ios_outlined, size: 16),
                        onTap: () {
                          // 관심 질환 상세 정보 다이얼로그 표시
                          _showDiseaseDetailsDialog(disease);
                        },
                      ),
                    );
                  }),
              SizedBox(height: 10),
              // 관심 질환 추가/관리 버튼
              ElevatedButton.icon(icon: Icon(Icons.playlist_add_check_outlined), onPressed: _navigateToManageConcernedDiseases, label: Text('관심 질환 추가/관리'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50))),
            ],
          ),
        ),
      ),
    );
  }

  // 상태 항목 카드 위젯 빌더
  Widget _buildStatusItem(BuildContext context, String title, String subtitle, IconData icon, {VoidCallback? onTap}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: onTap != null ? Icon(Icons.arrow_forward_ios_outlined, size: 16) : null,
      ),
    );
  }
}