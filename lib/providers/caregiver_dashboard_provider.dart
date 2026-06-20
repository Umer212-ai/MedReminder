import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:thirdly/core/utils/dose_utils.dart';
import 'package:thirdly/models/family_link_model.dart';
import 'package:thirdly/models/medicine_model.dart';
import 'package:thirdly/models/reminder_log_model.dart';
import 'package:thirdly/models/vital_model.dart';
import 'package:thirdly/models/lab_report_model.dart';
import 'package:thirdly/services/health_data_service.dart';
import 'package:thirdly/services/medicine_service.dart';

class CaregiverAlert {
  final String patientId;
  final String patientName;
  final String message;
  final String type; // 'missed_medicine' | 'high_bp' | 'abnormal_hr' | 'no_vitals'
  final DateTime timestamp;
  final String severity; // 'warning' | 'critical'

  const CaregiverAlert({
    required this.patientId,
    required this.patientName,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.severity,
  });
}

class UpcomingMedicineItem {
  final String patientId;
  final String patientName;
  final String medicineName;
  final String dosage;
  final String time;
  final DateTime scheduledAt;

  const UpcomingMedicineItem({
    required this.patientId,
    required this.patientName,
    required this.medicineName,
    required this.dosage,
    required this.time,
    required this.scheduledAt,
  });
}

class ActivityFeedItem {
  final String patientId;
  final String patientName;
  final String message;
  final String type; // 'took_med' | 'missed_med' | 'vital_recorded' | 'lab_added'
  final DateTime timestamp;

