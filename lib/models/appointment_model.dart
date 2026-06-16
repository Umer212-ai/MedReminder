import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final DateTime dateTime;
  final String problem;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String? caregiverNotes;
  final String? recommendations;
  final DateTime? followUpDate;
  final DateTime? completedAt;
  final DateTime createdAt;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.dateTime,
    required this.problem,
    required this.status,
    this.caregiverNotes,
    this.recommendations,
    this.followUpDate,
    this.completedAt,
    required this.createdAt,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      patientId: d['patientId'] as String? ?? '',
      patientName: d['patientName'] as String? ?? '',
      doctorId: d['doctorId'] as String? ?? '',
      doctorName: d['doctorName'] as String? ?? '',
      doctorSpecialty: d['doctorSpecialty'] as String? ?? '',
      dateTime: (d['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      problem: d['problem'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
      caregiverNotes: d['caregiverNotes'] as String?,
      recommendations: d['recommendations'] as String?,
      followUpDate: (d['followUpDate'] as Timestamp?)?.toDate(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'doctorSpecialty': doctorSpecialty,
        'dateTime': Timestamp.fromDate(dateTime),
        'problem': problem,
        'status': status,
        if (caregiverNotes != null) 'caregiverNotes': caregiverNotes,
        if (recommendations != null) 'recommendations': recommendations,
        if (followUpDate != null) 'followUpDate': Timestamp.fromDate(followUpDate!),
        if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
