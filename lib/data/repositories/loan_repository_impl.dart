import 'package:audit2fund/core/constants/loan_status.dart';
import 'package:audit2fund/data/datasources/database_service.dart';
import 'package:audit2fund/domain/entities/audit_event.dart';
import 'package:audit2fund/domain/entities/loan_file.dart';
import 'package:audit2fund/domain/repositories/loan_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LoanRepositoryImpl implements LoanRepository {
  final DatabaseService _databaseService;

  LoanRepositoryImpl(this._databaseService);

  @override
  Future<List<LoanFile>> getAllLoans() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loan_files',
      orderBy: 'updatedDate DESC',
    );
    return List.generate(maps.length, (i) => LoanFile.fromMap(maps[i]));
  }

  @override
  Future<LoanFile?> getLoanById(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loan_files',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return LoanFile.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> createLoan(LoanFile loan) async {
    final db = await _databaseService.database;
    await db.insert(
      'loan_files',
      loan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateLoan(LoanFile loan) async {
    final db = await _databaseService.database;
    await db.update(
      'loan_files',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  @override
  Future<List<LoanFile>> searchLoans(
    String query, {
    LoanStatus? statusFilter,
  }) async {
    final db = await _databaseService.database;
    String whereClause = 'clientName LIKE ? OR notes LIKE ? OR fileId LIKE ?';
    List<dynamic> args = ['%$query%', '%$query%', '%$query%'];

    if (statusFilter != null) {
      whereClause = '($whereClause) AND status = ?';
      args.add(statusFilter.index);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'loan_files',
      where: whereClause,
      whereArgs: args,
      orderBy: 'updatedDate DESC',
    );
    return List.generate(maps.length, (i) => LoanFile.fromMap(maps[i]));
  }

  @override
  Future<void> deleteLoan(String id) async {
    final db = await _databaseService.database;
    await db.delete('loan_files', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<AuditEvent>> getAuditHistory(String loanId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'audit_events',
      where: 'loanId = ?',
      orderBy: 'timestamp DESC', // Newest first
      whereArgs: [loanId],
    );
    return List.generate(maps.length, (i) => AuditEvent.fromMap(maps[i]));
  }

  @override
  Future<void> logAuditEvent(AuditEvent event) async {
    final db = await _databaseService.database;
    await db.insert(
      'audit_events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
