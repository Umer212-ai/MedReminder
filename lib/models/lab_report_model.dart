import 'package:cloud_firestore/cloud_firestore.dart';

class LabReportModel {
  final String id;
  final String userId;
  final String testName;
  final String status;
  final DateTime testDate;
  final DateTime createdAt;

  const LabReportModel({
    required this.id,
    required this.userId,
    required this.testName,
    required this.status,
    required this.testDate,
    required this.createdAt,
  });

  factory LabReportModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return LabReportModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      testName: d['testName'] as String? ?? '',
      status: d['status'] as String? ?? 'Pending',
      testDate: (d['testDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'testName': testName,
        'status': status,
        'testDate': Timestamp.fromDate(testDate),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
