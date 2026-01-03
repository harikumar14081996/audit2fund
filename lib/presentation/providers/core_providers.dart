import 'package:audit2fund/data/datasources/database_service.dart';
import 'package:audit2fund/data/datasources/settings_service.dart';
import 'package:audit2fund/data/repositories/loan_repository_impl.dart';
import 'package:audit2fund/data/repositories/settings_repository.dart';
import 'package:audit2fund/domain/repositories/loan_repository.dart';
import 'package:audit2fund/domain/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Database Service
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Settings Repository
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SettingsRepositoryImpl(SettingsService(dbService));
});

// Loan Repository
final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return LoanRepositoryImpl(dbService);
});
