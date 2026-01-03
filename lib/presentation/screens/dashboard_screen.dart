import 'package:audit2fund/core/constants/loan_status.dart';
import 'package:audit2fund/domain/entities/loan_file.dart';

import 'package:audit2fund/presentation/providers/loan_providers.dart';
import 'package:audit2fund/presentation/screens/settings_screen.dart';
import 'package:audit2fund/presentation/widgets/loan_form_dialog.dart';
import 'package:audit2fund/presentation/screens/loan_detail_screen.dart';
import 'package:audit2fund/presentation/screens/loan_list_screen.dart';
import 'package:audit2fund/presentation/widgets/status_tag.dart';
import 'package:audit2fund/presentation/screens/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:audit2fund/presentation/providers/service_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Start background service for notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(followUpServiceProvider).startService();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit2Fund'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Reports',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ref
          .watch(allLoansProvider)
          .when(
            data: (loans) {
              // Calculate stats
              final stats = {
                for (var status in LoanStatus.values)
                  status: loans.where((l) => l.status == status).length,
              };

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusCards(stats),
                    const SizedBox(height: 32),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Focus Panel (Left - 60%)
                          Expanded(
                            flex: 3,
                            child: _buildFocusPanel(context, ref),
                          ),
                          const SizedBox(width: 24),
                          // Aging/Activity (Right - 40%)
                          Expanded(
                            flex: 2,
                            child: _buildActivityPanel(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(context: context, builder: (_) => const LoanFormDialog());
        },
        label: const Text('New File'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusCards(Map<LoanStatus, int> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: LoanStatus.values.map((status) {
            return SizedBox(
              width: (constraints.maxWidth - (5 * 16)) / 6, // Divide by 6 cards
              child: _StatusCard(status: status, count: stats[status] ?? 0),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFocusPanel(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LoanFile>> loansAsync = ref.watch(allLoansProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Follow-Up Focus',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: loansAsync.when(
                data: (loans) {
                  // Filter active follow-ups
                  final active = loans
                      .where(
                        (l) => l.followUpConfig.isActive && !l.status.isFunded,
                      )
                      .toList();

                  if (active.isEmpty) {
                    return const Center(child: Text('No active follow-ups.'));
                  }

                  return ListView.separated(
                    itemCount: active.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final loan = active[index];
                      // Check if 'Due Now'
                      final isDue = _isDue(loan);

                      return ListTile(
                        leading: Icon(
                          Icons.notifications_active,
                          color: isDue
                              ? Theme.of(context).colorScheme.error
                              : Colors.grey,
                        ),
                        title: Text(
                          loan.clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Status: ${loan.status.label} • Next: ${_formatNext(loan)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    LoanDetailScreen(loanId: loan.id),
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoanDetailScreen(loanId: loan.id),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDue(LoanFile loan) {
    if (loan.followUpConfig.lastNotificationTime == null) return true;
    final diff = DateTime.now().difference(
      loan.followUpConfig.lastNotificationTime!,
    );
    return diff.inMinutes >= loan.followUpConfig.intervalMinutes;
  }

  String _formatNext(LoanFile loan) {
    if (loan.followUpConfig.lastNotificationTime == null) return 'Now';
    final next = loan.followUpConfig.lastNotificationTime!.add(
      Duration(minutes: loan.followUpConfig.intervalMinutes),
    );
    if (DateTime.now().isAfter(next)) return 'Now';
    return '${next.hour}:${next.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildActivityPanel(BuildContext context, WidgetRef ref) {
    // Need to watch all loans to filter them
    final AsyncValue<List<LoanFile>> loansAsync = ref.watch(allLoansProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Files',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoanListScreen()),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: loansAsync.when(
                data: (loans) {
                  // Show all loans sorted by update date (recent first)
                  final recent = List<LoanFile>.from(loans);
                  recent.sort((a, b) => b.updatedDate.compareTo(a.updatedDate));

                  if (recent.isEmpty) {
                    return const Center(
                      child: Text('No files yet. Create one!'),
                    );
                  }

                  return ListView.separated(
                    itemCount: recent.length > 7 ? 7 : recent.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final loan = recent[index];
                      // Calculate days since update for subtitle context
                      final days = DateTime.now()
                          .difference(loan.updatedDate)
                          .inDays;
                      final timeStr = days == 0
                          ? 'Today'
                          : days == 1
                          ? 'Yesterday'
                          : '$days days ago';

                      return ListTile(
                        dense: true,
                        leading: StatusTag(
                          status: loan.status,
                        ), // Use smaller tag or icon? StatusTag is fine
                        title: Text(
                          loan.clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('ID: ${loan.fileId ?? "?"} • $timeStr'),
                        trailing: const Icon(Icons.chevron_right, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoanDetailScreen(loanId: loan.id),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final LoanStatus status;
  final int count;

  const _StatusCard({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoanListScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                status.label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
