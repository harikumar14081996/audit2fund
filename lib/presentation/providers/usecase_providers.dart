import 'package:audit2fund/domain/usecases/loan_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';

final loanUseCasesProvider = Provider<LoanUseCases>((ref) {
  final repo = ref.watch(loanRepositoryProvider);
  return LoanUseCases(repo);
});
