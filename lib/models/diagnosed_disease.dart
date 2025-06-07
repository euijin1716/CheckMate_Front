// lib/models/diagnosed_disease.dart

import 'package:flutter/material.dart'; // Material.dart가 필요한 경우에만 유지 (예: TimeOfDay 등)

class DiagnosedDisease {
  final String id;
  String name;
  DateTime diagnosedDate;
  String? memo;
  int? systolicBloodPressure;   // 수축기 혈압
  int? diastolicBloodPressure;  // 이완기 혈압
  int? heartRate;              // 심박수

  DiagnosedDisease({
    required this.id,
    required this.name,
    required this.diagnosedDate,
    this.memo,
    this.systolicBloodPressure,
    this.diastolicBloodPressure,
    this.heartRate,
  });
}
