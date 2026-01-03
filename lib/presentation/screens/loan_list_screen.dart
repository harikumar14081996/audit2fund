import 'package:audit2fund/core/constants/loan_status.dart';
import 'package:audit2fund/presentation/widgets/status_tag.dart';
import 'package:audit2fund/presentation/screens/loan_detail_screen.dart';
import 'package:audit2fund/presentation/providers/loan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoanListScreen extends ConsumerStatefulWidget {
  const LoanListScreen({super.key});

  @override
  ConsumerState<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends ConsumerState<LoanListScreen> {
  String _searchQuery = '';
  LoanStatus? _statusFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Files')),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by client, ID, notes...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<LoanStatus?>(
                  value: _statusFilter,
                  hint: const Text('All Statuses'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    ...LoanStatus.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _statusFilter = val);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ref
                .watch(allLoansProvider)
                .when(
                  data: (allLoans) {
                    // Client-side filtering
                    var loans = allLoans;

                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      loans = loans.where((l) {
                        return l.clientName.toLowerCase().contains(q) ||
                            (l.fileId?.toLowerCase().contains(q) ?? false) ||
                            l.notes.toLowerCase().contains(q);
                      }).toList();
                    }

                    if (_statusFilter != null) {
                      loans = loans
                          .where((l) => l.status == _statusFilter)
                          .toList();
                    }

                    if (loans.isEmpty) {
                      return const Center(child: Text('No loans found.'));
                    }

                    return ListView.separated(
                      itemCount: loans.length,
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final loan = loans[index];
                        return ListTile(
                          title: Text(
                            loan.clientName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'ID: ${loan.fileId ?? "N/A"} • Amount: \$${loan.approvedAmount.toStringAsFixed(0)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (loan.followUpConfig.isActive &&
                                  !loan.status.isFunded)
                                const Icon(
                                  Icons.notifications_active,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                              const SizedBox(width: 8),
                              StatusTag(status: loan.status),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    LoanDetailScreen(loanId: loan.id),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
