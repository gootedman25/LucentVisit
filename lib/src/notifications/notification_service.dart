import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';
import '../models/entry_validation.dart';
import 'reminder_service.dart';

/// Schedules local (on-device) reminders for appointments and medications.
/// Nothing leaves the device.
class NotificationService implements ReminderService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const NotificationDetails _details = NotificationDetails(
    iOS: DarwinNotificationDetails(),
    android: AndroidNotificationDetails(
      // Android channel IDs are persistent compatibility identifiers. Changing
      // this old name creates a new channel instead of renaming the existing one.
      'clearvisit_reminders',
      'Reminders',
      channelDescription: 'Appointment and medication reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      // flutter_timezone returns a String in 3.x and a TimezoneInfo in
      // newer versions; handle both.
      final dynamic zone = await FlutterTimezone.getLocalTimezone();
      final String zoneName = zone is String ? zone : zone.identifier as String;
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (error) {
      debugPrint('NotificationService: could not set local timezone: $error');
    }
    try {
      await _plugin.initialize(
        const InitializationSettings(
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (error) {
      debugPrint('NotificationService: initialization failed: $error');
    }
  }

  /// Cancels everything and reschedules reminders for the given data.
  /// Called after every data change so reminders always match the database.
  @override
  Future<void> sync(
    List<Appointment> appointments,
    List<Medication> medications,
  ) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      var id = 0;
      final now = tz.TZDateTime.now(tz.local);

      for (final value in appointments) {
        if (value.reminderMinutes < 0) continue;
        final when = tz.TZDateTime.from(
          value.date,
          tz.local,
        ).subtract(Duration(minutes: value.reminderMinutes));
        if (!when.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          id++,
          'Upcoming visit',
          value.provider.isEmpty
              ? value.reason
              : '${value.reason} • ${value.provider}',
          when,
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      for (final value in medications) {
        if (value.reminderMinutes < 0 ||
            !value.active ||
            !supportsDailyMedicationReminders(value.schedule)) {
          continue;
        }
        for (final time in value.times) {
          final parts = time.split(':');
          if (parts.length != 2) continue;
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour == null || minute == null) continue;
          if (hour < 0 || hour > 23 || minute < 0 || minute > 59) continue;
          var when = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            hour,
            minute,
          ).subtract(Duration(minutes: value.reminderMinutes));
          while (!when.isAfter(now)) {
            when = when.add(const Duration(days: 1));
          }
          await _plugin.zonedSchedule(
            id++,
            'Medication reminder',
            [
              value.name,
              value.strength,
              value.dose,
            ].where((part) => part.isNotEmpty).join(' • '),
            when,
            _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }
    } catch (error) {
      debugPrint('NotificationService: scheduling failed: $error');
    }
  }
}
