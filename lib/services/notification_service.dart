import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:typed_data';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Channel IDs
  static const String billChannelId = 'bill_reminders';
  static const String readingChannelId = 'reading_reminders';
  static const String billChannelGroupId = 'bill_notifications';
  static const String readingChannelGroupId = 'reading_notifications';

  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();

      // Create notification channel groups for Android
      await _createNotificationChannelGroups();

      // Create notification channels for Android
      await _createNotificationChannels();

      final androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // We'll request permissions separately
        requestBadgePermission: false,
        requestSoundPermission: false,
        requestCriticalPermission: true, // Support for critical alerts
        notificationCategories: [
          DarwinNotificationCategory(
            'bill_reminder',
            actions: [
              DarwinNotificationAction.plain(
                'MARK_AS_PAID',
                'Mark as Paid',
                options: {
                  DarwinNotificationActionOption.foreground,
                },
              ),
            ],
          ),
          DarwinNotificationCategory(
            'reading_reminder',
            actions: [
              DarwinNotificationAction.plain(
                'TAKE_READING',
                'Take Reading',
                options: {
                  DarwinNotificationActionOption.foreground,
                },
              ),
            ],
          ),
        ],
      );

      final settings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _handleNotificationResponse,
      );
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
      rethrow;
    }
  }

  static Future<void> _createNotificationChannelGroups() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannelGroup(
        AndroidNotificationChannelGroup(
          billChannelGroupId,
          'Bill Notifications',
          description: 'All notifications related to bills',
        ),
      );
      await androidImplementation.createNotificationChannelGroup(
        AndroidNotificationChannelGroup(
          readingChannelGroupId,
          'Reading Notifications',
          description: 'All notifications related to meter readings',
        ),
      );
    }
  }

  static Future<void> _createNotificationChannels() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          billChannelId,
          'Bill Reminders',
          description: 'Notifications for bill payment reminders',
          groupId: billChannelGroupId,
          importance: Importance.high,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
          enableLights: true,
        ),
      );

      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          readingChannelId,
          'Reading Reminders',
          description: 'Notifications for meter reading reminders',
          groupId: readingChannelGroupId,
          importance: Importance.high,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 500, 500]),
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
          enableLights: true,
        ),
      );
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      // For Android 13 and above
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final androidResult =
            await androidImplementation.requestNotificationsPermission();
        if (androidResult != true) {
          debugPrint('Android notification permissions denied');
          return false;
        }
      }

      // For iOS
      final iOSImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iOSImplementation != null) {
        final iosResult = await iOSImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );

        if (iosResult != true) {
          debugPrint('iOS notification permissions denied or request failed');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Failed to request notification permissions: $e');
      return false;
    }
  }

  static Future<void> scheduleBillReminder({
    required String billId,
    required String meterName,
    required String clientName,
    required double amount,
    required DateTime dueDate,
    int daysBeforeDue = 3,
  }) async {
    try {
      final notificationDate = dueDate.subtract(Duration(days: daysBeforeDue));

      if (notificationDate.isBefore(DateTime.now())) {
        debugPrint('Notification date is in the past, skipping scheduling');
        return;
      }

      final androidDetails = AndroidNotificationDetails(
        billChannelId,
        'Bill Reminders',
        channelDescription: 'Notifications for bill payment reminders',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: billChannelGroupId,
        category: AndroidNotificationCategory.reminder,
        fullScreenIntent: true,
        actions: [
          const AndroidNotificationAction(
            'MARK_AS_PAID',
            'Mark as Paid',
            showsUserInterface: true,
          ),
        ],
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'bill_reminder',
        threadIdentifier: billId,
      );

      final details =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.zonedSchedule(
        billId.hashCode,
        'Bill Payment Reminder',
        'Payment of €$amount for $meterName ($clientName) is due in $daysBeforeDue days',
        tz.TZDateTime.from(notificationDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'bill:$billId',
      );
    } catch (e) {
      debugPrint('Failed to schedule bill reminder: $e');
      rethrow;
    }
  }

  static Future<void> scheduleDailyReadingReminder({
    required TimeOfDay time,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        readingChannelId,
        'Reading Reminders',
        channelDescription: 'Notifications for meter reading reminders',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: readingChannelGroupId,
        category: AndroidNotificationCategory.reminder,
        actions: [
          const AndroidNotificationAction(
            'TAKE_READING',
            'Take Reading',
            showsUserInterface: true,
          ),
        ],
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'reading_reminder',
        threadIdentifier: 'daily_reading',
      );

      final details =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        'daily_reading'.hashCode,
        'Meter Reading Reminder',
        'Time to take your daily meter readings',
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'reading:daily',
      );
    } catch (e) {
      debugPrint('Failed to schedule daily reading reminder: $e');
      rethrow;
    }
  }

  static void _handleNotificationResponse(NotificationResponse response) {
    if (response.payload == null) return;

    final parts = response.payload!.split(':');
    if (parts.length != 2) return;

    final type = parts[0];
    final id = parts[1];

    switch (type) {
      case 'bill':
        if (response.actionId == 'MARK_AS_PAID') {
          // Handle mark as paid action
          debugPrint('Bill $id marked as paid from notification');
        }
        break;
      case 'reading':
        if (response.actionId == 'TAKE_READING') {
          // Handle take reading action
          debugPrint('Taking reading from notification');
        }
        break;
    }
  }

  static Future<void> cancelBillReminder(String billId) async {
    try {
      await _notifications.cancel(billId.hashCode);
    } catch (e) {
      debugPrint('Failed to cancel bill reminder: $e');
      rethrow;
    }
  }

  static Future<void> cancelDailyReadingReminder() async {
    try {
      await _notifications.cancel('daily_reading'.hashCode);
    } catch (e) {
      debugPrint('Failed to cancel daily reading reminder: $e');
      rethrow;
    }
  }

  static Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel all reminders: $e');
      rethrow;
    }
  }

  static Future<List<PendingNotificationRequest>> getPendingReminders() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Failed to get pending reminders: $e');
      rethrow;
    }
  }
}