  const ActivityFeedItem({
    required this.patientId,
    required this.patientName,
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

class PatientSnapshot {
  final FamilyLinkModel link;
  final List<MedicineModel> medicines;
  final List<ReminderLogModel> todayLogs;
  final List<VitalModel> vitals;
  final List<LabReportModel> labReports;

  List<TodayDoseSlot> get todayDoseSlots => buildTodayDoseSlots(
        medicines: medicines,
        todayLogs: todayLogs,
      );

  const PatientSnapshot({
    required this.link,
    this.medicines = const [],
    this.todayLogs = const [],
    this.vitals = const [],
    this.labReports = const [],
  });

  PatientSnapshot copyWith({
    FamilyLinkModel? link,
    List<MedicineModel>? medicines,
    List<ReminderLogModel>? todayLogs,
    List<VitalModel>? vitals,
    List<LabReportModel>? labReports,
  }) {
    return PatientSnapshot(
      link: link ?? this.link,
      medicines: medicines ?? this.medicines,
      todayLogs: todayLogs ?? this.todayLogs,
      vitals: vitals ?? this.vitals,
      labReports: labReports ?? this.labReports,
    );
  }
}

class CaregiverDashboardProvider extends ChangeNotifier {
  CaregiverDashboardProvider({
    HealthDataService? healthService,
    MedicineService? medicineService,
  })  : _healthService = healthService ?? HealthDataService(),
        _medicineService = medicineService ?? MedicineService();

  final HealthDataService _healthService;
  final MedicineService _medicineService;

  final Map<String, PatientSnapshot> _patientSnapshots = {};
  final Map<String, List<StreamSubscription>> _patientSubscriptions = {};
  StreamSubscription? _watcherSubscription;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  List<FamilyLinkModel> get patients => _patientSnapshots.values.map((s) => s.link).toList();
  int get patientsCount => _patientSnapshots.length;

  double get complianceRate {
    int total = 0;
    int taken = 0;
    for (final snap in _patientSnapshots.values) {
      final slots = snap.todayDoseSlots;
      total += slots.length;
      taken += slots.where((s) => s.taken).length;
    }
    return total == 0 ? 100.0 : (taken / total) * 100;
  }

  int get missedDosesCount {
    int count = 0;
    for (final snap in _patientSnapshots.values) {
      count += snap.todayDoseSlots.where((s) => s.missed && !s.taken).length;
    }
    return count;
  }

  List<CaregiverAlert> get criticalAlerts {
    final alerts = <CaregiverAlert>[];
    final now = DateTime.now();

    for (final snap in _patientSnapshots.values) {
      final patientId = snap.link.patientId;
      final name = snap.link.patientName;

      // 1. Missed Medicines Alert
      final missedSlots = snap.todayDoseSlots.where((s) => s.missed && !s.taken);
      for (final slot in missedSlots) {
        alerts.add(CaregiverAlert(
          patientId: patientId,
          patientName: name,
          message: '$name missed ${slot.medicine.name} Scheduled @ ${slot.scheduleTime}',
          type: 'missed_medicine',
          timestamp: now, // recent today event
          severity: 'warning',
        ));
      }

      // 2. High Blood Pressure Alert
      final bp = _getLatestVital(snap.vitals, VitalType.bloodPressure);
      if (bp != null && bp.value.isNotEmpty) {
        final parts = bp.value.split('/');
        if (parts.length == 2) {
          final sys = int.tryParse(parts[0].trim());
          final dia = int.tryParse(parts[1].trim());
          if (sys != null && dia != null && (sys > 130 || dia > 80)) {
            alerts.add(CaregiverAlert(
              patientId: patientId,
              patientName: name,
              message: '$name blood pressure high: ${bp.value} mmHg',
              type: 'high_bp',
              timestamp: bp.createdAt,
              severity: 'critical',
            ));
          }
        }
      }

      // 3. Abnormal Heart Rate Alert
      final hr = _getLatestVital(snap.vitals, VitalType.heartRate);
      if (hr != null && hr.value.isNotEmpty) {
        final val = int.tryParse(hr.value.trim());
        if (val != null && (val < 60 || val > 100)) {
          alerts.add(CaregiverAlert(
            patientId: patientId,
            patientName: name,
            message: '$name abnormal heart rate: $val bpm',
            type: 'abnormal_hr',
            timestamp: hr.createdAt,
            severity: 'critical',
          ));
        }
      }

      // 4. No Vitals Logged Today Alert
      if (snap.vitals.isEmpty) {
        alerts.add(CaregiverAlert(
          patientId: patientId,
          patientName: name,
          message: '$name has not recorded vitals today',
          type: 'no_vitals',
          timestamp: now,
          severity: 'warning',
        ));
      } else {
        final latest = snap.vitals.first.createdAt;
        final todayStart = DateTime(now.year, now.month, now.day);
        if (latest.isBefore(todayStart)) {
          alerts.add(CaregiverAlert(
            patientId: patientId,
            patientName: name,
            message: '$name has not recorded vitals today',
            type: 'no_vitals',
            timestamp: now,
            severity: 'warning',
          ));
        }
      }
    }

    // Sort: critical first, then warning, then newest timestamp
    alerts.sort((a, b) {
      if (a.severity != b.severity) {
        return a.severity == 'critical' ? -1 : 1;
      }
      return b.timestamp.compareTo(a.timestamp);
    });

    return alerts;
  }

  List<UpcomingMedicineItem> get upcomingMedicines {
    final list = <UpcomingMedicineItem>[];
    final now = DateTime.now();

    for (final snap in _patientSnapshots.values) {
      final patientId = snap.link.patientId;
      final name = snap.link.patientName;
      final slots = snap.todayDoseSlots.where((s) => !s.taken && !s.missed);

      for (final slot in slots) {
        final parsed = parseScheduleTime(slot.scheduleTime);
        final scheduled = DateTime(
          now.year,
          now.month,
          now.day,
          parsed?.$1 ?? 12,
          parsed?.$2 ?? 0,
        );
        list.add(UpcomingMedicineItem(
          patientId: patientId,
          patientName: name,
          medicineName: slot.medicine.name,
          dosage: slot.medicine.dosage,
          time: slot.scheduleTime,
          scheduledAt: scheduled,
        ));
      }
    }

    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  List<ActivityFeedItem> get recentActivities {
    final list = <ActivityFeedItem>[];
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (final snap in _patientSnapshots.values) {
      final patientId = snap.link.patientId;
      final name = snap.link.patientName;

      // 1. Medicine taken logs
      final takenLogs = snap.todayLogs.where((l) => l.status == ReminderStatus.taken);
      for (final log in takenLogs) {
        list.add(ActivityFeedItem(
          patientId: patientId,
          patientName: name,
          message: '$name took ${log.medicineName} Scheduled @ ${log.scheduleTime}',
          type: 'took_med',
          timestamp: log.completedAt ?? log.scheduledAt,
        ));
      }

      // 2. Medicine missed slots
      final missedSlots = snap.todayDoseSlots.where((s) => s.missed && !s.taken);
      for (final slot in missedSlots) {
        final parsed = parseScheduleTime(slot.scheduleTime);
        final scheduled = DateTime(
          now.year,
          now.month,
          now.day,
          parsed?.$1 ?? 8,
          parsed?.$2 ?? 0,
        );
        list.add(ActivityFeedItem(
          patientId: patientId,
          patientName: name,
          message: '$name missed dose: ${slot.medicine.name} scheduled for ${slot.scheduleTime}',
          type: 'missed_med',
          timestamp: scheduled,
        ));
      }

      // 3. Vitals recorded
      for (final vital in snap.vitals) {
        if (vital.createdAt.isAfter(todayStart)) {
          list.add(ActivityFeedItem(
            patientId: patientId,
            patientName: name,
            message: '$name recorded vital: ${vital.title} (${vital.value} ${vital.unit})',
            type: 'vital_recorded',
            timestamp: vital.createdAt,
          ));
        }
      }

      // 4. Lab reports added
      for (final report in snap.labReports) {
        if (report.createdAt.isAfter(todayStart)) {
          list.add(ActivityFeedItem(
            patientId: patientId,
            patientName: name,
            message: '$name added lab report: ${report.testName}',
            type: 'lab_added',
            timestamp: report.createdAt,
          ));
        }
      }
    }

    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  String getPatientStatus(String patientId) {
    final alerts = criticalAlerts.where((a) => a.patientId == patientId);
    if (alerts.any((a) => a.severity == 'critical')) {
      return 'High Risk';
    } else if (alerts.isNotEmpty) {
      return 'Attention Needed';
    }
    return 'Stable';
  }

  void initialize(String watcherId, String email) {
    _watcherSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _watcherSubscription = _healthService.watchFamilyForWatcherEmail(email).listen((links) {
      // Automatically claim any unclaimed links
      for (final link in links) {
        if (link.watcherId == null || link.watcherId!.isEmpty) {
          _healthService.claimFamilyLinks(watcherId, email);
        }
      }

      final activeIds = links.map((l) => l.patientId).toSet();

      // Clean up unsubscribed patients
      final currentIds = _patientSnapshots.keys.toList();
      for (final id in currentIds) {
        if (!activeIds.contains(id)) {
          _cancelPatientStreams(id);
          _patientSnapshots.remove(id);
        }
      }

      if (links.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Initialize subscriptions for new patients
      for (final link in links) {
        final id = link.patientId;
        if (!_patientSnapshots.containsKey(id)) {
          _patientSnapshots[id] = PatientSnapshot(link: link);
          _subscribePatientStreams(id);
        } else {
          // Update patient link metadata (age, names etc)
          _patientSnapshots[id] = _patientSnapshots[id]!.copyWith(link: link);
        }
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  void _subscribePatientStreams(String patientId) {
    _cancelPatientStreams(patientId);

    final subs = <StreamSubscription>[];

    subs.add(_medicineService.watchUserMedicines(patientId).listen((list) {
      if (_patientSnapshots.containsKey(patientId)) {
        _patientSnapshots[patientId] = _patientSnapshots[patientId]!.copyWith(medicines: list);
        notifyListeners();
      }
    }));

    subs.add(_medicineService.watchTodayLogs(patientId).listen((logs) {
      if (_patientSnapshots.containsKey(patientId)) {
        _patientSnapshots[patientId] = _patientSnapshots[patientId]!.copyWith(todayLogs: logs);
        notifyListeners();
      }
    }));

    subs.add(_healthService.watchVitals(patientId).listen((list) {
      if (_patientSnapshots.containsKey(patientId)) {
        _patientSnapshots[patientId] = _patientSnapshots[patientId]!.copyWith(vitals: list);
        notifyListeners();
      }
    }));

    subs.add(_healthService.watchLabReports(patientId).listen((list) {
      if (_patientSnapshots.containsKey(patientId)) {
        _patientSnapshots[patientId] = _patientSnapshots[patientId]!.copyWith(labReports: list);
        notifyListeners();
      }
    }));

    _patientSubscriptions[patientId] = subs;
  }

  void _cancelPatientStreams(String patientId) {
    if (_patientSubscriptions.containsKey(patientId)) {
      for (final sub in _patientSubscriptions[patientId]!) {
        sub.cancel();
      }
      _patientSubscriptions.remove(patientId);
    }
  }

  VitalModel? _getLatestVital(List<VitalModel> vitals, VitalType type) {
    try {
      return vitals.firstWhere((v) => v.type == type);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _watcherSubscription?.cancel();
    for (final id in _patientSubscriptions.keys.toList()) {
      _cancelPatientStreams(id);
    }
    super.dispose();
  }
}
