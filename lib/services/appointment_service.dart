import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thirdly/core/constants/firestore_paths.dart';
import 'package:thirdly/models/appointment_model.dart';
import 'package:thirdly/services/notification_helper_service.dart';
import 'package:uuid/uuid.dart';

class AppointmentService {
  AppointmentService({
    FirebaseFirestore? firestore,
    NotificationHelperService? notificationHelper,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationHelper = notificationHelper ?? NotificationHelperService();

  final FirebaseFirestore _firestore;
  final NotificationHelperService _notificationHelper;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection(FirestorePaths.appointments);

  Future<AppointmentModel> bookAppointment({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required DateTime dateTime,
    required String problem,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final appointment = AppointmentModel(
      id: id,
      patientId: patientId,
      patientName: patientName,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      dateTime: dateTime,
      problem: problem,
      status: 'pending',
      createdAt: now,
    );
    await _appointments.doc(id).set(appointment.toFirestore());
    
    // Send notification to caregiver (doctor)
    await _notificationHelper.sendNewAppointmentRequest(
      caregiverId: doctorId,
      patientName: patientName,
      appointmentDate: dateTime,
      problem: problem,
    );
    
    return appointment;
  }

  Stream<List<AppointmentModel>> watchPatientAppointments(String patientId) {
    return _appointments
        .where('patientId', isEqualTo: patientId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppointmentModel.fromFirestore).toList());
  }

  Stream<List<AppointmentModel>> watchDoctorAppointments(String doctorId) {
    return _appointments
        .where('doctorId', isEqualTo: doctorId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppointmentModel.fromFirestore).toList());
  }

  Stream<List<AppointmentModel>> watchUpcomingAppointments(String doctorId) {
    final now = DateTime.now();
    return _appointments
        .where('doctorId', isEqualTo: doctorId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .where('dateTime', isGreaterThan: now)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppointmentModel.fromFirestore).toList());
  }

  Future<void> confirmAppointment(String appointmentId) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return;
    final appointment = AppointmentModel.fromFirestore(doc);
    
    await _appointments.doc(appointmentId).update({
      'status': 'confirmed',
    });
    
    // Send notification to patient
    await _notificationHelper.sendAppointmentConfirmed(
      patientId: appointment.patientId,
      doctorName: appointment.doctorName,
      appointmentDate: appointment.dateTime,
    );
  }

  Future<void> declineAppointment(String appointmentId) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return;
    final appointment = AppointmentModel.fromFirestore(doc);
    
    await _appointments.doc(appointmentId).update({
      'status': 'cancelled',
    });
    
    // Send notification to patient
    await _notificationHelper.sendAppointmentDeclined(
      patientId: appointment.patientId,
      doctorName: appointment.doctorName,
      appointmentDate: appointment.dateTime,
    );
  }

  Future<void> completeAppointment({
    required String appointmentId,
    String? caregiverNotes,
    String? recommendations,
    DateTime? followUpDate,
  }) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return;
    final appointment = AppointmentModel.fromFirestore(doc);
    
    final updates = <String, dynamic>{
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    };
    
    if (caregiverNotes != null) {
      updates['caregiverNotes'] = caregiverNotes;
    }
    
    if (recommendations != null) {
      updates['recommendations'] = recommendations;
    }
    
    if (followUpDate != null) {
      updates['followUpDate'] = Timestamp.fromDate(followUpDate);
    }
    
    await _appointments.doc(appointmentId).update(updates);
    
    // Send notification to patient
    await _notificationHelper.sendAppointmentCompleted(
      patientId: appointment.patientId,
      doctorName: appointment.doctorName,
      appointmentDate: appointment.dateTime,
    );
    
    if (caregiverNotes != null && caregiverNotes.isNotEmpty) {
      await _notificationHelper.sendNewNoteAdded(
        patientId: appointment.patientId,
        caregiverName: appointment.doctorName,
        notePreview: caregiverNotes.length > 50 ? caregiverNotes.substring(0, 50) + '...' : caregiverNotes,
      );
    }
    
    if (followUpDate != null) {
      await _notificationHelper.sendFollowUpScheduled(
        patientId: appointment.patientId,
        followUpDate: followUpDate,
        doctorName: appointment.doctorName,
      );
    }
  }

  Future<void> updateAppointmentNotesAndRecommendations({
    required String appointmentId,
    required String caregiverNotes,
    required String recommendations,
  }) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return;
    final appointment = AppointmentModel.fromFirestore(doc);
    
    await _appointments.doc(appointmentId).update({
      'caregiverNotes': caregiverNotes,
      'recommendations': recommendations,
    });
    
    // Send notification to patient
    await _notificationHelper.sendNewNoteAdded(
      patientId: appointment.patientId,
      caregiverName: appointment.doctorName,
      notePreview: caregiverNotes.length > 50 ? caregiverNotes.substring(0, 50) + '...' : caregiverNotes,
    );
  }

  Future<void> updateAppointmentNotes({
    required String appointmentId,
    required String caregiverNotes,
  }) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return;
    final appointment = AppointmentModel.fromFirestore(doc);
    
    await _appointments.doc(appointmentId).update({
      'caregiverNotes': caregiverNotes,
    });
    
    // Send notification to patient
    await _notificationHelper.sendNewNoteAdded(
      patientId: appointment.patientId,
      caregiverName: appointment.doctorName,
      notePreview: caregiverNotes.length > 50 ? caregiverNotes.substring(0, 50) + '...' : caregiverNotes,
    );
  }

  Future<void> scheduleFollowUp({
    required String appointmentId,
    required DateTime followUpDate,
  }) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return;
    final appointment = AppointmentModel.fromFirestore(doc);
    
    await _appointments.doc(appointmentId).update({
      'followUpDate': Timestamp.fromDate(followUpDate),
    });
    
    // Send notification to patient
    await _notificationHelper.sendFollowUpScheduled(
      patientId: appointment.patientId,
      followUpDate: followUpDate,
      doctorName: appointment.doctorName,
    );
  }
}
