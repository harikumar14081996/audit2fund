import 'package:audit2fund/core/constants/loan_status.dart';
import 'package:audit2fund/domain/entities/audit_event.dart';
import 'package:audit2fund/domain/entities/loan_file.dart';
import 'package:audit2fund/presentation/providers/core_providers.dart';
import 'package:audit2fund/presentation/providers/usecase_providers.dart';
import 'package:audit2fund/presentation/providers/loan_providers.dart';
import 'package:audit2fund/presentation/widgets/loan_form_dialog.dart';
import 'package:audit2fund/presentation/widgets/status_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LoanDetailScreen extends ConsumerWidget {
  final String loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanAsync = ref.watch(
      allLoansProvider.select(
        (value) => value.whenData(
          (loans) => loans.where((l) => l.id == loanId).firstOrNull,
        ),
      ),
    );

    return loanAsync.when(
      data: (loan) {
        if (loan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('File Details')),
            body: const Center(child: Text('Loan not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('File Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => LoanFormDialog(loan: loan),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.indigo),
                onPressed: () => _confirmDelete(context, ref, loan),
              ),
            ],
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel: Details (60%)
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, loan),
                      const SizedBox(height: 32),
                      _buildFinancials(loan),
                      const SizedBox(height: 32),
                      _buildNotes(loan),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              // Right Panel: Actions & Audit (40%)
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.grey.withValues(alpha: 0.05),
                  child: Column(
                    children: [
                      _buildActions(context, ref, loan),
                      const Divider(),
                      Expanded(child: _buildAuditTimeline(ref, loanId)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('File Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        appBar: AppBar(title: const Text('File Details')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LoanFile loan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusTag(status: loan.status),
            const Spacer(),
            Text(
              'Last Updated: ${DateFormat.yMMMd().add_jm().format(loan.updatedDate)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          loan.clientName,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text(
          'File ID: ${loan.fileId ?? 'N/A'}',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildFinancials(LoanFile loan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financials',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStat(
                  'Approved Amount',
                  '\$${loan.approvedAmount.toStringAsFixed(2)}',
                ),
                const SizedBox(width: 32),
                if (loan.requestedAmount != null)
                  _buildStat(
                    'Requested Amount',
                    '\$${loan.requestedAmount!.toStringAsFixed(2)}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildNotes(LoanFile loan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            loan.notes.isEmpty ? 'No notes.' : loan.notes,
            style: const TextStyle(height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, LoanFile loan) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Status Changer
          DropdownButtonFormField<LoanStatus>(
            key: ValueKey(loan.status),
            initialValue: loan.status,
            decoration: const InputDecoration(
              labelText: 'Current Status',
              border: OutlineInputBorder(),
            ),
            items: LoanStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (newStatus) {
              if (newStatus != null && newStatus != loan.status) {
                _confirmStatusChange(context, ref, loan, newStatus);
              }
            },
          ),
          const SizedBox(height: 16),
          // Follow Up Switch
          SwitchListTile(
            title: const Text('Follow-Up Active'),
            subtitle: Text(
              loan.followUpConfig.isActive
                  ? 'Every ${loan.followUpConfig.intervalMinutes} mins'
                  : 'Off',
            ),
            value: loan.followUpConfig.isActive,
            onChanged: loan.status.isFunded
                ? null
                : (val) {
                    // Toggle follow up
                    _toggleFollowUp(context, ref, loan, val);
                  },
          ),
        ],
      ),
    );
  }

  void _confirmStatusChange(
    BuildContext context,
    WidgetRef ref,
    LoanFile loan,
    LoanStatus newStatus,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Move to ${newStatus.label}?'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason / Comment (Optional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await ref
                      .read(loanUseCasesProvider)
                      .updateLoanStatus(
                        loanId: loan.id,
                        newStatus: newStatus,
                        description: controller.text,
                      );
                  ref.invalidate(allLoansProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, LoanFile loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: Text(
          'Are you sure you want to delete ${loan.clientName}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(loanUseCasesProvider).deleteLoan(loan.id);
              ref.invalidate(allLoansProvider);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to dashboard/list
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleFollowUp(
    BuildContext context,
    WidgetRef ref,
    LoanFile loan,
    bool isActive,
  ) {
    if (isActive) {
      // Show dialog to set interval (Hours & Minutes)
      showDialog(
        context: context,
        builder: (context) {
          int hours = 0;
          int minutes = 30; // default
          return AlertDialog(
            title: const Text('Set Reminder Interval'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Remind me every:'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: '0',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hours',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => hours = int.tryParse(v) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: '30',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minutes',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => minutes = int.tryParse(v) ?? 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final totalMinutes = (hours * 60) + minutes;
                  if (totalMinutes <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Interval must be > 0')),
                    );
                    return;
                  }

                  ref
                      .read(loanUseCasesProvider)
                      .updateFollowUpConfig(
                        loanId: loan.id,
                        isActive: true,
                        intervalMinutes: totalMinutes,
                      );

                  ref.invalidate(allLoansProvider);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    } else {
      ref
          .read(loanUseCasesProvider)
          .updateFollowUpConfig(loanId: loan.id, isActive: false);
      ref.invalidate(allLoansProvider);
    }
  }

  Widget _buildAuditTimeline(WidgetRef ref, String loanId) {
    final loanRepo = ref.watch(loanRepositoryProvider);
    return FutureBuilder<List<AuditEvent>>(
      future: loanRepo.getAuditHistory(loanId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final history = snapshot.data!;

        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return ListTile(
              leading: const Icon(Icons.history, size: 16),
              title: Text(
                item.action,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.description),
                  Text(
                    DateFormat.yMMMd().add_jm().format(item.timestamp),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }
}
