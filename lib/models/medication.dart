// lib/models/medication.dart

import 'package:flutter/material.dart'; // TimeOfDay를 위해 필요

class Medication {
  String id;
  String name;
  String dosage; // 복용량 (사용하지 않지만 남겨둠)
  String frequency; // 복용 빈도 (예: 1일 3회)
  DateTime startDate;
  DateTime? endDate;
  // reminderEnabled, reminderTime 필드는 Prescription 레벨로 이동되었으므로 Medication 모델에서는 삭제합니다.
  String? associatedDiseaseName; // 이 약이 처방된 질병명 (필터링을 위해 추가)

  // 새롭게 추가된 필드: 용량 및 용량 타입
  int? dose; // 복용량 숫자 (예: 1, 50)
  String? doseType; // 복용량 타입 (예: '정', 'ml', '가루약')

  // numPerDay 값을 직접 저장하기 위한 필드 추가
  int? numPerDayValue;

  Medication({
    required this.id,
    required this.name,
    required this.dosage, // 이 필드는 사용하지 않지만 유지
    required this.frequency,
    required this.startDate,
    this.endDate,
    // this.reminderEnabled = false, // 삭제
    // this.reminderTime, // 삭제
    this.associatedDiseaseName, // 필드 초기화
    this.dose, // 새 필드 초기화
    this.doseType, // 새 필드 초기화
    this.numPerDayValue, // 새 필드 초기화
  });
}