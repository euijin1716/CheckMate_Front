// lib/models/potential_disease_memo.dart

import 'package:flutter/material.dart'; // TimeOfDay를 위해 필요

class PotentialDiseaseMemo {
  final String id; // memo_id (from backend)
  String memoName; // memo_name (from backend)
  String memoContent; // memo_content (from backend)
  DateTime? reminderTime; // reminder_time (from backend)
  final DateTime createdAt; // This is a frontend-specific field for display, not directly from backend Memo
  bool hasReminder; // Derived from reminderTime presence

  final String? diseaseId; // disease_id (from backend, nullable)

  PotentialDiseaseMemo({
    required this.id,
    required this.memoContent,
    required this.createdAt, // This is for frontend display
    this.hasReminder = false,
    this.reminderTime,
    required this.memoName,
    this.diseaseId,
  });

  // JSON 파싱을 위한 팩토리 생성자
  factory PotentialDiseaseMemo.fromJson(Map<String, dynamic> json) {
    return PotentialDiseaseMemo(
      id: json['id'].toString(),
      memoContent: json['memoContent'] as String,
      createdAt: DateTime.now(), // Backend doesn't send createdAt for Memo, using DateTime.now() for consistency
      hasReminder: json['reminderTime'] != null,
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'] as String).toLocal() // Parse to local time
          : null,
      memoName: json['memoName'] as String,
      diseaseId: json['diseaseId']?.toString(),
    );
  }

  // 객체를 JSON으로 변환하는 메서드 (for sending to backend)
  Map<String, dynamic> toJson() {
    return {
      // 'id'는 새로운 메모 생성 시 일반적으로 보내지 않으며, 업데이트 시에는 URL 경로에 포함됩니다.
      // 백엔드 MemoRequestDto에 id 필드가 없습니다.
      'memoName': memoName,
      'memoContent': memoContent,
      'reminderTime': reminderTime?.toUtc().toIso8601String(), // Send as UTC to backend
      // diseaseId는 요청 DTO의 일부가 아님 (MemoRequestDto)
    };
  }
}