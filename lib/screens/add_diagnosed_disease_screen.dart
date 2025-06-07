// lib/screens/add_diagnosed_disease_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/main.dart';
import 'package:health_app/models/diagnosed_disease.dart'; // 올바른 DiagnosedDisease 모델 임포트
import 'package:health_app/models/medication.dart';
import 'package:flutter/services.dart'; // FilteringTextInputFormatter를 위해 추가

class AddDiagnosedDiseaseScreen extends StatefulWidget {
  const AddDiagnosedDiseaseScreen({Key? key}) : super(key: key);

  @override
  _AddDiagnosedDiseaseScreenState createState() => _AddDiagnosedDiseaseScreenState();
}

class _AddDiagnosedDiseaseScreenState extends State<AddDiagnosedDiseaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _diseaseNameController = TextEditingController();
  DateTime _selectedDiagnosedDate = DateTime.now();

  // 질병 정보 파트에서 사용할 복약 알림 설정 변수
  bool _isAlarmEnabled = false; // _hasDiseaseReminder에서 이름 변경
  // 변경: 단일 TimeOfDay 대신 여러 알람 시간을 저장할 리스트
  List<TimeOfDay?> _diseaseAlarmTimes = List.filled(4, null); // alarmTimer1 ~ alarmTimer4

  // 복용 횟수 입력 컨트롤러
  final TextEditingController _numTimesPerDayController = TextEditingController(text: '3'); // 기본값 3회

  // 각 횟수별 기본 알림 시간 정의
  final Map<int, List<TimeOfDay>> _defaultAlarmTimes = {
    1: [TimeOfDay(hour: 12, minute: 30)], // 점심
    2: [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 18, minute: 30)], // 아침, 저녁
    3: [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 12, minute: 30), TimeOfDay(hour: 18, minute: 30)], // 아침, 점심, 저녁
    4: [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 12, minute: 30), TimeOfDay(hour: 18, minute: 30), TimeOfDay(hour: 22, minute: 0)], // 아침, 점심, 저녁, 취침 전
  };

  // 복약 정보 입력 필드 세트
  final List<MedicationFormEntry> _medicationEntries = [];

  // 질병 검색 관련 변수
  List<Map<String, String>> _diseaseSearchResults = [];
  bool _isSearchingDisease = false;

  // 약 이름 자동 완성 관련 변수
  List<Map<String, String>> _medicineSuggestions = [];
  bool _isSearchingMedicine = false;

  @override
  void initState() {
    super.initState();
    _addMedicationEntry(); // 초기 화면에 최소 하나의 복약 정보 입력 필드를 추가

    // 복용 횟수 컨트롤러의 리스너 추가
    _numTimesPerDayController.addListener(_updateDefaultFrequencyForMedications);
    // 초기 알림 시간 설정
    _updateDefaultDiseaseAlarmTimes();
  }

  // 복용 횟수 변경 시 모든 복약 정보의 기본 횟수 업데이트
  void _updateDefaultFrequencyForMedications() {
    final int? currentNum = int.tryParse(_numTimesPerDayController.text);
    if (currentNum != null && currentNum >= 1 && currentNum <= 4) {
      for (var entry in _medicationEntries) {
        // 복약 정보의 1일 횟수 입력란에 기본값으로 적용
        entry.frequencyTimesController.text = currentNum.toString();
      }
    }
  }

  // 질병 알림 시간 기본값 업데이트 (복용 횟수에 따라)
  void _updateDefaultDiseaseAlarmTimes() {
    final int? numTimes = int.tryParse(_numTimesPerDayController.text);
    if (numTimes != null && _defaultAlarmTimes.containsKey(numTimes)) {
      setState(() {
        _diseaseAlarmTimes = List.filled(4, null); // 기존 값 초기화
        final List<TimeOfDay> times = _defaultAlarmTimes[numTimes]!;
        for (int i = 0; i < times.length; i++) {
          _diseaseAlarmTimes[i] = times[i];
        }
      });
    } else {
      setState(() {
        _diseaseAlarmTimes = List.filled(4, null); // 유효하지 않은 경우 모두 null
      });
    }
  }

  @override
  void dispose() {
    _diseaseNameController.dispose();
    _numTimesPerDayController.dispose(); // 컨트롤러 dispose
    for (var entry in _medicationEntries) {
      entry.nameController.dispose();
      entry.doseController.dispose();
      entry.frequencyTimesController.dispose();
      entry.durationDaysController.dispose();
    }
    super.dispose();
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

  // 질병 선택 처리
  void _selectDisease(String diseaseName) {
    setState(() {
      _diseaseNameController.text = diseaseName;
      _diseaseSearchResults = [];
    });
  }

  // 약 이름 검색 함수
  void _searchMedicines(String query, MedicationFormEntry entry) async {
    if (query.trim().isEmpty) {
      setState(() {
        _medicineSuggestions = [];
        _isSearchingMedicine = false;
      });
      return;
    }

    setState(() {
      _isSearchingMedicine = true;
      _medicineSuggestions = [];
    });

    try {
      final results = await dataService.searchMedicines(query);
      setState(() {
        _medicineSuggestions = results; // List<Map<String, String>>으로 직접 할당
        _isSearchingMedicine = false;
      });
    } catch (e) {
      print('Error searching medicines: $e');
      setState(() {
        _medicineSuggestions = [];
        _isSearchingMedicine = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('약 검색 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // 약 이름 선택 처리
  void _selectMedicine(Map<String, String> medicineDetail, MedicationFormEntry entry) { // Map<String, String> 타입으로 변경
    setState(() {
      entry.nameController.text = medicineDetail['medicineName']!; // 'medicineName' 키로 접근
      _medicineSuggestions = [];
    });
  }

  // 복약 정보 입력 필드 세트 추가
  void _addMedicationEntry() {
    final int? currentNumPerDay = int.tryParse(_numTimesPerDayController.text);
    final String initialFrequency = (currentNumPerDay != null && currentNumPerDay >=1 && currentNumPerDay <=4)
        ? currentNumPerDay.toString() : '3'; // 현재 설정된 횟수를 기본값으로 사용, 없으면 3

    setState(() {
      _medicationEntries.add(MedicationFormEntry(
        selectedStartDate: _selectedDiagnosedDate, // 질병 진단 날짜로 기본값 설정
        frequencyTimesController: TextEditingController(text: initialFrequency), // 기본값 3회
        doseController: TextEditingController(text: '1'), // 기본값 1
      ));
    });
  }

  // 복약 정보 입력 필드 세트 삭제
  void _removeMedicationEntry(int index) {
    setState(() {
      // 해당 엔트리의 컨트롤러들을 dispose하여 메모리 누수 방지
      _medicationEntries[index].nameController.dispose();
      _medicationEntries[index].doseController.dispose();
      _medicationEntries[index].frequencyTimesController.dispose();
      _medicationEntries[index].durationDaysController.dispose();
      _medicationEntries.removeAt(index);
    });
  }

  // 진단 날짜 선택 다이얼로그
  Future<void> _selectDiagnosedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDiagnosedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDiagnosedDate) {
      if (!mounted) return;
      setState(() {
        _selectedDiagnosedDate = picked;
        // 질병 진단 날짜가 변경되면 모든 복약 시작일도 업데이트
        for (var entry in _medicationEntries) {
          entry.selectedStartDate = _selectedDiagnosedDate;
          // 시작일이 종료일보다 늦으면 종료일 초기화
          if (entry.selectedEndDate != null && entry.selectedEndDate!.isBefore(entry.selectedStartDate)) {
            entry.selectedEndDate = null;
          }
          entry.updateDurationDays(); // 복약 기간도 업데이트
        }
      });
    }
  }

  // 복약 알림 설정 다이얼로그 표시 (수정됨)
  Future<bool?> _showDiseaseReminderSetupDialog() async {
    int? currentNumTimes = int.tryParse(_numTimesPerDayController.text);
    if (currentNumTimes == null || currentNumTimes < 1 || currentNumTimes > 4) {
      currentNumTimes = 3; // 기본값
    }

    // 로컬 상태를 위한 임시 리스트 (다이얼로그 내에서만 사용)
    List<TimeOfDay?> tempAlarmTimes = List.from(_diseaseAlarmTimes);
    int tempNumTimes = currentNumTimes;
    // final String initialNumTimesText = _numTimesPerDayController.text; // 다이얼로그 열기 전 횟수 값 저장

    return await showDialog<bool?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('복약 알림 시간 설정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1일 복용 횟수:'),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _numTimesPerDayController, // 기존 컨트롤러 사용
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1), // 한자리 숫자만 허용
                      ],
                      decoration: InputDecoration(
                        hintText: '1~4 사이의 숫자 입력',
                        border: OutlineInputBorder(),
                        suffixText: '회',
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          final int? num = int.tryParse(value);
                          if (num != null && num >= 1 && num <= 4) {
                            tempNumTimes = num;
                            tempAlarmTimes = List.filled(4, null); // 횟수 변경 시 시간 초기화
                            final List<TimeOfDay> defaultTimes = _defaultAlarmTimes[tempNumTimes]!;
                            for (int i = 0; i < defaultTimes.length; i++) {
                              tempAlarmTimes[i] = defaultTimes[i];
                            }
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '횟수를 입력해주세요.';
                        }
                        final int? num = int.tryParse(value);
                        if (num == null || num < 1 || num > 4) {
                          return '1~4 사이의 유효한 숫자를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    // 동적으로 시간 선택 위젯 표시
                    if (tempNumTimes >= 1)
                      _buildTimePickerRow(
                        setDialogState,
                        label: _getAlarmLabel(tempNumTimes, 0),
                        initialTime: tempAlarmTimes[0],
                        onTimeSelected: (time) => tempAlarmTimes[0] = time,
                      ),
                    if (tempNumTimes >= 2)
                      _buildTimePickerRow(
                        setDialogState,
                        label: _getAlarmLabel(tempNumTimes, 1),
                        initialTime: tempAlarmTimes[1],
                        onTimeSelected: (time) => tempAlarmTimes[1] = time,
                      ),
                    if (tempNumTimes >= 3)
                      _buildTimePickerRow(
                        setDialogState,
                        label: _getAlarmLabel(tempNumTimes, 2),
                        initialTime: tempAlarmTimes[2],
                        onTimeSelected: (time) => tempAlarmTimes[2] = time,
                      ),
                    if (tempNumTimes >= 4)
                      _buildTimePickerRow(
                        setDialogState,
                        label: _getAlarmLabel(tempNumTimes, 3),
                        initialTime: tempAlarmTimes[3],
                        onTimeSelected: (time) => tempAlarmTimes[3] = time,
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('취소'),
                  onPressed: () {
                    // 취소 시 다이얼로그를 닫고 false를 반환하여 취소되었음을 알림
                    Navigator.of(dialogContext).pop(false);
                  },
                ),
                ElevatedButton(
                  child: Text('설정'),
                  onPressed: () {
                    final int? finalNumTimes = int.tryParse(_numTimesPerDayController.text);
                    if (finalNumTimes != null && finalNumTimes >= 1 && finalNumTimes <= 4) {
                      // 설정이 완료되었으므로 다이얼로그를 닫고 true를 반환
                      setDialogState(() { // 다이얼로그 내부 상태 업데이트 (선택 사항)
                        _diseaseAlarmTimes = List.from(tempAlarmTimes);
                      });
                      Navigator.of(dialogContext).pop(true);
                    } else {
                      // 유효하지 않은 횟수 입력 시 스낵바 표시
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('1~4 사이의 유효한 복용 횟수를 입력해주세요.'), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 알림 시간 레이블을 반환하는 헬퍼 함수
  String _getAlarmLabel(int numTimes, int index) {
    if (numTimes == 1) {
      return '점심';
    } else if (numTimes == 2) {
      return index == 0 ? '아침' : '저녁';
    } else if (numTimes == 3) {
      return index == 0 ? '아침' : (index == 1 ? '점심' : '저녁');
    } else if (numTimes == 4) {
      return index == 0 ? '아침' : (index == 1 ? '점심' : (index == 2 ? '저녁' : '취침 전'));
    }
    return '시간 ${index + 1}'; // Fallback
  }

  // 시간 선택 Row 위젯 빌더
  Widget _buildTimePickerRow(StateSetter setDialogState, {required String label, required TimeOfDay? initialTime, required Function(TimeOfDay) onTimeSelected}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 16))),
          SizedBox(width: 16),
          InkWell(
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: initialTime ?? TimeOfDay.now(),
              );
              if (picked != null) {
                setDialogState(() {
                  onTimeSelected(picked);
                });
              }
            },
            child: Text(
              initialTime == null ? '시간 선택' : initialTime.format(context),
              style: TextStyle(fontSize: 18, color: Theme.of(context).primaryColor),
            ),
          ),
          Icon(Icons.edit, color: Theme.of(context).primaryColor, size: 20),
        ],
      ),
    );
  }

  // 질병 및 복약 정보 등록 처리
  void _registerDiseaseAndMedication() async {
    // Validate all form fields, including those in MedicationFormEntry
    bool allFormsValid = true;
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      allFormsValid = false;
    }
    // 각 복약 정보 엔트리에 대한 추가 유효성 검사
    for (var entry in _medicationEntries) {
      if (entry.nameController.text.trim().isEmpty ||
          entry.doseController.text.trim().isEmpty ||
          int.tryParse(entry.doseController.text.trim()) == null ||
          int.parse(entry.doseController.text.trim()) <= 0 ||
          entry.frequencyTimesController.text.trim().isEmpty ||
          int.tryParse(entry.frequencyTimesController.text.trim()) == null ||
          int.parse(entry.frequencyTimesController.text.trim()) <= 0 ||
          entry.durationDaysController.text.trim().isEmpty || // 복약 일수 추가
          int.tryParse(entry.durationDaysController.text.trim()) == null || // 복약 일수 추가
          int.parse(entry.durationDaysController.text.trim()) <= 0) // 복약 일수 추가
          {
        allFormsValid = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('모든 복약 정보 필드를 올바르게 입력해주세요.'), backgroundColor: Colors.orangeAccent),
        );
        break; // Stop checking if one is invalid
      }
    }


    if (allFormsValid) {
      // DiagnosedDisease 객체 생성
      final newDiagnosedDisease = DiagnosedDisease(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // 고유 ID 생성
        name: _diseaseNameController.text.trim(),
        diagnosedDate: _selectedDiagnosedDate,
      );

      // 여러 Medication 객체 생성
      final List<Medication> medications = [];
      for (var entry in _medicationEntries) {
        if (entry.nameController.text.trim().isNotEmpty) {
          // 약 이름이 비어있지 않은 경우만 유효한 복약 정보로 간주
          // 유효성 검사를 통과했으므로 int.parse()를 사용합니다.
          final int numPerDay = int.parse(entry.frequencyTimesController.text.trim());
          final int dose = int.parse(entry.doseController.text.trim());
          final int durationDays = int.parse(entry.durationDaysController.text.trim()); // 복약 일수 파싱

          // 복약 시작일과 복약 일수를 사용하여 종료일 계산
          final DateTime calculatedEndDate = entry.selectedStartDate.add(Duration(days: durationDays - 1));


          print('DEBUG: Medication - Name: ${entry.nameController.text}, Dose: $dose, DoseType: ${entry.selectedDoseType}, NumPerDay: $numPerDay, StartDate: ${entry.selectedStartDate}, EndDate: $calculatedEndDate');


          medications.add(
            Medication(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_med_${medications.length}', // 고유 ID 생성
              name: entry.nameController.text.trim(),
              dosage: '', // 사용하지 않음 (요구사항)
              frequency: '1일 ${numPerDay}회', // 새로운 형식: '1일 X회'
              startDate: entry.selectedStartDate,
              endDate: calculatedEndDate, // 계산된 종료일 사용
              // reminderEnabled, reminderTime 삭제
              associatedDiseaseName: _diseaseNameController.text.trim(), // 등록된 질병명 연결
              dose: dose, // dose 추가
              doseType: entry.selectedDoseType, // doseType 추가
              numPerDayValue: numPerDay, // numPerDayValue 필드 추가
            ),
          );
        }
      }

      if (medications.isEmpty) {
        // 등록할 약이 없는 경우 스낵바 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('하나 이상의 복약 정보를 입력해주세요.'), backgroundColor: Colors.orangeAccent),
        );
        return;
      }

      // DataService를 통해 백엔드로 데이터 전송
      try {
        final int? numPerDayForPrescription = _isAlarmEnabled ? int.tryParse(_numTimesPerDayController.text) : null;
        final List<TimeOfDay?> alarmTimesForPrescription = _isAlarmEnabled ? _diseaseAlarmTimes : List.filled(4, null);

        final int prescriptionId = await dataService.registerDiseaseAndMedications(
          newDiagnosedDisease,
          medications,
          numPerDayForPrescription: numPerDayForPrescription,
          alarmTimesForPrescription: alarmTimesForPrescription,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('질병 및 복약 정보가 성공적으로 등록되었습니다.')),
          );
          Navigator.pop(context, true); // 이전 화면으로 돌아가기
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('정보 등록 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  // 날짜 선택 위젯 빌더 (AddDiagnosedDiseaseScreen과 동일하게 유지)
  Widget _buildDateSelector({
    required BuildContext context,
    required String title,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
    required bool isStartDate,
    bool allowClear = false,
    VoidCallback? onClearDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                selectedDate == null
                    ? (isStartDate ? '날짜를 선택해주세요' : '종료일 미지정')
                    : '${selectedDate.year}년 ${selectedDate.month.toString().padLeft(2, '0')}월 ${selectedDate.day.toString().padLeft(2, '0')}일',
                style: TextStyle(
                    fontSize: 18,
                    color: selectedDate == null
                        ? Colors.grey
                        : Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ),
            TextButton.icon(
              icon: Icon(Icons.calendar_today_outlined),
              label: Text(selectedDate == null ? '날짜 선택' : '날짜 변경'),
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: isStartDate
                      ? DateTime(DateTime.now().year - 5)
                      : (selectedDate ??
                      DateTime.now().add(Duration(days: -365))),
                  lastDate: isStartDate
                      ? DateTime(DateTime.now().year + 5)
                      : DateTime(DateTime.now().year + 5),
                  helpText: title,
                );
                if (picked != null) onDateSelected(picked);
              },
            ),
            if (allowClear && selectedDate != null && onClearDate != null)
              IconButton(
                  icon: Icon(Icons.clear, color: Colors.redAccent),
                  onPressed: onClearDate),
          ],
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('질병 및 복약 정보 등록'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('질병 정보', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              // 질병 검색 입력 필드
              TextFormField(
                controller: _diseaseNameController,
                decoration: InputDecoration(
                  labelText: '질병명 검색 또는 직접 입력...',
                  prefixIcon: Icon(Icons.search_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                onChanged: (value) {
                  _searchDiseases(value);
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  // 검색 결과가 있으면 첫 번째 결과를 선택, 없으면 입력값 그대로 사용
                  if (_diseaseSearchResults.isNotEmpty) {
                    _selectDisease(_diseaseSearchResults.first['name']!); // 'name' 키로 접근
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '질병명을 입력해주세요.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              // 질병 검색 결과 표시
              _isSearchingDisease
                  ? Center(child: CircularProgressIndicator())
                  : _diseaseSearchResults.isEmpty && _diseaseNameController.text.isNotEmpty
                  ? Center(child: Text('검색 결과가 없습니다.'))
                  : _diseaseSearchResults.isNotEmpty
                  ? Container(
                height: 100, // 높이 제한
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _diseaseSearchResults.length,
                  itemBuilder: (context, index) {
                    final result = _diseaseSearchResults[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text(result['name']!), // 'name' 키로 접근
                        onTap: () {
                          _selectDisease(result['name']!); // 'name' 키로 접근
                        },
                      ),
                    );
                  },
                ),
              )
                  : SizedBox.shrink(),
              SizedBox(height: 15),
              ListTile(
                title: Text('진단 날짜: ${_selectedDiagnosedDate.year}-${_selectedDiagnosedDate.month.toString().padLeft(2, '0')}-${_selectedDiagnosedDate.day.toString().padLeft(2, '0')}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDiagnosedDate(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: Colors.grey),
                ),
              ),
              SizedBox(height: 15),
              // 질병 정보 파트에 복약 알림 설정 추가
              SwitchListTile(
                title: Text('복약 알림 설정'),
                subtitle: _isAlarmEnabled && _diseaseAlarmTimes.any((element) => element != null)
                    ? Text('1일 ${_numTimesPerDayController.text}회: ${_diseaseAlarmTimes.where((e) => e != null).map((t) => t!.format(context)).join(', ')}')
                    : null,
                value: _isAlarmEnabled,
                onChanged: (bool value) async {
                  // 먼저 스위치 상태를 즉시 반영
                  setState(() {
                    _isAlarmEnabled = value;
                  });

                  if (value) { // 스위치를 켜는 경우
                    // 다이얼로그를 호출하고 반환되는 결과를 기다림
                    final bool? dialogResult = await _showDiseaseReminderSetupDialog();
                    if (!mounted) return;
                    setState(() {
                      // 다이얼로그 결과에 따라 _isAlarmEnabled 업데이트
                      // dialogResult가 true이면 '설정' 버튼을 눌렀으므로 켠다.
                      // dialogResult가 false이면 '취소' 버튼을 눌렀으므로 끈다.
                      // dialogResult가 null이면 (예: 뒤로가기 버튼으로 닫힘) false로 간주하여 끈다.
                      _isAlarmEnabled = dialogResult ?? false;

                      // 만약 알림이 최종적으로 설정되지 않았다면 (취소되었거나 유효하지 않은 입력)
                      if (!_isAlarmEnabled) {
                        _numTimesPerDayController.text = '3'; // 복용 횟수 컨트롤러 초기값으로 복구
                        _diseaseAlarmTimes = List.filled(4, null); // 알림 시간 초기화
                      }
                    });
                  } else { // 스위치를 끄는 경우 (이 경우 알림 시간은 유지)
                    // _isAlarmEnabled는 이미 false로 설정됨
                    // _diseaseAlarmTimes와 _numTimesPerDayController.text는 유지
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('질병 복약 알림 ${value ? "켬" : "끔"}')));
                },
              ),
              SizedBox(height: 30),
              // 복약 정보 섹션 (동적으로 추가/삭제 가능)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('복약 정보', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
                    onPressed: _addMedicationEntry,
                    tooltip: '복약 정보 추가',
                  ),
                ],
              ),
              SizedBox(height: 10),
              // 여러 개의 복약 정보 입력 필드 리스트
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // 부모 스크롤과 충돌 방지
                itemCount: _medicationEntries.length,
                itemBuilder: (context, index) {
                  return _buildMedicationEntryCard(context, _medicationEntries[index], index);
                },
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(Icons.save_outlined),
                onPressed: _registerDiseaseAndMedication,
                label: Text('정보 등록', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 각 복약 정보 입력 필드 세트를 위한 카드 위젯
  Widget _buildMedicationEntryCard(BuildContext context, MedicationFormEntry entry, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('복약 #${index + 1}', style: Theme.of(context).textTheme.titleMedium),
                if (_medicationEntries.length > 1) // 최소 1개는 유지
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    onPressed: () => _removeMedicationEntry(index),
                    tooltip: '복약 정보 삭제',
                  ),
              ],
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: entry.nameController,
              decoration: InputDecoration(
                labelText: '약 이름',
                prefixIcon: Icon(Icons.medication_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              onChanged: (value) {
                _searchMedicines(value, entry);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '약 이름을 입력해주세요.';
                }
                return null;
              },
            ),
            if (_isSearchingMedicine)
              Center(child: CircularProgressIndicator())
            else if (_medicineSuggestions.isNotEmpty)
              Container(
                height: 100, // 제한된 높이
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _medicineSuggestions.length,
                  itemBuilder: (context, suggestionIndex) {
                    final suggestion = _medicineSuggestions[suggestionIndex];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 2.0),
                      child: ListTile(
                        title: Text(suggestion['medicineName']!), // 'medicineName' 키로 접근
                        onTap: () {
                          _selectMedicine(suggestion, entry);
                        },
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 15),
            // 용량 입력 필드
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: entry.doseController,
                    decoration: InputDecoration(
                      labelText: '용량',
                      prefixIcon: Icon(Icons.medical_services_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly], // 숫자만 입력
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '용량을 입력해주세요.';
                      }
                      // Ensure it's a positive integer
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return '유효한 숫자를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: entry.selectedDoseType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: <String>['정', 'ml', '가루약'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        entry.selectedDoseType = newValue!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '타입 선택';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            // 복용 빈도 입력 필드 (수정됨)
            Row(
              children: [
                Text('1일', style: TextStyle(fontSize: 16)), // "1일" 고정 텍스트
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: entry.frequencyTimesController,
                    decoration: InputDecoration(
                      labelText: '복용 횟수', // 라벨 변경
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) return '횟수 입력';
                      // Ensure it's a positive integer
                      if (int.tryParse(value) == null || int.parse(value) <= 0) return '유효한 숫자';
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 8),
                Text('회', style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 15),
            // 복약 시작일 선택 필드
            _buildDateSelector(
                context: context,
                title: '복약 시작일:',
                selectedDate: entry.selectedStartDate,
                onDateSelected: (date) {
                  setState(() {
                    entry.selectedStartDate = date;
                    entry.updateDurationDays(); // 시작일 변경 시 복약 기간 업데이트
                    // 시작일이 종료일보다 늦으면 종료일 초기화
                    if (entry.selectedEndDate != null && entry.selectedEndDate!.isBefore(entry.selectedStartDate)) {
                      entry.selectedEndDate = null;
                    }
                  });
                },
                isStartDate: true),
            SizedBox(height: 15),
            // 복약 일수 입력 필드
            TextFormField(
              controller: entry.durationDaysController,
              decoration: InputDecoration(
                labelText: '복약 일수',
                suffixText: '일',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '복약 일수를 입력해주세요.';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return '유효한 복약 일수를 입력해주세요.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

// MedicationFormEntry 클래스는 AddDiagnosedDiseaseScreen과 동일하게 유지
class MedicationFormEntry {
  final TextEditingController nameController = TextEditingController();
  TextEditingController doseController;
  String selectedDoseType = '정';
  TextEditingController frequencyTimesController;
  DateTime selectedStartDate;
  DateTime? selectedEndDate; // 이제 직접 사용되지 않음
  final TextEditingController durationDaysController = TextEditingController();
  // bool reminderEnabled = false; // AddDiagnosedDiseaseScreen으로 이동
  // TimeOfDay? selectedReminderTime; // AddDiagnosedDiseaseScreen으로 이동

  MedicationFormEntry({
    required this.selectedStartDate,
    TextEditingController? doseController,
    TextEditingController? frequencyTimesController,
  }) : this.doseController = doseController ?? TextEditingController(text: '1'),
        this.frequencyTimesController = frequencyTimesController ?? TextEditingController(text: '3');

  // durationDaysController의 텍스트 필드를 직접 업데이트하지 않도록 수정
  void updateDurationDays() {
    // 이 함수는 이제 복약 기간 계산에 사용되지 않고,
    // durationDaysController가 직접 복약 일수를 입력받으므로 필요 없음
    // 기존 로직을 제거하거나 변경합니다.
  }

  // 복약 일수를 계산하는 메서드 (현재는 사용되지 않지만, 다른 곳에서 필요할 경우를 위해 남겨둠)
  int calculateDurationDays() {
    if (selectedStartDate != null && selectedEndDate != null) {
      return selectedEndDate!.difference(selectedStartDate).inDays + 1;
    }
    return 0;
  }
}