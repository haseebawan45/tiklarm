import 'package:flutter/material.dart';

class AlarmModel {
  final String id;
  final TimeOfDay time;
  final String label;
  final List<bool> days; // [mon, tue, wed, thu, fri, sat, sun]
  final String soundPath;
  final bool isVibrate;
  final bool isActive;
  final int snoozeTime; // in minutes

  AlarmModel({
    required this.id,
    required this.time,
    this.label = '',
    required this.days,
    this.soundPath = 'default_alarm',
    this.isVibrate = true,
    this.isActive = true,
    this.snoozeTime = 5,
  });

  // Convert AlarmModel to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'label': label,
      'days': days,
      'soundPath': soundPath,
      'isVibrate': isVibrate,
      'isActive': isActive,
      'snoozeTime': snoozeTime,
    };
  }

  // Create AlarmModel from Map
  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    return AlarmModel(
      id: map['id'],
      time: TimeOfDay(hour: map['hour'], minute: map['minute']),
      label: map['label'] ?? '',
      days: List<bool>.from(map['days']),
      soundPath: map['soundPath'] ?? 'default_alarm',
      isVibrate: map['isVibrate'] ?? true,
      isActive: map['isActive'] ?? true,
      snoozeTime: map['snoozeTime'] ?? 5,
    );
  }

  // Create a copy of AlarmModel with some properties changed
  AlarmModel copyWith({
    String? id,
    TimeOfDay? time,
    String? label,
    List<bool>? days,
    String? soundPath,
    bool? isVibrate,
    bool? isActive,
    int? snoozeTime,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      time: time ?? this.time,
      label: label ?? this.label,
      days: days ?? this.days,
      soundPath: soundPath ?? this.soundPath,
      isVibrate: isVibrate ?? this.isVibrate,
      isActive: isActive ?? this.isActive,
      snoozeTime: snoozeTime ?? this.snoozeTime,
    );
  }
} 