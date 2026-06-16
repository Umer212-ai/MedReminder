import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContactModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String relation;
  final bool isPrimary;
  final DateTime createdAt;

  const EmergencyContactModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.relation,
    this.isPrimary = false,
    required this.createdAt,
  });

  factory EmergencyContactModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return EmergencyContactModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      relation: data['relation'] as String? ?? '',
      isPrimary: data['isPrimary'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'phone': phone,
        'relation': relation,
        'isPrimary': isPrimary,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
