// lib/screens/manage_concerned_diseases_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/main.dart'; // dataService 접근을 위해 main.dart 임포트
import 'package:health_app/models/concerned_disease.dart'; // 모델 임포트

class ManageConcernedDiseasesScreen extends StatefulWidget {
  @override
  _ManageConcernedDiseasesScreenState createState() => _ManageConcernedDiseasesScreenState();
}

class _ManageConcernedDiseasesScreenState extends State<ManageConcernedDiseasesScreen> {
  final _diseaseNameController = TextEditingController();
  late List<ConcernedDisease> _concernedDiseaseListLocal; // 관심 질환 목록
  bool _dataChanged = false; // 데이터 변경 여부 (이전 화면으로 돌아갈 때 사용)
  List<Map<String, String>> _searchResults = []; // 질병 검색 결과 (타입 변경)
  bool _isSearching = false; // 검색 중 여부

  @override
  void initState() {
    super.initState();
    _loadConcernedDiseases(); // 초기 관심 질환 데이터 로드
  }

  // 관심 질환 목록을 다시 로드하는 함수
  void _loadConcernedDiseases() {
    if (!mounted) return; // 위젯이 dispose되지 않았는지 확인
    setState(() {
      _concernedDiseaseListLocal = dataService.getConcernedDiseaseList();
    });
  }

  // 질병 검색 함수
  void _searchDiseases(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await dataService.searchDiseases(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching diseases: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('질병 검색 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  // 관심 질환 추가
  void _addConcernedDisease(String name) {
    // 이미 추가된 질병인지 확인
    if (_concernedDiseaseListLocal.any((d) => d.name == name)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미 추가된 질환입니다.'), backgroundColor: Colors.orangeAccent));
      return;
    }

    final newDisease = ConcernedDisease(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name);
    dataService.addOrUpdateConcernedDisease(newDisease); // DataService를 통해 관심 질환 추가
    _diseaseNameController.clear(); // 입력 필드 초기화
    _loadConcernedDiseases(); // 목록 새로고침
    _dataChanged = true; // 데이터 변경 플래그 설정
    setState(() {
      _searchResults = []; // 검색 결과 초기화
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${newDisease.name}이(가) 관심 질환으로 추가되었습니다.'), backgroundColor: Colors.green));
  }

  // 관심 질환 삭제 확인 대화상자 표시 및 처리
  void _deleteConcernedDisease(String id, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('관심 질환 삭제'),
        content: Text("'$name'을(를) 관심 질환 목록에서 삭제하시겠습니까?"),
        actions: <Widget>[
          TextButton(child: Text('취소'), onPressed: () => Navigator.of(context).pop()),
          TextButton(
            child: Text('삭제', style: TextStyle(color: Colors.red)),
            onPressed: () {
              dataService.deleteConcernedDisease(id); // DataService를 통해 관심 질환 삭제
              _loadConcernedDiseases(); // 목록 새로고침
              _dataChanged = true; // 데이터 변경 플래그 설정
              Navigator.of(context).pop(); // 대화상자 닫기
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$name'이(가) 삭제되었습니다.")));
            },
          ),
        ],
      ),
    );
  }

  // 관심 질환 상세 정보 표시 및 수정 다이얼로그
  void _showDiseaseDetailsDialog(ConcernedDisease disease) {
    // 다이얼로그 내에서 사용할 TextEditingController
    final _descriptionController = TextEditingController(text: disease.description ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(disease.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('설명:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5, // 여러 줄 입력 가능
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: '질환에 대한 설명을 입력하세요.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
                _descriptionController.dispose(); // 컨트롤러 해제
              },
            ),
            TextButton(
              child: Text('저장', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                // 수정된 설명 저장 로직
                disease.description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();
                dataService.addOrUpdateConcernedDisease(disease); // DataService를 통해 업데이트
                _loadConcernedDiseases(); // 목록 새로고침
                Navigator.of(context).pop();
                _descriptionController.dispose(); // 컨트롤러 해제
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('설명이 저장되었습니다.')));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('관심 질환 관리'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _dataChanged), // 데이터 변경 여부 반환
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('관심 있는 질환을 검색하여 등록하고 관리하세요.', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            // 질병 검색 입력 필드
            TextField(
              controller: _diseaseNameController,
              decoration: InputDecoration(
                hintText: '질환명 검색...',
                prefixIcon: Icon(Icons.search_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              onChanged: (value) {
                _searchDiseases(value);
              },
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                // 검색 결과가 있을 경우 첫 번째 결과를 자동으로 추가
                if (_searchResults.isNotEmpty) {
                  _addConcernedDisease(_searchResults.first['name']!); // 'name' 키로 접근
                }
              },
            ),
            SizedBox(height: 10),
            // 검색 결과 표시
            _isSearching
                ? Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty && _diseaseNameController.text.isNotEmpty
                ? Center(child: Text('검색 결과가 없습니다.'))
                : _searchResults.isNotEmpty
                ? Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text(result['name']!), // 'name' 키로 접근
                      trailing: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
                      onTap: () {
                        _addConcernedDisease(result['name']!); // 'name' 키로 접근
                      },
                    ),
                  );
                },
              ),
            )
                : SizedBox.shrink(), // 검색어가 비어있을 때는 검색 결과 영역 숨김
            SizedBox(height: 20),
            Text('등록된 관심 질환 목록', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Divider(),
            // 관심 질환 목록
            Expanded(
              child: _concernedDiseaseListLocal.isEmpty
                  ? Center(child: Text('등록된 관심 질환이 없습니다.'))
                  : ListView.builder(
                itemCount: _concernedDiseaseListLocal.length,
                itemBuilder: (context, index) {
                  final disease = _concernedDiseaseListLocal[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.star_border_purple500_outlined, color: Colors.amber[700]), // 아이콘 유지
                      title: Text(disease.name),
                      subtitle: disease.description != null && disease.description!.isNotEmpty
                          ? Text(disease.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null, // 설명이 있으면 표시
                      trailing: IconButton(icon: Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteConcernedDisease(disease.id, disease.name)), // 삭제 버튼
                      onTap: () => _showDiseaseDetailsDialog(disease), // 탭 시 상세 정보 다이얼로그 표시
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