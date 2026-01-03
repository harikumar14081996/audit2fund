import 'package:audit2fund/data/datasources/notification_service.dart';
import 'package:audit2fund/domain/services/data_transfer_service.dart';
import 'package:audit2fund/domain/services/follow_up_service.dart';
import 'package:audit2fund/presentation/providers/core_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final followUpServiceProvider = Provider<FollowUpService>((ref) {
  final loanRepo = ref.watch(loanRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return FollowUpService(loanRepo, settingsRepo, notificationService);
});

final dataTransferServiceProvider = Provider<DataTransferService>((ref) {
  final loanRepo = ref.watch(loanRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return DataTransferService(loanRepo, settingsRepo);
});
