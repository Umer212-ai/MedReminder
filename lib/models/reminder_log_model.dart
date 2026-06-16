import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderStatus { pending, taken, missed, snoozed }

class ReminderLogModel {
  final String id;
  final String userId;
  final String medicineId;
  final String medicineName;
  final String scheduleTime;
  final DateTime scheduledAt;
  final ReminderStatus status;
  final DateTime? completedAt;

  const ReminderLogModel({
    required this.id,
    required this.userId,
    required this.medicineId,
    required this.medicineName,
    this.scheduleTime = '',
    required this.scheduledAt,
    required this.status,
    this.completedAt,
  });

  factory ReminderLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ReminderLogModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      medicineId: data['medicineId'] as String? ?? '',
      medicineName: data['medicineName'] as String? ?? '',
      scheduleTime: data['scheduleTime'] as String? ?? '',
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _statusFromString(data['status'] as String?),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  static ReminderStatus _statusFromString(String? value) {
    switch (value) {
      case 'taken':
        return ReminderStatus.taken;
      case 'missed':
        return ReminderStatus.missed;
      case 'snoozed':
        return ReminderStatus.snoozed;
      default:
        return ReminderStatus.pending;
    }
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'medicineId': medicineId,
        'medicineName': medicineName,
        'scheduleTime': scheduleTime,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'status': status.name,
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };
}
