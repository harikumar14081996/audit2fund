import 'dart:io';
import 'package:audit2fund/domain/entities/loan_file.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Don't request permissions immediately on init if we want to defer it to the button tap
    // But keeping it true is fine as long as we haven't inited yet.
    // However, to be safe and explicit, let's set them to false here and request manually.
    const macOsSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: macOsSettings,
      macOS: macOsSettings,
      linux: linuxSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap
      },
    );

    _initialized = true;
  }

  Future<bool?> requestPermissions() async {
    // Ensure initialized first (without requesting permissions implicitly)
    if (!_initialized) await init();

    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImplementation?.requestNotificationsPermission();
    } else if (Platform.isMacOS) {
      return await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    return false;
  }

  Future<void> showFollowUpNotification(LoanFile loan) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'follow_up_channel',
      'Follow Ups',
      channelDescription: 'Reminders for loan follow-ups',
      importance: Importance.high,
      priority: Priority.high,
    );

    const macOsDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const linuxDetails = LinuxNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      macOS: macOsDetails,
      linux: linuxDetails,
    );

    // Use a hash of the ID for the integer request code, avoiding collisions
    final id = loan.id.hashCode;

    await _notificationsPlugin.show(
      id,
      'Follow Up Required: ${loan.clientName}',
      'Status: ${loan.status.label} • Amount: \$${loan.approvedAmount.toStringAsFixed(0)}',
      details,
      payload: loan.id,
    );
  }
}
