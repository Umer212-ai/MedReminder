import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorModel {
  final String id;
  final String userId;
  final String name;
  final String specialty;
  final String phone;
  final String clinic;
  final DateTime createdAt;

  const DoctorModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.specialty,
    required this.phone,
    required this.clinic,
    required this.createdAt,
  });

  factory DoctorModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return DoctorModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      specialty: d['specialty'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      clinic: d['clinic'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'specialty': specialty,
        'phone': phone,
        'clinic': clinic,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
