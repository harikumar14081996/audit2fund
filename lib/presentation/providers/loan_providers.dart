import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audit2fund/domain/entities/loan_file.dart';
import 'core_providers.dart';

final allLoansProvider = FutureProvider<List<LoanFile>>((ref) async {
  final repo = ref.watch(loanRepositoryProvider);
  return repo.getAllLoans();
});
