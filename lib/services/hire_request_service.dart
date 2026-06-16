import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thirdly/core/constants/firestore_paths.dart';
import 'package:thirdly/models/hire_request_model.dart';
import 'package:thirdly/services/notification_helper_service.dart';
import 'package:uuid/uuid.dart';

class HireRequestService {
  HireRequestService({
    FirebaseFirestore? firestore,
    NotificationHelperService? notificationHelper,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationHelper = notificationHelper ?? NotificationHelperService();

  final FirebaseFirestore _firestore;
  final NotificationHelperService _notificationHelper;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _hireRequests =>
      _firestore.collection(FirestorePaths.hireRequests);

  CollectionReference<Map<String, dynamic>> get _familyLinks =>
      _firestore.collection(FirestorePaths.familyLinks);

  Future<HireRequestModel> sendHireRequest({
    required String patientId,
    required String patientName,
    required String patientEmail,
    required String caregiverId,
    required String caregiverName,
    required String caregiverEmail,
    String? message,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final request = HireRequestModel(
      id: id,
      patientId: patientId,
      patientName: patientName,
      patientEmail: patientEmail,
      caregiverId: caregiverId,
      caregiverName: caregiverName,
      caregiverEmail: caregiverEmail,
      status: RequestStatus.pending,
      createdAt: now,
      message: message,
    );
    await _hireRequests.doc(id).set(request.toFirestore());
    
    // Send notification to caregiver
    await _notificationHelper.sendNewHireRequest(
      caregiverId: caregiverId,
      patientName: patientName,
      message: message,
    );
    
    return request;
  }

  Stream<List<HireRequestModel>> watchCaregiverRequests(String caregiverId) {
    return _hireRequests
        .where('caregiverId', isEqualTo: caregiverId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(HireRequestModel.fromFirestore).toList());
  }

  Stream<List<HireRequestModel>> watchPatientRequests(String patientId) {
    return _hireRequests
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(HireRequestModel.fromFirestore).toList());
  }

  Future<void> acceptRequest(String requestId) async {
    final doc = await _hireRequests.doc(requestId).get();
    if (!doc.exists) return;
    
    final request = HireRequestModel.fromFirestore(doc);
    
    // Update request status
    await _hireRequests.doc(requestId).update({
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // Create family link
    await _familyLinks.add({
      'patientId': request.patientId,
      'patientName': request.patientName,
      'memberName': request.caregiverName,
      'relation': 'Caregiver',
      'memberAge': 0, // Will be updated from patient profile
      'watcherEmail': request.caregiverEmail,
      'watcherId': request.caregiverId,
      'todayTaken': 0,
      'todayTotal': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectRequest(String requestId) async {
    await _hireRequests.doc(requestId).update({
      'status': 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelRequest(String requestId) async {
    await _hireRequests.doc(requestId).update({
      'status': 'cancelled',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }
}
