import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  // Patient notifications
  appointmentConfirmed,
  appointmentDeclined,
  newNoteAdded,
  followUpScheduled,
  appointmentCompleted,
  medicineReminder,
  
  // Caregiver notifications
  newHireRequest,
  newAppointmentRequest,
  patientMissedMedicine,
  newVitalAdded,
  emergencySOSTriggered,
}

enum NotificationRecipient {
  patient,
  caregiver,
}

class NotificationModel {
  final String id;
  final String recipientId;
  final NotificationRecipient recipientType;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientType,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      recipientId: d['recipientId'] as String? ?? '',
      recipientType: _recipientFromString(d['recipientType'] as String? ?? 'patient'),
      type: _typeFromString(d['type'] as String? ?? 'medicineReminder'),
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      data: d['data'] as Map<String, dynamic>?,
      isRead: d['isRead'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'recipientId': recipientId,
        'recipientType': _recipientToString(recipientType),
        'type': _typeToString(type),
        'title': title,
        'body': body,
        if (data != null) 'data': data,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    NotificationRecipient? recipientType,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      recipientType: recipientType ?? this.recipientType,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static NotificationType _typeFromString(String type) {
    switch (type) {
      case 'appointmentConfirmed':
        return NotificationType.appointmentConfirmed;
      case 'appointmentDeclined':
        return NotificationType.appointmentDeclined;
      case 'newNoteAdded':
        return NotificationType.newNoteAdded;
      case 'followUpScheduled':
        return NotificationType.followUpScheduled;
      case 'appointmentCompleted':
        return NotificationType.appointmentCompleted;
      case 'medicineReminder':
        return NotificationType.medicineReminder;
      case 'newHireRequest':
        return NotificationType.newHireRequest;
      case 'newAppointmentRequest':
        return NotificationType.newAppointmentRequest;
      case 'patientMissedMedicine':
        return NotificationType.patientMissedMedicine;
      case 'newVitalAdded':
        return NotificationType.newVitalAdded;
      case 'emergencySOSTriggered':
        return NotificationType.emergencySOSTriggered;
      default:
        return NotificationType.medicineReminder;
    }
  }

  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentConfirmed:
        return 'appointmentConfirmed';
      case NotificationType.appointmentDeclined:
        return 'appointmentDeclined';
      case NotificationType.newNoteAdded:
        return 'newNoteAdded';
      case NotificationType.followUpScheduled:
        return 'followUpScheduled';
      case NotificationType.appointmentCompleted:
        return 'appointmentCompleted';
      case NotificationType.medicineReminder:
        return 'medicineReminder';
      case NotificationType.newHireRequest:
        return 'newHireRequest';
      case NotificationType.newAppointmentRequest:
        return 'newAppointmentRequest';
      case NotificationType.patientMissedMedicine:
        return 'patientMissedMedicine';
      case NotificationType.newVitalAdded:
        return 'newVitalAdded';
      case NotificationType.emergencySOSTriggered:
        return 'emergencySOSTriggered';
    }
  }

  static NotificationRecipient _recipientFromString(String recipient) {
    switch (recipient) {
      case 'patient':
        return NotificationRecipient.patient;
      case 'caregiver':
        return NotificationRecipient.caregiver;
      default:
        return NotificationRecipient.patient;
    }
  }

  static String _recipientToString(NotificationRecipient recipient) {
    switch (recipient) {
      case NotificationRecipient.patient:
        return 'patient';
      case NotificationRecipient.caregiver:
        return 'caregiver';
    }
  }
}
