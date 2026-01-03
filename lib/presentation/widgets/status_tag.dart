import 'package:audit2fund/core/constants/loan_status.dart';
import 'package:flutter/material.dart';

class StatusTag extends StatelessWidget {
  final LoanStatus status;

  const StatusTag({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getColor(context).withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          color: _getColor(context),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColor(BuildContext context) {
    switch (status) {
      case LoanStatus.pending:
        return Colors.grey;
      case LoanStatus.sentForApproval:
        return Colors.blue;
      case LoanStatus.additionalDocsRequested:
        return Colors.orange;
      case LoanStatus.approved:
        return Theme.of(context).colorScheme.primary; // Muted blue
      case LoanStatus.sentInAudit:
        return Colors.purple;
      case LoanStatus.funded:
        return const Color(0xFF059669); // Muted Green
    }
  }
}
