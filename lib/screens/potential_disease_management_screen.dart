// lib/screens/potential_disease_management_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/main.dart'; // dataService 접근을 위해 main.dart 임포트
import 'package:health_app/models/potential_disease_memo.dart'; // 모델 임포트

class PotentialDiseaseManagementScreen extends StatefulWidget {
  final PotentialDiseaseMemo? memoToEdit; // 수정할 메모가 있을 경우 전달받음
  const PotentialDiseaseManagementScreen({Key? key, this.memoToEdit}) : super(key: key);
  @override
  _PotentialDiseaseManagementScreenState createState() => _PotentialDiseaseManagementScreenState();
}

class _PotentialDiseaseManagementScreenState extends State<PotentialDiseaseManagementScreen> {
  final _memoContentController = TextEditingController(); // 메모 내용 컨트롤러
  final _memoNameController = TextEditingController(); // 질병명 또는 메모 이름 컨트롤러

  late List<PotentialDiseaseMemo> _memos = []; // 초기화 추가
  bool _hasReminder = false; // 리마인더 설정 여부
  DateTime? _selectedReminderTime; // 선택된 리마인더 시간
  bool _isEditMode = false; // 수정 모드 여부
  bool _dataChanged = false; // 데이터 변경 여부 (이전 화면으로 돌아갈 때 사용)

  // 질병 검색 관련 변수
  List<Map<String, String>> _diseaseSearchResults = [];
  bool _isSearchingDisease = false;

  @override
  void initState() {
    super.initState();
    // 수정 모드인 경우 기존 메모 데이터로 필드 초기화
    if (widget.memoToEdit != null) {
      _isEditMode = true;
      _memoContentController.text = widget.memoToEdit!.memoContent; // Corrected field name
      _memoNameController.text = widget.memoToEdit!.memoName; // Corrected field name
      _hasReminder = widget.memoToEdit!.hasReminder;
      _selectedReminderTime = widget.memoToEdit!.reminderTime;
    }
    _loadMemos(); // 메모 목록 로드
  }

