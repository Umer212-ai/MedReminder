import 'package:thirdly/models/medicine_model.dart';
import 'package:thirdly/models/reminder_log_model.dart';

class TodayDoseSlot {
  final MedicineModel medicine;
  final String scheduleTime;
  final bool taken;
  final bool missed;

  const TodayDoseSlot({
    required this.medicine,
    required this.scheduleTime,
    required this.taken,
    required this.missed,
  });
}

bool isMedicineActiveToday(MedicineModel medicine, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final start = DateTime(
    medicine.startDate.year,
    medicine.startDate.month,
    medicine.startDate.day,
  );
  if (start.isAfter(today)) return false;
  if (medicine.endDate != null) {
    final end = DateTime(
      medicine.endDate!.year,
      medicine.endDate!.month,
      medicine.endDate!.day,
    );
    if (end.isBefore(today)) return false;
  }
  return medicine.isActive && medicine.scheduleTimes.isNotEmpty;
}

(int hour, int minute)? parseScheduleTime(String raw) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw.trim());
  if (match == null) return null;
  final h = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  if (h > 23 || m > 59) return null;
  return (h, m);
}

List<TodayDoseSlot> buildTodayDoseSlots({
  required List<MedicineModel> medicines,
  required List<ReminderLogModel> todayLogs,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final slots = <TodayDoseSlot>[];

  for (final med in medicines) {
    if (!isMedicineActiveToday(med, current)) continue;
    for (final time in med.scheduleTimes) {
      final taken = todayLogs.any(
        (log) =>
            log.medicineId == med.id &&
            log.scheduleTime == time &&
            log.status == ReminderStatus.taken,
      );
      final parsed = parseScheduleTime(time);
      var missed = false;
      if (!taken && parsed != null) {
        final doseAt = DateTime(
          current.year,
          current.month,
          current.day,
          parsed.$1,
          parsed.$2,
        );
        missed = current.isAfter(doseAt);
      }
      slots.add(
        TodayDoseSlot(
          medicine: med,
          scheduleTime: time,
          taken: taken,
          missed: missed,
        ),
      );
    }
  }

  slots.sort((a, b) {
    final pa = parseScheduleTime(a.scheduleTime);
    final pb = parseScheduleTime(b.scheduleTime);
    if (pa == null || pb == null) return 0;
    return pa.$1 != pb.$1 ? pa.$1.compareTo(pb.$1) : pa.$2.compareTo(pb.$2);
  });
  return slots;
}
