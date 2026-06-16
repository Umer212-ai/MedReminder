import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyLinkModel {
  final String id;
  final String patientId;
  final String patientName;
  final String memberName;
  final String relation;
  final int memberAge;
  final String watcherEmail;
  final String? watcherId;
  final int todayTaken;
  final int todayTotal;
  final DateTime createdAt;

  const FamilyLinkModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.memberName,
    required this.relation,
    required this.memberAge,
    required this.watcherEmail,
    this.watcherId,
    this.todayTaken = 0,
    this.todayTotal = 0,
    required this.createdAt,
  });

  factory FamilyLinkModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return FamilyLinkModel(
      id: doc.id,
      patientId: d['patientId'] as String? ?? '',
      patientName: d['patientName'] as String? ?? 'Patient',
      memberName: d['memberName'] as String? ?? '',
      relation: d['relation'] as String? ?? '',
      memberAge: (d['memberAge'] as num?)?.toInt() ?? 0,
      watcherEmail: d['watcherEmail'] as String? ?? '',
      watcherId: d['watcherId'] as String?,
      todayTaken: (d['todayTaken'] as num?)?.toInt() ?? 0,
      todayTotal: (d['todayTotal'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'memberName': memberName,
        'relation': relation,
        'memberAge': memberAge,
        'watcherEmail': watcherEmail,
        'watcherId': watcherId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get isLinked => watcherId != null && watcherId!.isNotEmpty;
}