  // 메모 목록을 다시 로드하는 함수
  Future<void> _loadMemos() async {
    if (!mounted) return; // 위젯이 dispose되지 않았는지 확인
    try {
      final fetchedMemos = await dataService.fetchPotentialDiseaseMemosFromServer();
      setState(() {
        _memos = fetchedMemos;
      });
    } catch (e) {
      print('메모 로드 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메모를 불러오는 데 실패했습니다: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // 리마인더 날짜 및 시간 선택 다이얼로그 표시
  Future<void> _pickReminderDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedReminderTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)), // 5년 후까지 선택 가능
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedReminderTime ?? DateTime.now()),
      );
      if (pickedTime != null) {
        if (!mounted) return;
        setState(() {
          // 선택된 날짜와 시간을 합쳐서 리마인더 시간 설정
          _selectedReminderTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
          _hasReminder = true; // 리마인더 활성화
        });
      }
    }
  }

  // 질병 검색 함수
  void _searchDiseases(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _diseaseSearchResults = [];
        _isSearchingDisease = false;
      });
      return;
    }

    setState(() {
      _isSearchingDisease = true;
      _diseaseSearchResults = [];
    });

    try {
      final results = await dataService.searchDiseases(query);
      setState(() {
        _diseaseSearchResults = results;
        _isSearchingDisease = false;
      });
    } catch (e) {
      print('Error searching diseases: $e');
      setState(() {
        _diseaseSearchResults = [];
        _isSearchingDisease = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('질병 검색 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // 질병 선택 처리 (자동완성 목록에서 선택 시)
  void _selectDisease(String diseaseName) {
    setState(() {
      _memoNameController.text = diseaseName;
      _diseaseSearchResults = []; // 검색 결과 초기화
    });
  }

  // 메모 저장 또는 업데이트
  Future<void> _saveOrUpdateMemo() async {
    if (_memoContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('메모 내용을 입력해주세요.'), backgroundColor: Colors.orangeAccent));
      return;
    }
    if (_memoNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('질병명 또는 메모 이름을 입력해주세요.'), backgroundColor: Colors.orangeAccent));
      return;
    }

    // 새 메모 또는 기존 메모 업데이트 객체 생성
    final memo = PotentialDiseaseMemo(
      id: _isEditMode ? widget.memoToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(), // 수정 모드면 기존 ID, 아니면 새 ID
      memoContent: _memoContentController.text.trim(), // Corrected named parameter
      memoName: _memoNameController.text.trim(), // Corrected named parameter
      createdAt: _isEditMode ? widget.memoToEdit!.createdAt : DateTime.now(), // 수정 모드면 기존 생성일, 아니면 현재 시간
      hasReminder: _hasReminder,
      reminderTime: _hasReminder ? _selectedReminderTime : null,
      diseaseId: null, // Backend will link disease via memoName
    );

    try {
      if (_isEditMode) {
        await dataService.updatePotentialDiseaseMemoToServer(memo); // 서버에 업데이트
      } else {
        await dataService.savePotentialDiseaseMemoToServer(memo); // 서버에 저장
      }
      _dataChanged = true; // 데이터 변경 플래그 설정

      // 수정 모드가 아니면 입력 필드 초기화
      if (!_isEditMode) {
        _memoContentController.clear();
        _memoNameController.clear();
        if (mounted) {
          setState(() {
            _hasReminder = false;
            _selectedReminderTime = null;
          });
        }
      }
      // _loadMemos() is called by the API call method, so no need to call it directly here again
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditMode ? '메모가 수정되었습니다.' : '새로운 메모가 추가되었습니다.'), backgroundColor: Colors.green));
    } catch (e) {
      print('메모 저장/업데이트 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('메모 저장/업데이트 실패: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  // 메모 삭제 확인 대화상자 표시 및 처리
  void _deleteMemo(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('메모 삭제'),
        content: Text('정말로 이 메모를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
        actions: <Widget>[
          TextButton(child: Text('취소'), onPressed: () => Navigator.of(context).pop()),
          TextButton(
            child: Text('삭제', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(context).pop(); // 대화상자 닫기
              try {
                await dataService.deletePotentialDiseaseMemoFromServer(id); // 서버에서 삭제
                _dataChanged = true; // 데이터 변경 플래그 설정
                // _loadMemos() is called by the API call method, so no need to call it directly here again
                // 수정 중인 메모가 삭제된 경우 이전 화면으로 돌아감
                if (_isEditMode && widget.memoToEdit?.id == id) {
                  if (mounted) Navigator.pop(context, true);
                }
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('메모가 삭제되었습니다.')));
              } catch (e) {
                print('메모 삭제 중 오류 발생: $e');
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('메모 삭제 실패: $e'), backgroundColor: Colors.redAccent));
              }
            },
          ),
        ],
      ),
    );
  }

  // 질병 정보 보기 다이얼로그 표시 (새로 추가된 메서드)
  void _showDiseaseInfoDialog(String diseaseName) async {
    String explanation = '설명을 불러오는 중...';
    try {
      final results = await dataService.searchDiseases(diseaseName);
      if (results.isNotEmpty) {
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
    _memoContentController.dispose();
    _memoNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '잠재 질병 노트 수정' : '잠재 질병 노트 관리'),
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
            Text(_isEditMode ? '메모를 수정하세요.' : '새로운 증상이나 건강 관련 메모를 기록하세요.', style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            // 질병명/메모 이름 입력 필드 (검색 기능 포함)
            TextFormField(
              controller: _memoNameController,
              decoration: InputDecoration(
                hintText: '질병명 또는 메모 이름을 검색/입력...',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(icon: Icon(Icons.clear), onPressed: () => _memoNameController.clear()),
              ),
              onChanged: (value) {
                _searchDiseases(value); // 입력값 변경 시 질병 검색
              },
              textInputAction: TextInputAction.next,
            ),
            // 질병 검색 결과 표시
            if (_isSearchingDisease)
              Center(child: CircularProgressIndicator())
            else if (_diseaseSearchResults.isNotEmpty)
              Container(
                constraints: BoxConstraints(maxHeight: 150), // 최대 높이 지정
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _diseaseSearchResults.length,
                  itemBuilder: (context, index) {
                    final result = _diseaseSearchResults[index];
                    return ListTile(
                      title: Text(result['name']!),
                      trailing: Icon(Icons.add),
                      onTap: () => _selectDisease(result['name']!),
                    );
                  },
                ),
              ),
            SizedBox(height: 10),
            // 메모 내용 입력 필드
            TextField(
              controller: _memoContentController,
              decoration: InputDecoration(
                hintText: '메모 내용 입력...',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(icon: Icon(Icons.clear), onPressed: () => _memoContentController.clear()),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 리마인더 설정 체크박스
                      Checkbox(
                        value: _hasReminder,
                        onChanged: (bool? value) {
                          setState(() {
                            _hasReminder = value ?? false;
                            if (!_hasReminder) _selectedReminderTime = null; // 리마인더 해제 시 시간 초기화
                            else if (_selectedReminderTime == null) _pickReminderDateTime(); // 리마인더 설정 시 시간 선택
                          });
                        },
                      ),
                      // 리마인더 시간 표시 및 선택 버튼
                      Flexible(
                          child: GestureDetector(
                              onTap: _hasReminder ? _pickReminderDateTime : null,
                              child: Text(
                                '리마인더 설정${_hasReminder && _selectedReminderTime != null ? "\n(${_selectedReminderTime!.year}-${_selectedReminderTime!.month.toString().padLeft(2, '0')}-${_selectedReminderTime!.day.toString().padLeft(2, '0')} ${_selectedReminderTime!.hour.toString().padLeft(2, '0')}:${_selectedReminderTime!.minute.toString().padLeft(2, '0')})" : ""}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ))),
                      if (_hasReminder)
                        IconButton(
                          icon: Icon(Icons.edit_calendar_outlined, color: Theme.of(context).primaryColor),
                          tooltip: '리마인더 시간 변경',
                          onPressed: _pickReminderDateTime,
                        )
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // 저장/수정 버튼
                ElevatedButton.icon(icon: Icon(Icons.save_outlined), onPressed: _saveOrUpdateMemo, label: Text(_isEditMode ? '수정' : '저장'), style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10))),
              ],
            ),
            SizedBox(height: 20),
            // 수정 모드가 아닐 때만 메모 목록 표시
            if (!_isEditMode) ...[
              Text('나의 노트 목록', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Divider(),
              Expanded(
                child: _memos.isEmpty
                    ? Center(child: Text('기록된 메모가 없습니다.'))
                    : ListView.builder(
                  itemCount: _memos.length,
                  itemBuilder: (context, index) {
                    final memo = _memos[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6.0),
                      child: ListTile(
                        leading: Icon(memo.hasReminder ? Icons.alarm_on_outlined : Icons.notes_outlined, color: memo.hasReminder ? Theme.of(context).primaryColor : Colors.grey[600]),
                        title: Text(memo.memoName.isNotEmpty ? memo.memoName : '(이름 없음)', style: TextStyle(fontWeight: FontWeight.bold)), // memoName 표시
                        subtitle: Text(
                            '${memo.memoContent}\n' // Corrected field name
                                '기록일: ${memo.createdAt.year}-${memo.createdAt.month.toString().padLeft(2, '0')}-${memo.createdAt.day.toString().padLeft(2, '0')} ${memo.createdAt.hour.toString().padLeft(2, '0')}:${memo.createdAt.minute.toString().padLeft(2, '0')}'
                                '${memo.hasReminder && memo.reminderTime != null ? "\n리마인더: ${memo.reminderTime!.year}-${memo.reminderTime!.month.toString().padLeft(2, '0')}-${memo.reminderTime!.day.toString().padLeft(2, '0')} ${memo.reminderTime!.hour.toString().padLeft(2, '0')}:${memo.reminderTime!.minute.toString().padLeft(2, '0')}" : ""}'),
                        isThreeLine: true, // 메모 내용과 리마인더 시간까지 표시할 경우 3줄이 될 수 있음
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                              onPressed: () => _showDiseaseInfoDialog(memo.memoName), // Corrected field name
                              tooltip: '질환 정보 보기',
                            ),
                            IconButton(icon: Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteMemo(memo.id)),
                          ],
                        ),
                        onTap: () => Navigator.pushReplacementNamed(context, '/potential_disease_management', arguments: memo), // 탭 시 해당 메모 수정 화면으로 이동
                      ),
                    );
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}