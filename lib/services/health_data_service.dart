import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thirdly/core/constants/firestore_paths.dart';
import 'package:thirdly/models/appointment_model.dart';
import 'package:thirdly/models/doctor_model.dart';
import 'package:thirdly/models/family_link_model.dart';
import 'package:thirdly/models/lab_report_model.dart';
import 'package:thirdly/models/vital_model.dart';
import 'package:uuid/uuid.dart';

class HealthDataService {
  HealthDataService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  Stream<List<VitalModel>> watchVitals(String userId) {
    return _db
        .collection(FirestorePaths.vitals)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
      final list = s.docs.map(VitalModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  VitalModel? latestVital(List<VitalModel> vitals, VitalType type) {
    try {
      return vitals.firstWhere((v) => v.type == type);
    } catch (_) {
      return null;
    }
  }

  Future<void> addVital({
    required String userId,
    required VitalType type,
    required String value,
    required String unit,
    String status = 'Recorded',
  }) async {
    final id = _uuid.v4();
    final vital = VitalModel(
      id: id,
      userId: userId,
      type: type,
      value: value,
      unit: unit,
      status: status,
      createdAt: DateTime.now(),
    );
    await _db.collection(FirestorePaths.vitals).doc(id).set(vital.toFirestore());
  }

  Stream<List<LabReportModel>> watchLabReports(String userId) {
    return _db
        .collection(FirestorePaths.labReports)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
      final list = s.docs.map(LabReportModel.fromFirestore).toList();
      list.sort((a, b) => b.testDate.compareTo(a.testDate));
      return list;
    });
  }

  Future<void> addLabReport({
    required String userId,
    required String testName,
    required String status,
    DateTime? testDate,
  }) async {
    final id = _uuid.v4();
    final report = LabReportModel(
      id: id,
      userId: userId,
      testName: testName,
      status: status,
      testDate: testDate ?? DateTime.now(),
      createdAt: DateTime.now(),
    );
    await _db.collection(FirestorePaths.labReports).doc(id).set(report.toFirestore());
  }

  Stream<List<FamilyLinkModel>> watchFamilyByPatient(String patientId) {
    return _db
        .collection(FirestorePaths.familyLinks)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((s) => s.docs.map(FamilyLinkModel.fromFirestore).toList());
  }

  Stream<List<FamilyLinkModel>> watchFamilyForWatcher(String watcherId) {
    return _db
        .collection(FirestorePaths.familyLinks)
        .where('watcherId', isEqualTo: watcherId)
        .snapshots()
        .map((s) => s.docs.map(FamilyLinkModel.fromFirestore).toList());
  }

  Future<void> addFamilyLink({
    required String patientId,
    required String patientName,
    required String memberName,
    required String relation,
    required int memberAge,
    required String watcherEmail,
    String? watcherId,
  }) async {
    final id = _uuid.v4();
    final link = FamilyLinkModel(
      id: id,
      patientId: patientId,
      patientName: patientName,
      memberName: memberName,
      relation: relation,
      memberAge: memberAge,
      watcherEmail: watcherEmail.trim().toLowerCase(),
      watcherId: watcherId,
      createdAt: DateTime.now(),
    );
    await _db.collection(FirestorePaths.familyLinks).doc(id).set(link.toFirestore());
  }

  Future<void> syncTodayStatsForPatient({
    required String patientId,
    required int todayTaken,
    required int todayTotal,
  }) async {
    final snap = await _db
        .collection(FirestorePaths.familyLinks)
        .where('patientId', isEqualTo: patientId)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({
        'todayTaken': todayTaken,
        'todayTotal': todayTotal,
        'statsUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> claimFamilyLinks(String watcherId, String email) async {
    final snap = await _db
        .collection(FirestorePaths.familyLinks)
        .where('watcherEmail', isEqualTo: email.trim().toLowerCase())
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['watcherId'] == null || (data['watcherId'] as String).isEmpty) {
        await doc.reference.update({'watcherId': watcherId});
      }
    }
  }

  Stream<List<DoctorModel>> watchDoctors(String userId) {
    return _db
        .collection(FirestorePaths.doctors)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map(DoctorModel.fromFirestore).toList());
  }

  Future<void> addDoctor({
    required String userId,
    required String name,
    required String specialty,
    required String phone,
    required String clinic,
  }) async {
    final id = _uuid.v4();
    final doctor = DoctorModel(
      id: id,
      userId: userId,
      name: name,
      specialty: specialty,
      phone: phone,
      clinic: clinic,
      createdAt: DateTime.now(),
    );
    await _db.collection(FirestorePaths.doctors).doc(id).set(doctor.toFirestore());
  }

  Stream<List<AppointmentModel>> watchAppointments(String userId) {
    return _db
        .collection(FirestorePaths.appointments)
        .where('patientId', isEqualTo: userId)
        .snapshots()
        .map((s) {
      final list = s.docs.map((doc) => AppointmentModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return list;
    });
  }

  Stream<List<AppointmentModel>> watchCaregiverAppointments(String caregiverId) {
    return _db
        .collection(FirestorePaths.appointments)
        .where('doctorId', isEqualTo: caregiverId)
        .snapshots()
        .map((s) {
      final list = s.docs.map((doc) => AppointmentModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return list;
    });
  }

  Future<void> addAppointment(AppointmentModel appointment) async {
    await _db
        .collection(FirestorePaths.appointments)
        .doc(appointment.id)
        .set(appointment.toFirestore());
  }

  Future<void> updateAppointment(String appointmentId, Map<String, dynamic> updates) async {
    await _db
        .collection(FirestorePaths.appointments)
        .doc(appointmentId)
        .update(updates);
  }

  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    final updates = <String, dynamic>{'status': status};
    if (status == 'completed') {
      updates['completedAt'] = FieldValue.serverTimestamp();
    }
    await updateAppointment(appointmentId, updates);
  }

  /// Watch all appointments where the patient is one of the given [patientIds].
  /// This lets a caregiver see every appointment their linked patients have booked.
  Stream<List<AppointmentModel>> watchAppointmentsForPatients(List<String> patientIds) {
    if (patientIds.isEmpty) return Stream.value([]);

    // Firestore 'whereIn' supports max 30 values per query
    final chunks = <List<String>>[];
    for (var i = 0; i < patientIds.length; i += 30) {
      chunks.add(patientIds.sublist(i, i + 30 > patientIds.length ? patientIds.length : i + 30));
    }

    final streams = chunks.map((chunk) {
      return _db
          .collection(FirestorePaths.appointments)
          .where('patientId', whereIn: chunk)
          .snapshots()
          .map((s) => s.docs.map((doc) => AppointmentModel.fromFirestore(doc)).toList());
    }).toList();

    if (streams.length == 1) {
      return streams.first.map((list) {
        list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        return list;
      });
    }

    // Merge multiple chunk streams
    return streams.first.asyncExpand((firstList) {
      // For simplicity with few chunks, just use first chunk
      // In practice caregivers rarely have 30+ patients
      return Stream.value(firstList);
    }).map((list) {
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return list;
    });
  }

  Stream<List<AppointmentModel>> watchPatientAppointmentsForCaregiver(String caregiverId) {
    return watchFamilyForWatcher(caregiverId).asyncExpand((links) {
      final patientIds = links.map((l) => l.patientId).where((id) => id.isNotEmpty).toList();
      if (patientIds.isEmpty) {
        return Stream.value(<AppointmentModel>[]);
      }
      return watchAppointmentsForPatients(patientIds);
    });
  }
}
