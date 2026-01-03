import 'dart:async';
import 'package:audit2fund/data/datasources/notification_service.dart';
import 'package:audit2fund/domain/entities/loan_file.dart';
import 'package:audit2fund/domain/repositories/loan_repository.dart';
import 'package:audit2fund/domain/repositories/settings_repository.dart';

class FollowUpService {
  final LoanRepository _loanRepository;
  final SettingsRepository _settingsRepository;
  final NotificationService _notificationService;
  Timer? _timer;

  FollowUpService(
    this._loanRepository,
    this._settingsRepository,
    this._notificationService,
  );

  void startService() {
    _timer?.cancel();
    // Check every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndNotify();
    });
    // Run immediately on start
    _checkAndNotify();
  }

  void stopService() {
    _timer?.cancel();
  }

  Future<void> _checkAndNotify() async {
    // 1. Check Office Hours
    final now = DateTime.now();
    final isWorkingDay = await _isWorkingDay(now);
    if (!isWorkingDay) return;

    final isOfficeHours = await _isOfficeHours(now);
    if (!isOfficeHours) return;

    // 2. Fetch Active Loans with Follow-up enabled
    // Optimally, repository should have getActiveFollowUps(), but getAllLoans is fine for now (local db)
    final allLoans = await _loanRepository.getAllLoans();
    final activeFollowUps = allLoans
        .where((l) => l.followUpConfig.isActive && !l.status.isFunded)
        .toList();

    for (final loan in activeFollowUps) {
      if (_shouldNotify(loan, now)) {
        await _notificationService.showFollowUpNotification(loan);
        await _updateLastNotificationTime(loan, now);
      }
    }
  }

  Future<bool> _isWorkingDay(DateTime date) async {
    final workingDays = await _settingsRepository.getWorkingDays(); // [1, 2...]
    return workingDays.contains(date.weekday);
  }

  Future<bool> _isOfficeHours(DateTime date) async {
    final start = await _settingsRepository.getOfficeStartTime();
    final end = await _settingsRepository.getOfficeEndTime();

    final currentMinutes = date.hour * 60 + date.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes =
        end.hour * 60 + end.minute; // Assuming end time is usually later in day

    // Simple check: start <= now < end
    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  bool _shouldNotify(LoanFile loan, DateTime now) {
    if (loan.followUpConfig.lastNotificationTime == null) {
      // Never notified. Notify immediately if inside office hours.
      return true;
    }

    final diff = now.difference(loan.followUpConfig.lastNotificationTime!);
    final interval = Duration(minutes: loan.followUpConfig.intervalMinutes);

    return diff >= interval;
  }

  Future<void> _updateLastNotificationTime(LoanFile loan, DateTime now) async {
    final updatedConfig = loan.followUpConfig.copyWith(
      lastNotificationTime: now,
    );
    final updatedLoan = loan.copyWith(followUpConfig: updatedConfig);
    // Use repository update logic directly to avoid double auditing or usecase overhead for system update
    // But direct update bypasses "Updated Date" if we aren't careful.
    // Let's just update the config.
    await _loanRepository.updateLoan(updatedLoan);
  }
}
