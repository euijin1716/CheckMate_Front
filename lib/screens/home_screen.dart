// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/main.dart'; // authService, dataService 접근을 위해 main.dart 임포트
import 'package:health_app/models/potential_disease_memo.dart'; // 모델 임포트
import 'package:health_app/models/diagnosed_disease.dart'; // 올바른 DiagnosedDisease 모델 임포트
import 'package:health_app/screens/vital_signs_screen.dart'; // 새로운 화면 임포트

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<PotentialDiseaseMemo> _memos = []; // 초기화
  late List<DiagnosedDisease> _diagnosedDiseases = [];

  @override
  void initState() {
    super.initState();
    _loadAllData(); // 모든 데이터 초기 로드
  }

  // 모든 데이터를 로드하는 함수
  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() {
      _memos = [];
      _diagnosedDiseases = [];
    });
    try {
      await _loadMemos(); // 잠재 질병 메모 로드
      await _loadDiagnosedDiseasesFromServer(); // 진단 질환 로드
    } catch (e) {
      print('홈 화면 데이터 로드 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터를 불러오는 데 실패했습니다: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }


  // 메모 데이터를 다시 로드하는 함수 (서버 연동)
  Future<void> _loadMemos() async {
    try {
      if (!mounted) return;
      final fetchedMemos = await dataService.fetchPotentialDiseaseMemosFromServer();
      setState(() {
        _memos = fetchedMemos;
      });
    } catch (e) {
      print('잠재 질병 메모 로드 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('잠재 질병 메모를 불러오는 데 실패했습니다: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }


  // 서버에서 진단 질환 데이터를 로드하는 함수 (새로 추가)
  Future<void> _loadDiagnosedDiseasesFromServer() async {
    try {
      if (!mounted) return;
      final fetchedDiseases = await dataService.fetchDiagnosedDiseasesFromServer();
      setState(() {
        _diagnosedDiseases = fetchedDiseases;
      });
    } catch (e) {
      print('진단 질환 로드 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('진단 질환을 불러오는 데 실패했습니다: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // 잠재 질병 관리 화면으로 이동하는 함수
  Future<void> _navigateToPotentialDiseaseManagement({PotentialDiseaseMemo? memoToEdit}) async {
    // Navigator.pushNamed를 사용하여 화면 이동 및 결과 반환 대기
    final result = await Navigator.pushNamed(context, '/potential_disease_management', arguments: memoToEdit);
    // 화면에서 돌아왔을 때 결과가 true이면 메모 데이터 새로고침
    if (result == true) _loadMemos();
  }

  // 진단 질환 관리 화면으로 이동하는 함수 (기존 로직 사용)
  Future<void> _navigateToManageDiagnosedDiseases() async {
    final result = await Navigator.pushNamed(context, '/manage_diagnosed_diseases');
    if (result == true) {
      _loadDiagnosedDiseasesFromServer(); // 진단 질환 관리 후 목록 새로고침
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAllData(); // 당겨서 새로고침 시 모든 데이터 로드
          if (mounted) setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: <Widget>[
              // 사용자 환영 메시지
              Text('안녕하세요, ${authService.getUserName()}님!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              // 건강 상태 요약 카드 수정
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VitalSignsScreen()),
                  );
                },
                child: _buildInfoCard(context, '나의 건강 상태 요약', '키, 몸무게, 혈압, 심박수 등을 확인하고 관리합니다.', Icons.monitor_heart_outlined, isSummary: true),
              ),
              SizedBox(height: 10),
              // 나의 현재 질환 카드 (서버에서 가져온 데이터 사용)
              GestureDetector(
                onTap: _navigateToManageDiagnosedDiseases, // 탭하면 진단 질환 관리 화면으로 이동
                child: _buildInfoCard(
                  context,
                  '나의 현재 질환',
                  _diagnosedDiseases.isEmpty ? '등록된 질환 없음' : _diagnosedDiseases.map((d) => d.name).join(', '),
                  Icons.sick_outlined,
                ),
              ),
              // SizedBox(height: 10),
              // // 오늘의 복약 카드
              // _buildInfoCard(context, '오늘의 복약', '${dataService.getMedications().where((m) {
              //   final today = DateTime.now();
              //   // 복약 기간이 오늘을 포함하고 알림이 활성화된 복약만 카운트
              //   bool isActive = m.startDate.isBefore(today.add(Duration(days: 1))) && (m.endDate == null || m.endDate!.isAfter(today.subtract(Duration(days: 1))));
              //   return isActive && m.reminderEnabled;
              // }).length}건 (알림 설정됨)', Icons.medication_outlined),
              SizedBox(height: 20),
              // 잠재 질병 노트 섹션 제목
              Text('나의 잠재 질병 노트', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              // 잠재 질병 메모 목록
              _memos.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text('기록된 잠재 질병 메모가 없습니다.\n아래 버튼을 눌러 추가해보세요.')))
                  : ListView.builder(
                shrinkWrap: true, // ListView가 Column 내에서 사용될 때 필요
                physics: NeverScrollableScrollPhysics(), // 부모 ListView와 스크롤 충돌 방지
                itemCount: _memos.length,
                itemBuilder: (context, index) {
                  final memo = _memos[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(memo.hasReminder ? Icons.alarm_on_outlined : Icons.notes_outlined, color: memo.hasReminder ? Theme.of(context).primaryColor : Colors.grey[600]),
                      title: Text(memo.memoName.isNotEmpty ? memo.memoName : '(이름 없음)', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold)), // Corrected field name
                      subtitle: Text('${memo.memoContent}\n' // Corrected field name
                          '기록일: ${memo.createdAt.year}년 ${memo.createdAt.month}월 ${memo.createdAt.day}일'
                          '${memo.hasReminder && memo.reminderTime != null ? "\n리마인더: ${memo.reminderTime!.year}-${memo.reminderTime!.month}-${memo.reminderTime!.day} ${memo.reminderTime!.hour}:${memo.reminderTime!.minute.toString().padLeft(2, '0')}" : ""}'),
                      trailing: Icon(Icons.edit_note_outlined, size: 20),
                      onTap: () => _navigateToPotentialDiseaseManagement(memoToEdit: memo), // 메모 탭 시 수정 화면으로 이동
                      isThreeLine: true, // 리마인더가 있으면 3줄로 표시
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              // 잠재 질병 노트 추가/관리 버튼
              ElevatedButton.icon(icon: Icon(Icons.add_comment_outlined), onPressed: () => _navigateToPotentialDiseaseManagement(), label: Text('잠재 질병 노트 추가/관리'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50))),
            ],
          ),
        ),
      ),
    );
  }

  // 정보 카드 위젯 빌더
  Widget _buildInfoCard(BuildContext context, String title, String content, IconData icon, {bool isSummary = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: isSummary ? 40 : 30, color: Theme.of(context).primaryColor),
            SizedBox(width: 16),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontSize: isSummary ? 18 : 16, fontWeight: FontWeight.bold)),
                  if (content.isNotEmpty) ...[SizedBox(height: 4), Text(content, style: TextStyle(fontSize: 14))]
                ])),
            if (isSummary) Icon(Icons.arrow_forward_ios_outlined, size: 16, color: Colors.grey)
          ],
        ),
      ),
    );
  }
}