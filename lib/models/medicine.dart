import 'package:flutter/material.dart';

class Medicine {
  final String id;
  final String name;
  final String dosage;
  final TimeOfDay scheduledTime;
  final List<int> notificationIds;
  bool isTaken;
  final String frequency; 
  final String mealInstruction; 
  final int stock;
  String notes;
  final String duration; 
  final String alertType; 
  bool isReminderActive;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.scheduledTime,
    required this.notificationIds,
    this.isTaken = false,
    this.frequency = "Once daily",
    this.mealInstruction = "Before",
    this.stock = 15,
    this.notes = "Take with water. Avoid alcohol.",
    this.duration = "Ongoing",
    this.alertType = "Notification",
    this.isReminderActive = true,
  });

  String get formattedTime {
    final hour = scheduledTime.hour == 0 ? 12 : (scheduledTime.hour > 12 ? scheduledTime.hour - 12 : scheduledTime.hour);
    final amPm = scheduledTime.hour >= 12 ? "PM" : "AM";
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute $amPm';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'hour': scheduledTime.hour,
      'minute': scheduledTime.minute,
      'isTaken': isTaken ? 1 : 0,
      'notificationIds': notificationIds.join(','),
      'frequency': frequency,
      'mealInstruction': mealInstruction,
      'stock': stock,
      'notes': notes,
      'duration': duration,
      'alertType': alertType,
      'isReminderActive': isReminderActive ? 1 : 0,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'],
      scheduledTime: TimeOfDay(hour: map['hour'], minute: map['minute']),
      isTaken: map['isTaken'] == 1,
      notificationIds: (map['notificationIds'] as String)
          .split(',')
          .map((e) => int.parse(e))
          .toList(),
      frequency: map['frequency'] ?? "Once daily",
      mealInstruction: map['mealInstruction'] ?? "Before",
      stock: map['stock'] ?? 15,
      notes: map['notes'] ?? "Take with water. Avoid alcohol.",
      duration: map['duration'] ?? "Ongoing",
      alertType: map['alertType'] ?? "Notification",
      isReminderActive: (map['isReminderActive'] ?? 1) == 1,
    );
  }
}
