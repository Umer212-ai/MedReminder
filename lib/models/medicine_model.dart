import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineModel {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String medicineType;
  final int quantity;
  final List<String> scheduleTimes;
  final DateTime startDate;
  final DateTime? endDate;
  final String notes;
  final String doctorName;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicineModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.medicineType,
    required this.quantity,
    required this.scheduleTimes,
    required this.startDate,
    this.endDate,
    this.notes = '',
    this.doctorName = '',
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicineModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return MedicineModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      dosage: data['dosage'] as String? ?? '',
      medicineType: data['medicineType'] as String? ?? 'tablet',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      scheduleTimes: List<String>.from(data['scheduleTimes'] as List? ?? []),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'dosage': dosage,
        'medicineType': medicineType,
        'quantity': quantity,
        'scheduleTimes': scheduleTimes,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'notes': notes,
        'doctorName': doctorName,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  MedicineModel copyWith({
    String? name,
    String? dosage,
    String? medicineType,
    int? quantity,
    List<String>? scheduleTimes,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    String? notes,
    String? doctorName,
    String? imageUrl,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return MedicineModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      medicineType: medicineType ?? this.medicineType,
      quantity: quantity ?? this.quantity,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      notes: notes ?? this.notes,
      doctorName: doctorName ?? this.doctorName,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
