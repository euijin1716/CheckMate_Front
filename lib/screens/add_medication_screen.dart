// lib/screens/add_medication_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/main.dart'; // dataService 접근을 위해 main.dart 임포트
import 'package:health_app/models/medication.dart'; // 모델 임포트
import 'package:health_app/models/diagnosed_disease.dart'; // DiagnosedDisease 모델 임포트 (prescription_id 로직 때문에 필요)
import 'package:flutter/services.dart'; // FilteringTextInputFormatter를 위해 추가

class AddMedicationScreen extends StatefulWidget {
  // 초기 질병명을 받을 수 있도록 생성자 수정
  final String? initialDiseaseName;

  const AddMedicationScreen({Key? key, this.initialDiseaseName}) : super(key: key);

  @override
  _AddMedicationScreenState createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  // 기존 _nameController, _dosageController, _frequencyController는 이제 MedicationFormEntry 내부로 이동
  // 질병명 입력 필드 대신 드롭다운 필터를 사용할 것이므로, 컨트롤러는 유지하되 UI에서 직접 사용하지 않습니다.
  final TextEditingController _diseaseNameController = TextEditingController(); // 드롭다운 값으로 사용될 질병명

  // 여러 개의 복약 정보를 관리하기 위한 리스트 (AddDiagnosedDiseaseScreen과 동일)
  final List<MedicationFormEntry> _medicationEntries = [];

  List<Map<String, String>> _diseaseSearchResults = []; // 질병 검색 결과
  bool _isSearchingDisease = false; // 질병 검색 중 여부

  List<Map<String, String>> _medicineSuggestions = []; // 약 검색 결과 (타입 변경)
  bool _isSearchingMedicine = false;

  String? _selectedDiseaseForFilter; // 드롭다운 필터에서 선택된 질병
  List<String> _diseaseFilterOptions = []; // 질병 필터 옵션 목록

  // AddMedicationScreen에서는 개별 약에 대한 알람 설정이 필요 없습니다.
  // 알람 설정은 AddDiagnosedDiseaseScreen에서 질병(Prescription) 단위로 관리됩니다.

  @override
  void initState() {
    super.initState();
    _loadDiseaseFilterOptions().then((_) {
      // 초기 질병명 설정은 _loadDiseaseFilterOptions 내부에서 처리됩니다.
    });

    _addMedicationEntry(); // 초기 화면에 최소 하나의 복약 정보 입력 필드를 추가
  }

