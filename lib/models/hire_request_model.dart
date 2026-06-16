import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus {
  pending,
  accepted,
  rejected,
  cancelled,
}

class HireRequestModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientEmail;
  final String caregiverId;
  final String caregiverName;
  final String caregiverEmail;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? message;

  const HireRequestModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientEmail,
    required this.caregiverId,
    required this.caregiverName,
    required this.caregiverEmail,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.message,
  });

  factory HireRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return HireRequestModel(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      patientEmail: data['patientEmail'] as String? ?? '',
      caregiverId: data['caregiverId'] as String? ?? '',
      caregiverName: data['caregiverName'] as String? ?? '',
      caregiverEmail: data['caregiverEmail'] as String? ?? '',
      status: _statusFromString(data['status'] as String? ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      message: data['message'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'patientEmail': patientEmail,
        'caregiverId': caregiverId,
        'caregiverName': caregiverName,
        'caregiverEmail': caregiverEmail,
        'status': _statusToString(status),
        'createdAt': Timestamp.fromDate(createdAt),
        'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
        'message': message,
      };

  HireRequestModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientEmail,
    String? caregiverId,
    String? caregiverName,
    String? caregiverEmail,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? message,
  }) {
    return HireRequestModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientEmail: patientEmail ?? this.patientEmail,
      caregiverId: caregiverId ?? this.caregiverId,
      caregiverName: caregiverName ?? this.caregiverName,
      caregiverEmail: caregiverEmail ?? this.caregiverEmail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
    );
  }

  static RequestStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return RequestStatus.pending;
      case 'accepted':
        return RequestStatus.accepted;
      case 'rejected':
        return RequestStatus.rejected;
      case 'cancelled':
        return RequestStatus.cancelled;
      default:
        return RequestStatus.pending;
    }
  }

  static String _statusToString(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'pending';
      case RequestStatus.accepted:
        return 'accepted';
      case RequestStatus.rejected:
        return 'rejected';
      case RequestStatus.cancelled:
        return 'cancelled';
    }
  }
}
