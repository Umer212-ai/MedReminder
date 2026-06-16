import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thirdly/core/constants/firestore_paths.dart';
import 'package:thirdly/models/emergency_contact_model.dart';
import 'package:thirdly/services/notification_helper_service.dart';
import 'package:uuid/uuid.dart';

class EmergencyService {
  EmergencyService({
    FirebaseFirestore? firestore,
    NotificationHelperService? notificationHelper,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationHelper = notificationHelper ?? NotificationHelperService();

  final FirebaseFirestore _firestore;
  final NotificationHelperService _notificationHelper;
  final _uuid = const Uuid();

  Stream<List<EmergencyContactModel>> watchContacts(String userId) {
    return _firestore
        .collection(FirestorePaths.emergencyContacts)
        .where('userId', isEqualTo: userId)
        .orderBy('isPrimary', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(EmergencyContactModel.fromFirestore).toList());
  }

  Future<String> addContact({
    required String userId,
    required String name,
    required String phone,
    required String relation,
    bool isPrimary = false,
  }) async {
    final id = _uuid.v4();
    final contact = EmergencyContactModel(
      id: id,
      userId: userId,
      name: name,
      phone: phone,
      relation: relation,
      isPrimary: isPrimary,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(FirestorePaths.emergencyContacts)
        .doc(id)
        .set(contact.toFirestore());
    return id;
  }

  Future<void> sendEmergencyAlert({
    required String userId,
    required String userName,
    String? location,
    List<String>? familyMemberIds,
  }) async {
    final alertId = _uuid.v4();
    await _firestore.collection(FirestorePaths.emergencyAlerts).doc(alertId).set({
      'userId': userId,
      'userName': userName,
      'location': location,
      'type': 'sos',
      'status': 'active',
      'notifiedUsers': familyMemberIds ?? [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send notifications using the notification helper
    if (familyMemberIds != null) {
      for (final memberId in familyMemberIds) {
        await _notificationHelper.sendEmergencySOSTriggered(
          caregiverId: memberId,
          patientName: userName,
          timestamp: DateTime.now(),
          location: location,
        );
      }
    }
  }
}
