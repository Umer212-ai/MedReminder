import 'package:cloud_firestore/cloud_firestore.dart';

enum VitalType { bloodPressure, heartRate, bloodSugar, weight, temperature }

VitalType vitalTypeFromString(String? v) {
  switch (v) {
    case 'heart_rate':
      return VitalType.heartRate;
    case 'blood_sugar':
      return VitalType.bloodSugar;
    case 'weight':
      return VitalType.weight;
    case 'temperature':
      return VitalType.temperature;
    default:
      return VitalType.bloodPressure;
  }
}

String vitalTypeToString(VitalType type) {
  switch (type) {
    case VitalType.heartRate:
      return 'heart_rate';
    case VitalType.bloodSugar:
      return 'blood_sugar';
    case VitalType.bloodPressure:
      return 'blood_pressure';
    case VitalType.weight:
      return 'weight';
    case VitalType.temperature:
      return 'temperature';
  }
}

class VitalModel {
  final String id;
  final String userId;
  final VitalType type;
  final String value;
  final String unit;
  final String status;
  final DateTime createdAt;

  const VitalModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.unit,
    required this.status,
    required this.createdAt,
  });

  factory VitalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return VitalModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      type: vitalTypeFromString(d['type'] as String?),
      value: d['value'] as String? ?? '',
      unit: d['unit'] as String? ?? '',
      status: d['status'] as String? ?? 'Recorded',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'type': vitalTypeToString(type),
        'value': value,
        'unit': unit,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  String get title {
    switch (type) {
      case VitalType.heartRate:
        return 'Heart Rate';
      case VitalType.bloodSugar:
        return 'Blood Sugar';
      case VitalType.bloodPressure:
        return 'Blood Pressure';
      case VitalType.weight:
        return 'Weight';
      case VitalType.temperature:
        return 'Temperature';
    }
  }
}