  // 진단 질환 목록을 가져와 필터 옵션으로 설정
  Future<void> _loadDiseaseFilterOptions() async {
    try {
      final fetchedDiseases = await dataService.fetchDiagnosedDiseasesFromServer();
      if (!mounted) return;
      setState(() {
        _diseaseFilterOptions.clear();
        _diseaseFilterOptions.add('전체'); // '전체' 옵션 추가
        _diseaseFilterOptions.add('영양제'); // '영양제' 옵션 추가
        // 실제 질병명만 추가
        for (var disease in fetchedDiseases) {
          if (!_diseaseFilterOptions.contains(disease.name)) {
            _diseaseFilterOptions.add(disease.name);
          }
        }

        // Determine the initial selected filter value
        String? determinedInitialFilter;

        if (widget.initialDiseaseName != null) {
          if (widget.initialDiseaseName == '전체' || widget.initialDiseaseName == '영양제') {
            determinedInitialFilter = widget.initialDiseaseName;
          } else if (_diseaseFilterOptions.contains(widget.initialDiseaseName)) {
            // If it's a specific disease name and exists in the options
            determinedInitialFilter = widget.initialDiseaseName;
          }
        }

        // If no specific initial filter was determined, default to '전체'
        if (determinedInitialFilter == null && _diseaseFilterOptions.isNotEmpty) {
          determinedInitialFilter = '전체';
        }

        _selectedDiseaseForFilter = determinedInitialFilter;
        _diseaseNameController.text = determinedInitialFilter ?? ''; // Ensure controller is not null

        print('DEBUG: _diseaseFilterOptions: $_diseaseFilterOptions');
        print('DEBUG: initialDiseaseName: ${widget.initialDiseaseName}');
        print('DEBUG: _selectedDiseaseForFilter (after logic): $_selectedDiseaseForFilter');

      });
    } catch (e) {
      print('질병 필터 옵션 로드 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('질병 목록을 불러오는 데 실패했습니다: $e'), backgroundColor: Colors.redAccent),
        );
      }
      setState(() {
        _diseaseFilterOptions = ['오류 발생']; // 오류 시 표시
        _selectedDiseaseForFilter = '오류 발생';
        _diseaseNameController.text = '';
      });
    }
  }


  @override
  void dispose() {
    _diseaseNameController.dispose();
    for (var entry in _medicationEntries) {
      entry.nameController.dispose();
      entry.doseController.dispose();
      entry.frequencyTimesController.dispose();
      entry.durationDaysController.dispose();
    }
    super.dispose();
  }

  // 질병 검색 함수 (이 화면에서는 드롭다운으로 대체되므로 직접 사용되지 않음)
  void _searchDiseases(String query) async {
    // 이 함수는 이제 직접적으로 UI에 사용되지 않지만, DataService 호출을 위해 유지
    // 드롭다운 필터가 질병 선택을 담당
  }

  // 질병 선택 처리 (드롭다운에서 선택 시 호출)
  void _selectDisease(String diseaseName) {
    setState(() {
      _selectedDiseaseForFilter = diseaseName;
      _diseaseNameController.text = diseaseName; // 컨트롤러에 선택된 질병명 설정
    });
  }

  // 약 이름 검색 함수 (AddDiagnosedDiseaseScreen에서 복사)
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

  // 약 이름 선택 처리 (AddDiagnosedDiseaseScreen에서 복사)
  void _selectMedicine(Map<String, String> medicineDetail, MedicationFormEntry entry) { // Map<String, String> 타입으로 변경
    setState(() {
      entry.nameController.text = medicineDetail['medicineName']!; // 'medicineName' 키로 접근
      _medicineSuggestions = [];
    });
  }

  // 복약 정보 입력 필드 세트 추가 (AddDiagnosedDiseaseScreen에서 복사)
  void _addMedicationEntry() {
    setState(() {
      _medicationEntries.add(MedicationFormEntry(
        selectedStartDate: DateTime.now(), // 현재 날짜로 기본값 설정
        frequencyTimesController: TextEditingController(text: '3'), // 기본값 3회
        doseController: TextEditingController(text: '1'), // 기본값 1
      ));
    });
  }

  // 복약 정보 입력 필드 세트 삭제 (AddDiagnosedDiseaseScreen에서 복사)
  void _removeMedicationEntry(int index) {
    setState(() {
      _medicationEntries[index].nameController.dispose();
      _medicationEntries[index].doseController.dispose();
      _medicationEntries[index].frequencyTimesController.dispose();
      _medicationEntries[index].durationDaysController.dispose();
      _medicationEntries.removeAt(index);
    });
  }

  // 복약 정보 저장 처리 (백엔드 연동 로직 포함)
  void _saveMedication() async {
    // 폼 유효성 검사
    bool allFormsValid = true;
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      allFormsValid = false;
    }
    // 드롭다운에서 질병이 선택되지 않았거나, '등록된 질병 없음' 등의 유효하지 않은 값인 경우
    if (_selectedDiseaseForFilter == null || _selectedDiseaseForFilter!.isEmpty ||
        _selectedDiseaseForFilter == '등록된 질병 없음' || _selectedDiseaseForFilter == '오류 발생' ||
        _selectedDiseaseForFilter == '전체') { // '전체' 옵션 선택 시에도 경고
      allFormsValid = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('복약 정보를 등록할 질병을 선택해주세요 (전체 제외).'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

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
        break;
      }
    }

    if (allFormsValid) {
      final String diseaseName = _selectedDiseaseForFilter!; // 드롭다운에서 선택된 질병명 사용
      final List<Medication> medicationsToRegister = [];

      for (var entry in _medicationEntries) {
        if (entry.nameController.text.trim().isNotEmpty) {
          final int numPerDay = int.parse(entry.frequencyTimesController.text.trim());
          final int dose = int.parse(entry.doseController.text.trim());
          final int durationDays = int.parse(entry.durationDaysController.text.trim()); // 복약 일수 파싱

          // 복약 시작일과 복약 일수를 사용하여 종료일 계산
          final DateTime calculatedEndDate = entry.selectedStartDate.add(Duration(days: durationDays - 1));

          medicationsToRegister.add(
            Medication(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_med_${medicationsToRegister.length}',
              name: entry.nameController.text.trim(),
              dosage: '', // 이 필드는 더 이상 사용하지 않음
              frequency: '1일 ${numPerDay}회',
              startDate: entry.selectedStartDate,
              endDate: calculatedEndDate, // 계산된 종료일 사용
              // reminderEnabled, reminderTime 삭제
              associatedDiseaseName: diseaseName,
              dose: dose,
              doseType: entry.selectedDoseType,
              numPerDayValue: numPerDay,
            ),
          );
        }
      }

      if (medicationsToRegister.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('하나 이상의 복약 정보를 입력해주세요.'), backgroundColor: Colors.orangeAccent),
        );
        return;
      }

      try {
        // 1. 해당 질병명으로 기존 처방전이 있는지 조회
        // fetchDiagnosedDiseasesFromServer는 DiagnosedDisease 객체 리스트를 반환하며,
        // 이 객체에는 서버의 prescription ID가 id 필드에 저장되어 있습니다.
        final List<DiagnosedDisease> existingPrescriptions = await dataService.fetchDiagnosedDiseasesFromServer();
        DiagnosedDisease? targetPrescription;
        for (var p in existingPrescriptions) {
          if (p.name == diseaseName) {
            targetPrescription = p;
            break;
          }
        }

        String prescriptionIdToUse;

        if (targetPrescription == null) {
          // 2. 해당 질병명의 처방전이 없는 경우: 새로운 처방전 생성 후 ID 사용
          print('Prescription for $diseaseName not found. Creating new prescription...');
          // registerDiseaseAndMedications는 이제 생성된 prescriptionId를 반환합니다.
          // AddMedicationScreen에서는 질병 알람 정보를 직접 설정하지 않으므로, 이 값들은 null로 전달합니다.
          final int newPrescriptionId = await dataService.registerDiseaseAndMedications(
            DiagnosedDisease(id: '', name: diseaseName, diagnosedDate: DateTime.now()), // 새 질병 정보
            [], // 약 정보는 여기서 추가하지 않음
            numPerDayForPrescription: null, // AddMedicationScreen에서는 설정하지 않음
            alarmTimesForPrescription: List.filled(4, null), // AddMedicationScreen에서는 설정하지 않음
          );
          prescriptionIdToUse = newPrescriptionId.toString();
        } else {
          // 3. 해당 질병명의 처방전이 있는 경우: 기존 처방전 ID 사용
          print('Prescription for $diseaseName found. Using existing prescription ID: ${targetPrescription.id}');
          prescriptionIdToUse = targetPrescription.id;
        }

        // 4. 각 약 정보를 해당 처방전 ID에 추가
        for (var med in medicationsToRegister) {
          await dataService.addMedicineToPrescriptionForExistingId(prescriptionIdToUse, med);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$diseaseName에 대한 복약 정보가 성공적으로 등록되었습니다.')),
          );
          Navigator.pop(context, true); // 이전 화면으로 돌아가기
        }
      } catch (e) {
        print('복약 정보 등록 중 오류 발생: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('복약 정보 등록 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }


  // 각 복약 엔트리에 대한 알림 시간 선택 (AddDiagnosedDiseaseScreen에서 복사)
  // AddMedicationScreen에서는 개별 약에 대한 알람 설정이 필요 없으므로 이 함수는 사용하지 않습니다.
  // Future<void> _pickReminderTimeForEntry(MedicationFormEntry entry) async { ... }

  // 날짜 선택 위젯 빌더 (AddDiagnosedDiseaseScreen에서 복사)
  Widget _buildDateSelector({
    required BuildContext context,
    required String title,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
    required bool isStartDate,
    // allowClear, onClearDate는 사용하지 않으므로 제거
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
                    ? '날짜를 선택해주세요'
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
                  firstDate: DateTime(DateTime.now().year - 5),
                  lastDate: DateTime(DateTime.now().year + 5),
                  helpText: title,
                );
                if (picked != null) onDateSelected(picked);
              },
            ),
          ],
        ),
      ],
    );
  }

  // 각 복약 정보 입력 필드 세트를 위한 카드 위젯 (AddDiagnosedDiseaseScreen에서 복사)
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '용량을 입력해주세요.';
                      }
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
            Row(
              children: [
                Text('1일', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: entry.frequencyTimesController,
                    decoration: InputDecoration(
                      labelText: '복용 횟수',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) return '횟수 입력';
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
            _buildDateSelector(
                context: context,
                title: '복약 시작일:',
                selectedDate: entry.selectedStartDate,
                onDateSelected: (date) {
                  setState(() {
                    entry.selectedStartDate = date;
                    // 시작일이 변경될 때 종료일은 자동으로 업데이트되지 않도록 함
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
            // AddMedicationScreen에서는 개별 약에 대한 알람 설정이 필요 없으므로 아래 코드는 삭제
            // SizedBox(height: 15),
            // SwitchListTile(
            //   title: Text('복약 알림 설정'),
            //   subtitle: entry.reminderEnabled && entry.selectedReminderTime != null
            //       ? Text('매일 ${entry.selectedReminderTime!.hour.toString().padLeft(2, '0')}:${entry.selectedReminderTime!.minute.toString().padLeft(2, '0')}에 알림')
            //       : null,
            //   value: entry.reminderEnabled,
            //   onChanged: (bool value) async {
            //     setState(() {
            //       entry.reminderEnabled = value;
            //       if (entry.reminderEnabled && entry.selectedReminderTime == null) {
            //         _pickReminderTimeForEntry(entry);
            //       } else if (!entry.reminderEnabled) {
            //         entry.selectedReminderTime = null;
            //       }
            //     });
            //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${entry.nameController.text} 알림 ${value ? "켬" : "끔"}')));
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('새로운 복약 정보 등록'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('질병 정보', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  // 필터 드롭다운을 Expanded로 감싸서 공간을 확보합니다.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: DropdownButton<String>(
                        value: _selectedDiseaseForFilter,
                        icon: const Icon(Icons.filter_list),
                        elevation: 16,
                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            _selectDisease(newValue); // 선택된 질병 업데이트
                          }
                        },
                        items: _diseaseFilterOptions.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              // 질병명 입력 필드 대신 선택된 질병명을 표시하는 텍스트
              Card(
                margin: EdgeInsets.symmetric(vertical: 4.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.sick_outlined, color: Theme.of(context).primaryColor),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _selectedDiseaseForFilter ?? '질병을 선택해주세요',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
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
                onPressed: _saveMedication,
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
  // MedicationFormEntry는 더 이상 알림 관련 필드를 직접 가지지 않습니다.
  // bool reminderEnabled = false; // 삭제
  // TimeOfDay? selectedReminderTime; // 삭제

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