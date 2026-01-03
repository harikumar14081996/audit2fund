import 'package:audit2fund/core/constants/loan_status.dart';

class AuditEvent {
  final String id;
  final String loanId;
  final DateTime timestamp;
  final LoanStatus oldStatus;
  final LoanStatus newStatus;
  final String action; // e.g., "Created", "Status Change", "Update"
  final String description;

  const AuditEvent({
    required this.id,
    required this.loanId,
    required this.timestamp,
    required this.oldStatus,
    required this.newStatus,
    required this.action,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loanId': loanId,
      'timestamp': timestamp.toIso8601String(),
      'oldStatus': oldStatus.index,
      'newStatus': newStatus.index,
      'action': action,
      'description': description,
    };
  }

  factory AuditEvent.fromMap(Map<String, dynamic> map) {
    return AuditEvent(
      id: map['id'],
      loanId: map['loanId'],
      timestamp: DateTime.parse(map['timestamp']),
      oldStatus: LoanStatus.fromIndex(map['oldStatus']),
      newStatus: LoanStatus.fromIndex(map['newStatus']),
      action: map['action'],
      description: map['description'],
    );
  }
}
