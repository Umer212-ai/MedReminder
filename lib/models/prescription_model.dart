import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String imageUrl;
  final String? notes;
  final DateTime createdAt;

  const PrescriptionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.imageUrl,
    this.notes,
    required this.createdAt,
  });

  factory PrescriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return PrescriptionModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? 'general',
      imageUrl: data['imageUrl'] as String? ?? '',
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'title': title,
        'category': category,
        'imageUrl': imageUrl,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
