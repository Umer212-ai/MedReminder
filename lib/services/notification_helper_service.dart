import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:thirdly/core/constants/firestore_paths.dart';
import 'package:thirdly/models/notification_model.dart';
import 'package:uuid/uuid.dart';

class NotificationHelperService {
  NotificationHelperService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(FirestorePaths.notifications);

  // Patient Notifications

  /// Patient: Appointment Confirmed
  /// 🔔 Your appointment has been confirmed.
  Future<void> sendAppointmentConfirmed({
    required String patientId,
    required String doctorName,
    required DateTime appointmentDate,
  }) async {
    final formattedDate = DateFormat('dd MMM yyyy').format(appointmentDate);
    await _createNotification(
      recipientId: patientId,
      recipientType: NotificationRecipient.patient,
      type: NotificationType.appointmentConfirmed,
      title: 'Appointment Confirmed',
      body: '🔔 Your appointment with $doctorName on $formattedDate has been confirmed.',
      data: {
        'doctorName': doctorName,
        'appointmentDate': appointmentDate.toIso8601String(),
      },
    );
  }

  /// Patient: Appointment Declined
  /// 🔔 Your appointment has been declined.
  Future<void> sendAppointmentDeclined({
    required String patientId,
    required String doctorName,
    required DateTime appointmentDate,
  }) async {
    final formattedDate = DateFormat('dd MMM yyyy').format(appointmentDate);
    await _createNotification(
      recipientId: patientId,
      recipientType: NotificationRecipient.patient,
      type: NotificationType.appointmentDeclined,
      title: 'Appointment Declined',
      body: '🔔 Your appointment with $doctorName on $formattedDate has been declined.',
      data: {
        'doctorName': doctorName,
        'appointmentDate': appointmentDate.toIso8601String(),
      },
    );
  }

  /// Patient: New Note Added
  /// 🔔 Caregiver added new recommendations.
  Future<void> sendNewNoteAdded({
    required String patientId,
    required String caregiverName,
    String? notePreview,
  }) async {
    await _createNotification(
      recipientId: patientId,
      recipientType: NotificationRecipient.patient,
      type: NotificationType.newNoteAdded,
      title: 'New Note Added',
      body: '🔔 Caregiver $caregiverName added new recommendations.${notePreview != null ? ' Note: $notePreview' : ''}',
      data: {
        'caregiverName': caregiverName,
        'notePreview': notePreview,
      },
    );
  }

  /// Patient: Follow-up Scheduled
  /// 🔔 Follow-up scheduled for 25 Aug 2026.
  Future<void> sendFollowUpScheduled({
    required String patientId,
    required DateTime followUpDate,
    String? doctorName,
  }) async {
    final formattedDate = DateFormat('dd MMM yyyy').format(followUpDate);
    await _createNotification(
      recipientId: patientId,
      recipientType: NotificationRecipient.patient,
      type: NotificationType.followUpScheduled,
      title: 'Follow-up Scheduled',
      body: '🔔 Follow-up scheduled for $formattedDate.${doctorName != null ? ' Doctor: $doctorName' : ''}',
      data: {
        'followUpDate': followUpDate.toIso8601String(),
        'doctorName': doctorName,
      },
    );
  }

  /// Patient: Appointment Completed
  /// 🔔 Your appointment has been completed.
  Future<void> sendAppointmentCompleted({
    required String patientId,
    required String doctorName,
    required DateTime appointmentDate,
  }) async {
    final formattedDate = DateFormat('dd MMM yyyy').format(appointmentDate);
    await _createNotification(
      recipientId: patientId,
      recipientType: NotificationRecipient.patient,
      type: NotificationType.appointmentCompleted,
      title: 'Appointment Completed',
      body: '🔔 Your appointment with $doctorName on $formattedDate has been completed.',
      data: {
        'doctorName': doctorName,
        'appointmentDate': appointmentDate.toIso8601String(),
      },
    );
  }

  /// Patient: Medicine Reminder
  /// 🔔 Time to take your medicine.
  Future<void> sendMedicineReminder({
    required String patientId,
    required String medicineName,
    required String dosage,
    required String scheduledTime,
  }) async {
    await _createNotification(
      recipientId: patientId,
      recipientType: NotificationRecipient.patient,
      type: NotificationType.medicineReminder,
      title: 'Medicine Reminder',
      body: '🔔 Time to take your $medicineName ($dosage) at $scheduledTime.',
      data: {
        'medicineName': medicineName,
        'dosage': dosage,
        'scheduledTime': scheduledTime,
      },
    );
  }

  // Caregiver Notifications

