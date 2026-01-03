import 'package:audit2fund/core/constants/loan_status.dart';
import 'package:audit2fund/presentation/providers/loan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _timeFilter = 'Month'; // 'Week', 'Month', 'All'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance Reports')),
      body: ref
          .watch(allLoansProvider)
          .when(
            data: (allLoans) {
              // 1. Filter Data
              final now = DateTime.now();
              final filteredLoans = allLoans.where((l) {
                if (_timeFilter == 'All') return true;
                if (_timeFilter == 'Week') {
                  // Simple "Last 7 days" or "This Week" check
                  final diff = now.difference(l.createdDate).inDays;
                  return diff <= 7;
                }
                if (_timeFilter == 'Month') {
                  final diff = now.difference(l.createdDate).inDays;
                  return diff <= 30;
                }
                return true;
              }).toList();

              // 2. Calculate Metrics
              final totalCount = filteredLoans.length;
              final fundedLoans = filteredLoans
                  .where((l) => l.status == LoanStatus.funded)
                  .toList();
              final fundedCount = fundedLoans.length;

              final totalApprovedAmount = filteredLoans.fold(
                0.0,
                (sum, l) => sum + l.approvedAmount,
              );
              final totalFundedAmount = fundedLoans.fold(
                0.0,
                (sum, l) => sum + l.approvedAmount,
              );

              final conversionRate = totalCount == 0
                  ? 0.0
                  : (fundedCount / totalCount);

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Row
                    Row(
                      children: [
                        const Text(
                          'Time Period:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'Week',
                              label: Text('Last 7 Days'),
                            ),
                            ButtonSegment(
                              value: 'Month',
                              label: Text('Last 30 Days'),
                            ),
                            ButtonSegment(
                              value: 'All',
                              label: Text('All Time'),
                            ),
                          ],
                          selected: {_timeFilter},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _timeFilter = newSelection.first;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Metrics Grid
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        _MetricCard(
                          title: 'Total Files',
                          value: totalCount.toString(),
                          icon: Icons.folder_open,
                          color: Colors.blueGrey,
                        ),
                        _MetricCard(
                          title: 'Conversion Rate',
                          value:
                              '${(conversionRate * 100).toStringAsFixed(1)}%',
                          icon: Icons.percent,
                          color: Colors.teal,
                        ),
                        _MetricCard(
                          title: 'Funded Volume',
                          value: NumberFormat.currency(
                            symbol: '\$',
                          ).format(totalFundedAmount),
                          icon: Icons.attach_money,
                          color: Colors.green,
                        ),
                        _MetricCard(
                          title: 'Pipeline Value',
                          value: NumberFormat.currency(
                            symbol: '\$',
                          ).format(totalApprovedAmount),
                          subtitle: '(Total Approved)',
                          icon: Icons.account_balance_wallet,
                          color: Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),
                    const Text(
                      'Funded Breakdown',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: fundedLoans.length,
                        separatorBuilder: (c, i) => const Divider(),
                        itemBuilder: (context, index) {
                          final l = fundedLoans[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              l.clientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Funded on ${DateFormat.yMMMd().format(l.updatedDate)}',
                            ),
                            trailing: Text(
                              NumberFormat.currency(
                                symbol: '\$',
                              ).format(l.approvedAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
