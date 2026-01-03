import 'dart:convert';
import 'dart:io';
import 'package:audit2fund/domain/entities/audit_event.dart';
import 'package:audit2fund/domain/entities/loan_file.dart';
import 'package:audit2fund/domain/repositories/loan_repository.dart';
import 'package:audit2fund/domain/repositories/settings_repository.dart';
import 'package:file_picker/file_picker.dart';
// Note: handling file_picker for desktop might require specific entitlement or config, but standard version works mostly.

class DataTransferService {
  final LoanRepository _loanRepository;
  final SettingsRepository _settingsRepository;

  DataTransferService(this._loanRepository, this._settingsRepository);

  Future<String> exportData() async {
    final loans = await _loanRepository.getAllLoans();

    // Gather all audits
    final Map<String, List<Map<String, dynamic>>> audits = {};
    for (var loan in loans) {
      final history = await _loanRepository.getAuditHistory(loan.id);
      audits[loan.id] = history.map((e) => e.toMap()).toList();
    }

    final settings = {
      'start': (await _settingsRepository.getOfficeStartTime())
          .toString(), // format? "TimeOfDay(09:30)" check
      'end': (await _settingsRepository.getOfficeEndTime()).toString(),
      'workingDays': await _settingsRepository.getWorkingDays(),
    };

    final exportData = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'loans': loans.map((l) => l.toMap()).toList(),
      'audits': audits,
      'settings': settings,
    };

    final jsonString = jsonEncode(exportData);

    // Save to file
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Database',
      fileName: 'audit2fund_backup.json',
      allowedExtensions: ['json'],
      type: FileType.custom,
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(jsonString);
      return 'Exported to $outputFile';
    }

    return 'Export cancelled';
  }

  Future<String> importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import Database',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final data = jsonDecode(content);

        if (data['version'] == 1) {
          // Import Logic: Strategy - Merge/Upsert
          // 1. Loans
          final loansList = data['loans'] as List;
          int importedCount = 0;

          for (var l in loansList) {
            final loan = LoanFile.fromMap(l);
            // We use createLoan which is an upsert in SQLite (INSERT OR REPLACE)
            await _loanRepository.createLoan(loan);
            importedCount++;
          }

          // 2. Audits
          final auditsMap = data['audits'] as Map<String, dynamic>;
          auditsMap.forEach((loanId, eventsList) async {
            for (var e in (eventsList as List)) {
              final event = AuditEvent.fromMap(e);
              await _loanRepository.logAuditEvent(event);
            }
          });

          return 'Imported $importedCount files successfully.';
        } else {
          return 'Unknown version';
        }
      }
    } catch (e) {
      return 'Error importing data: $e';
    }
    return 'Import cancelled';
  }
}
