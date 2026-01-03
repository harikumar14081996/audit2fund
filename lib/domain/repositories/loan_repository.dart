import 'package:audit2fund/core/constants/loan_status.dart';
import 'package:audit2fund/domain/entities/audit_event.dart';
import 'package:audit2fund/domain/entities/loan_file.dart';

abstract class LoanRepository {
  Future<List<LoanFile>> getAllLoans();
  Future<LoanFile?> getLoanById(String id);
  Future<void> createLoan(LoanFile loan);
  Future<void> updateLoan(LoanFile loan);
  Future<void> deleteLoan(String id);

  Future<List<LoanFile>> searchLoans(String query, {LoanStatus? statusFilter});

  // Audit related
  Future<List<AuditEvent>> getAuditHistory(String loanId);
  Future<void> logAuditEvent(AuditEvent event);
}
