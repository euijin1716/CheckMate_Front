// lib/screens/manage_diagnosed_diseases_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/main.dart'; // dataService 접근을 위해 main.dart 임포트
import 'package:health_app/models/diagnosed_disease.dart'; // 올바른 DiagnosedDisease 모델 임포트

class ManageDiagnosedDiseasesScreen extends StatefulWidget {
  @override
  _ManageDiagnosedDiseasesScreenState createState() => _ManageDiagnosedDiseasesScreenState();
}

class _ManageDiagnosedDiseasesScreenState extends State<ManageDiagnosedDiseasesScreen> {
  final _diseaseNameController = TextEditingController();
  final _memoController = TextEditingController();

  DateTime _diagnosedDate = DateTime.now();
  late List<DiagnosedDisease> _diagnosedDiseases;
  bool _dataChanged = false;

  @override
  void initState() {
    super.initState();
    _loadDiagnosedDiseases();
  }

  void _loadDiagnosedDiseases() {
    if (!mounted) return;
    setState(() {
      _diagnosedDiseases = dataService.getDiagnosedDiseases();
    });
  }

  Future<void> _selectDiagnosedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _diagnosedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _diagnosedDate) {
      if (!mounted) return;
      setState(() {
        _diagnosedDate = picked;
      });
    }
  }

  void _addDiagnosedDisease() {
    if (_diseaseNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('질환명을 입력해주세요.'), backgroundColor: Colors.orangeAccent));
      return;
    }
    final newDisease = DiagnosedDisease(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _diseaseNameController.text.trim(),
      diagnosedDate: _diagnosedDate,
      memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
    );
    dataService.addDiagnosedDisease(newDisease);
    _diseaseNameController.clear();
    _memoController.clear();
    _diagnosedDate = DateTime.now();
    _loadDiagnosedDiseases();
    _dataChanged = true;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${newDisease.name}이(가) 진단 질환으로 추가되었습니다.'), backgroundColor: Colors.green));
  }

  // 진단 질환 삭제 확인 대화상자 표시 및 처리
  void _deleteDiagnosedDisease(String id, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('진단 질환 삭제'),
        content: Text("'$name'을(를) 진단 질환 목록에서 삭제하시겠습니까?"),
        actions: <Widget>[
          TextButton(child: Text('취소'), onPressed: () => Navigator.of(context).pop()),
          TextButton(
            child: Text('삭제', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(context).pop(); // 대화상자 닫기
              try {
                await dataService.deleteDiagnosedDiseaseFromServer(id); // 서버 API 호출
                _dataChanged = true;
                _loadDiagnosedDiseases(); // 삭제 후 목록 새로고침
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$name'이(가) 삭제되었습니다.")));
              } catch (e) {
                print('진단 질환 삭제 중 오류 발생: $e');
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$name' 삭제에 실패했습니다: $e"), backgroundColor: Colors.redAccent));
              }
            },
          ),
        ],
      ),
    );
  }

  void _editDiagnosedDisease(String id, String name) {
    // 여기에 진단 질환 수정 로직을 추가할 수 있습니다.
    // 예를 들어, 새로운 화면으로 이동하거나 다이얼로그를 띄워서 수정할 수 있습니다.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\'$name\' 질환 수정 기능은 아직 구현되지 않았습니다.')));
  }

  // 질환 정보 보기 다이얼로그 표시 (새로 추가된 메서드)
  void _showDiseaseInfoDialog(String diseaseName) async {
    String explanation = '설명을 불러오는 중...';
    try {
      // DataService를 통해 질병 검색 API 호출
      final results = await dataService.searchDiseases(diseaseName);
      if (results.isNotEmpty) {
        // 첫 번째 결과의 설명을 사용 (가장 관련성 높은 결과로 가정)
        explanation = results.first['explain'] ?? '설명 없음';
      } else {
        explanation = '해당 질환에 대한 설명을 찾을 수 없습니다.';
      }
    } catch (e) {
      explanation = '질병 설명을 불러오는 데 실패했습니다: $e';
      print('Error fetching disease explanation: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(diseaseName, style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(explanation),
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

  @override
  void dispose() {
    _diseaseNameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('현재 진단 질환 관리'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _dataChanged),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('등록된 진단 질환 목록', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Divider(),
            Expanded(
              child: _diagnosedDiseases.isEmpty
                  ? Center(child: Text('등록된 진단 질환이 없습니다.'))
                  : ListView.builder(
                itemCount: _diagnosedDiseases.length,
                itemBuilder: (context, index) {
                  final disease = _diagnosedDiseases[index];
                  return Card(
                    child: ListTile(
                      title: Text(disease.name),
                      subtitle: Text('진단일: ${disease.diagnosedDate.year}-${disease.diagnosedDate.month.toString().padLeft(2, '0')}-${disease.diagnosedDate.day.toString().padLeft(2, '0')}'),
                      trailing: Row( // Wrap multiple widgets in a Row
                        mainAxisSize: MainAxisSize.min, // To make the Row take minimum space
                        children: [
                          IconButton( // 정보 보기 아이콘 추가
                            icon: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                            onPressed: () => _showDiseaseInfoDialog(disease.name),
                            tooltip: '질환 정보 보기',
                          ),
                          // 기존 수정 아이콘 제거
                          // IconButton(
                          //   icon: Icon(Icons.edit_outlined, color: Colors.blueAccent), // 수정 아이콘 색상 변경
                          //   onPressed: () => _editDiagnosedDisease(disease.id, disease.name),
                          //   tooltip: '수정',
                          // ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteDiagnosedDisease(disease.id, disease.name),
                            tooltip: '삭제',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}