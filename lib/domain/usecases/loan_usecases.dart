import 'package:audit2fund/core/constants/loan_status.dart';
import 'package:audit2fund/domain/entities/audit_event.dart';
import 'package:audit2fund/domain/entities/loan_file.dart';
import 'package:audit2fund/domain/repositories/loan_repository.dart';
import 'package:uuid/uuid.dart';

class LoanUseCases {
  final LoanRepository _repository;
  final Uuid _uuid = const Uuid();

  LoanUseCases(this._repository);

  Future<void> createLoan({
    required String clientName,
    required double approvedAmount,
    String? fileId,
    double? requestedAmount,
    String notes = '',
  }) async {
    final loanId = _uuid.v4();
    final now = DateTime.now();

    final newLoan = LoanFile(
      id: loanId,
      clientName: clientName,
      fileId: fileId,
      approvedAmount: approvedAmount,
      requestedAmount: requestedAmount,
      notes: notes,
      createdDate: now,
      updatedDate: now,
      status: LoanStatus.pending,
      followUpConfig: const FollowUpConfig(isActive: false, intervalMinutes: 0),
    );

    await _repository.createLoan(newLoan);

    // Log creation audit
    await _repository.logAuditEvent(
      AuditEvent(
        id: _uuid.v4(),
        loanId: loanId,
        timestamp: now,
        oldStatus: LoanStatus.pending,
        newStatus: LoanStatus.pending,
        action: 'Created',
        description: 'File created for client $clientName',
      ),
    );
  }

  Future<void> updateLoanStatus({
    required String loanId,
    required LoanStatus newStatus,
    String description = '',
  }) async {
    final loan = await _repository.getLoanById(loanId);
    if (loan == null) throw Exception('Loan not found');

    if (!_isValidTransition(loan.status, newStatus)) {
      throw Exception(
        'Invalid status transition from ${loan.status.label} to ${newStatus.label}',
      );
    }

    final updatedLoan = loan.copyWith(
      status: newStatus,
      updatedDate: DateTime.now(),
      // Stop follow-ups if funded
      followUpConfig: newStatus == LoanStatus.funded
          ? loan.followUpConfig.copyWith(isActive: false)
          : loan.followUpConfig,
    );

    await _repository.updateLoan(updatedLoan);

    // Log Audit
    await _repository.logAuditEvent(
      AuditEvent(
        id: _uuid.v4(),
        loanId: loan.id,
        timestamp: DateTime.now(),
        oldStatus: loan.status,
        newStatus: newStatus,
        action: 'Status Change',
        description: description.isNotEmpty
            ? description
            : 'Moved to ${newStatus.label}',
      ),
    );
  }

  Future<void> updateFollowUpConfig({
    required String loanId,
    required bool isActive,
    int? intervalMinutes,
  }) async {
    final loan = await _repository.getLoanById(loanId);
    if (loan == null) throw Exception('Loan not found');

    // Cannot enable follow up if funded
    if (loan.status == LoanStatus.funded && isActive) {
      throw Exception('Cannot enable follow-ups for funded loans');
    }

    final updatedConfig = loan.followUpConfig.copyWith(
      isActive: isActive,
      intervalMinutes: intervalMinutes,
    );

    await _repository.updateLoan(
      loan.copyWith(followUpConfig: updatedConfig, updatedDate: DateTime.now()),
    );
  }

  Future<void> updateLoanDetails({
    required String loanId,
    required String clientName,
    required double approvedAmount,
    String? fileId,
    double? requestedAmount,
    String? notes,
  }) async {
    final loan = await _repository.getLoanById(loanId);
    if (loan == null) throw Exception('Loan not found');

    final updatedLoan = loan.copyWith(
      clientName: clientName,
      approvedAmount: approvedAmount,
      fileId: fileId,
      requestedAmount: requestedAmount,
      notes: notes,
      updatedDate: DateTime.now(),
    );

    await _repository.updateLoan(updatedLoan);

    // Log Audit
    await _repository.logAuditEvent(
      AuditEvent(
        id: _uuid.v4(),
        loanId: loan.id,
        timestamp: DateTime.now(),
        oldStatus: loan.status,
        newStatus: loan.status,
        action: 'File Updated',
        description: 'Details updated',
      ),
    );
  }

  Future<void> deleteLoan(String loanId) async {
    await _repository.deleteLoan(loanId);
  }

  bool _isValidTransition(LoanStatus current, LoanStatus next) {
    if (current == next) return false;
    // Relaxed rule: Allow jumping to any status (except same)
    // Strict enforcement removed based on user feedback.
    return true;
  }
}
