import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:thirdly/models/medicine_model.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules local alarms 1 minute before each medicine dose time.
class ReminderSchedulerService {
  ReminderSchedulerService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  Future<void> ensureReady() async {
    if (_ready || kIsWeb) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _ready = true;
  }

  int _id(String medicineId, int slot) =>
      '${medicineId}_$slot'.hashCode & 0x7FFFFFFF;

  (int hour, int minute)? _parseTime(String raw) {
    final cleaned = raw.trim().toUpperCase();
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$').firstMatch(cleaned);
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final ampm = match.group(3);
    if (ampm == 'PM' && hour < 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return (hour, minute);
  }

  Future<void> cancelMedicine(MedicineModel medicine) async {
    if (kIsWeb) return;
    for (var i = 0; i < medicine.scheduleTimes.length; i++) {
      await _plugin.cancel(_id(medicine.id, i));
    }
  }

  Future<void> scheduleMedicine({
    required MedicineModel medicine,
    required String patientName,
  }) async {
    if (kIsWeb) return;
    await ensureReady();
    await cancelMedicine(medicine);

    final location = tz.local;
    final now = tz.TZDateTime.now(location);

    for (var i = 0; i < medicine.scheduleTimes.length; i++) {
      final parsed = _parseTime(medicine.scheduleTimes[i]);
      if (parsed == null) continue;

      var doseTime = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        parsed.$1,
        parsed.$2,
      );
      var reminderTime = doseTime.subtract(const Duration(minutes: 1));
      if (reminderTime.isBefore(now)) {
        doseTime = doseTime.add(const Duration(days: 1));
        reminderTime = doseTime.subtract(const Duration(minutes: 1));
      }

      await _plugin.zonedSchedule(
        _id(medicine.id, i),
        'Medicine Reminder',
        '$patientName, take ${medicine.name} (${medicine.dosage}) in 1 minute',
        reminderTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_reminders',
            'Medicine Reminders',
            channelDescription: 'Ring 1 minute before scheduled dose',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> rescheduleAll({
    required List<MedicineModel> medicines,
    required String patientName,
  }) async {
    for (final med in medicines) {
      await scheduleMedicine(medicine: med, patientName: patientName);
    }
  }
}
