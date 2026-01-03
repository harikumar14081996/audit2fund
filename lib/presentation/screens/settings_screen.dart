import 'package:audit2fund/presentation/providers/core_providers.dart';
import 'package:audit2fund/presentation/providers/service_providers.dart';
import 'package:audit2fund/presentation/providers/loan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<int> _workingDays = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Use the notification service to request permissions correctly on macOS
    await ref.read(notificationServiceProvider).requestPermissions();
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(settingsRepositoryProvider);
    _startTime = await repo.getOfficeStartTime();
    _endTime = await repo.getOfficeEndTime();
    _workingDays = await repo.getWorkingDays();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'Office Schedule',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Reminders only fire during these hours.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Office Start Time'),
            subtitle: Text(_startTime!.format(context)),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final newTime = await showTimePicker(
                context: context,
                initialTime: _startTime!,
              );
              if (newTime != null) {
                await ref
                    .read(settingsRepositoryProvider)
                    .setOfficeStartTime(newTime);
                setState(() => _startTime = newTime);
              }
            },
          ),
          ListTile(
            title: const Text('Office End Time'),
            subtitle: Text(_endTime!.format(context)),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final newTime = await showTimePicker(
                context: context,
                initialTime: _endTime!,
              );
              if (newTime != null) {
                await ref
                    .read(settingsRepositoryProvider)
                    .setOfficeEndTime(newTime);
                setState(() => _endTime = newTime);
              }
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Working Days',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final day = index + 1; // 1=Mon, 7=Sun
              final isSelected = _workingDays.contains(day);
              final label = [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ][index];
              return FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (val) async {
                  setState(() {
                    final currentList = List<int>.of(_workingDays);
                    if (val) {
                      currentList.add(day);
                    } else {
                      currentList.remove(day);
                    }
                    _workingDays = currentList;
                  });
                  await ref
                      .read(settingsRepositoryProvider)
                      .setWorkingDays(_workingDays);
                },
              );
            }),
          ),
          const Divider(height: 48),
          const Text(
            'Data Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () async {
                  final msg = await ref
                      .read(dataTransferServiceProvider)
                      .exportData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Export Database'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final msg = await ref
                      .read(dataTransferServiceProvider)
                      .importData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(msg)));
                    // Refresh data
                    ref.invalidate(allLoansProvider);
                  }
                },
                icon: const Icon(Icons.upload),
                label: const Text('Import Database'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