  /// Caregiver: New Hire Request
  /// 🔔 New hire request from patient.
  Future<void> sendNewHireRequest({
    required String caregiverId,
    required String patientName,
    String? message,
  }) async {
    await _createNotification(
      recipientId: caregiverId,
      recipientType: NotificationRecipient.caregiver,
      type: NotificationType.newHireRequest,
      title: 'New Hire Request',
      body: '🔔 New hire request from $patientName.${message != null ? ' Message: $message' : ''}',
      data: {
        'patientName': patientName,
        'message': message,
      },
    );
  }

  /// Caregiver: New Appointment Request
  /// 🔔 New Appointment Request from Ahmed
  Future<void> sendNewAppointmentRequest({
    required String caregiverId,
    required String patientName,
    required DateTime appointmentDate,
    required String problem,
  }) async {
    final formattedDate = DateFormat('dd MMM yyyy').format(appointmentDate);
    await _createNotification(
      recipientId: caregiverId,
      recipientType: NotificationRecipient.caregiver,
      type: NotificationType.newAppointmentRequest,
      title: 'New Appointment Request',
      body: '🔔 New Appointment Request from $patientName for $formattedDate. Problem: $problem',
      data: {
        'patientName': patientName,
        'appointmentDate': appointmentDate.toIso8601String(),
        'problem': problem,
      },
    );
  }

  /// Caregiver: Patient Missed Medicine
  /// 🔔 Patient missed their medicine.
  Future<void> sendPatientMissedMedicine({
    required String caregiverId,
    required String patientName,
    required String medicineName,
    required String scheduledTime,
  }) async {
    await _createNotification(
      recipientId: caregiverId,
      recipientType: NotificationRecipient.caregiver,
      type: NotificationType.patientMissedMedicine,
      title: 'Patient Missed Medicine',
      body: '🔔 $patientName missed their $medicineName scheduled for $scheduledTime.',
      data: {
        'patientName': patientName,
        'medicineName': medicineName,
        'scheduledTime': scheduledTime,
      },
    );
  }

  /// Caregiver: New Vital Added
  /// 🔔 New vital reading added.
  Future<void> sendNewVitalAdded({
    required String caregiverId,
    required String patientName,
    required String vitalType,
    required String value,
    required String unit,
  }) async {
    await _createNotification(
      recipientId: caregiverId,
      recipientType: NotificationRecipient.caregiver,
      type: NotificationType.newVitalAdded,
      title: 'New Vital Added',
      body: '🔔 New $vitalType reading for $patientName: $value $unit.',
      data: {
        'patientName': patientName,
        'vitalType': vitalType,
        'value': value,
        'unit': unit,
      },
    );
  }

  /// Caregiver: Emergency SOS Triggered
  /// 🔔 Emergency SOS triggered by patient.
  Future<void> sendEmergencySOSTriggered({
    required String caregiverId,
    required String patientName,
    required DateTime timestamp,
    String? location,
  }) async {
    final formattedTime = DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
    await _createNotification(
      recipientId: caregiverId,
      recipientType: NotificationRecipient.caregiver,
      type: NotificationType.emergencySOSTriggered,
      title: 'Emergency SOS Triggered',
      body: '🔔 Emergency SOS triggered by $patientName at $formattedTime.${location != null ? ' Location: $location' : ''}',
      data: {
        'patientName': patientName,
        'timestamp': timestamp.toIso8601String(),
        'location': location,
      },
    );
  }

  // Helper Methods

  Future<void> _createNotification({
    required String recipientId,
    required NotificationRecipient recipientType,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final id = _uuid.v4();
    final notification = NotificationModel(
      id: id,
      recipientId: recipientId,
      recipientType: recipientType,
      type: type,
      title: title,
      body: body,
      data: data,
      createdAt: DateTime.now(),
    );

    await _notifications.doc(id).set(notification.toFirestore());

    // Send push notification if recipient has FCM token
    await _sendPushNotification(
      recipientId: recipientId,
      title: title,
      body: body,
      data: data,
    );
  }

  Future<void> _sendPushNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get recipient's FCM token
      final userDoc = await _firestore
          .collection(FirestorePaths.users)
          .doc(recipientId)
          .get();

      if (!userDoc.exists) return;

      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null) return;

      // Queue the push notification for server-side delivery via Cloud Functions.
      // FirebaseMessaging client SDK cannot send messages directly (FCM v1 requires
      // server-side auth). A Cloud Function listening to this collection will
      // deliver the push notification using the Admin SDK.
      await _firestore.collection('fcm_queue').add({
        'to': fcmToken,
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': DateTime.now().toIso8601String(),
        'sent': false,
      });
    } catch (e) {
      // Silent fail - push notification is optional
      // ignore: avoid_print
      debugPrint('Failed to queue push notification: $e');
    }
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _notifications
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final unreadNotifications = await _notifications
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadNotifications.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  Future<int> getUnreadCount(String userId) async {
    final snapshot = await _notifications
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }
}
