import 'dart:convert';
import 'package:audit2fund/core/constants/loan_status.dart';

class FollowUpConfig {
  final bool isActive;
  final int intervalMinutes; // e.g., 60 for hourly
  final DateTime? lastNotificationTime;

  const FollowUpConfig({
    required this.isActive,
    required this.intervalMinutes,
    this.lastNotificationTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive ? 1 : 0,
      'intervalMinutes': intervalMinutes,
      'lastNotificationTime': lastNotificationTime?.toIso8601String(),
    };
  }

  factory FollowUpConfig.fromMap(Map<String, dynamic> map) {
    return FollowUpConfig(
      isActive: map['isActive'] == 1,
      intervalMinutes: map['intervalMinutes'] ?? 0,
      lastNotificationTime: map['lastNotificationTime'] != null
          ? DateTime.parse(map['lastNotificationTime'])
          : null,
    );
  }

  FollowUpConfig copyWith({
    bool? isActive,
    int? intervalMinutes,
    DateTime? lastNotificationTime,
  }) {
    return FollowUpConfig(
      isActive: isActive ?? this.isActive,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      lastNotificationTime: lastNotificationTime ?? this.lastNotificationTime,
    );
  }
}

class LoanFile {
  final String id;
  final String clientName;
  final String? fileId; // Optional specialized ID
  final double approvedAmount;
  final double? requestedAmount;
  final String notes; // Rich text content stored as string
  final DateTime createdDate;
  final DateTime updatedDate;
  final LoanStatus status;
  final FollowUpConfig followUpConfig;

  const LoanFile({
    required this.id,
    required this.clientName,
    this.fileId,
    required this.approvedAmount,
    this.requestedAmount,
    required this.notes,
    required this.createdDate,
    required this.updatedDate,
    required this.status,
    required this.followUpConfig,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'fileId': fileId,
      'approvedAmount': approvedAmount,
      'requestedAmount': requestedAmount,
      'notes': notes,
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate.toIso8601String(),
      'status': status.index,
      'followUpConfig': jsonEncode(followUpConfig.toMap()),
    };
  }

  factory LoanFile.fromMap(Map<String, dynamic> map) {
    return LoanFile(
      id: map['id'],
      clientName: map['clientName'],
      fileId: map['fileId'],
      approvedAmount: (map['approvedAmount'] as num).toDouble(),
      requestedAmount: map['requestedAmount'] != null
          ? (map['requestedAmount'] as num).toDouble()
          : null,
      notes: map['notes'] ?? '',
      createdDate: DateTime.parse(map['createdDate']),
      updatedDate: DateTime.parse(map['updatedDate']),
      status: LoanStatus.fromIndex(map['status']),
      followUpConfig: FollowUpConfig.fromMap(jsonDecode(map['followUpConfig'])),
    );
  }

  LoanFile copyWith({
    String? clientName,
    String? fileId,
    double? approvedAmount,
    double? requestedAmount,
    String? notes,
    DateTime? updatedDate,
    LoanStatus? status,
    FollowUpConfig? followUpConfig,
  }) {
    return LoanFile(
      id: id,
      clientName: clientName ?? this.clientName,
      fileId: fileId ?? this.fileId,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      notes: notes ?? this.notes,
      createdDate: createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      status: status ?? this.status,
      followUpConfig: followUpConfig ?? this.followUpConfig,
    );
  }
}
