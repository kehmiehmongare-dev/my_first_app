import 'package:flutter/material.dart'; // ✅ ADD THIS IMPORT
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  attendance,
  announcement,
  feeReminder, // ✅ Changed from fee_reminder to follow camelCase
  event,
  gradeUpdate, // ✅ Changed from grade_update to follow camelCase
  general,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String senderId; // Lecturer UID
  final String senderName;
  final String senderRole; // 'lecturer' or 'admin'
  final List<String> recipientIds; // Student UIDs or 'all'
  final String? courseCode; // Optional: specific course
  final bool isRead;
  final bool isImportant;
  final DateTime createdAt;
  final Map<String, dynamic>? actionData; // For action buttons

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.recipientIds,
    this.courseCode,
    this.isRead = false,
    this.isImportant = false,
    required this.createdAt,
    this.actionData,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.name,
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'recipientIds': recipientIds,
        'courseCode': courseCode,
        'isRead': isRead,
        'isImportant': isImportant,
        'createdAt': createdAt.toIso8601String(),
        'actionData': actionData,
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json, String id) {
    return NotificationModel(
      id: id,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Unknown',
      senderRole: json['senderRole'] ?? 'lecturer',
      recipientIds: List<String>.from(json['recipientIds'] ?? []),
      courseCode: json['courseCode'],
      isRead: json['isRead'] ?? false,
      isImportant: json['isImportant'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      actionData: json['actionData'],
    );
  }

  // ✅ Helper to get icon based on type
  IconData getIcon() {
    switch (type) {
      case NotificationType.attendance:
        return Icons.qr_code_scanner;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.feeReminder:
        return Icons.payments;
      case NotificationType.event:
        return Icons.event;
      case NotificationType.gradeUpdate:
        return Icons.grade;
      default:
        return Icons.notifications;
    }
  }

  // ✅ Helper to get color based on type
  Color getColor() {
    switch (type) {
      case NotificationType.attendance:
        return Colors.green;
      case NotificationType.announcement:
        return Colors.blue;
      case NotificationType.feeReminder:
        return Colors.red;
      case NotificationType.event:
        return Colors.purple;
      case NotificationType.gradeUpdate:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
