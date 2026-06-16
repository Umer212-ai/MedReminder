import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:thirdly/core/constants/firestore_paths.dart';
import 'package:thirdly/models/hire_request_model.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/services/notification_helper_service.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
    NotificationHelperService? notificationHelper,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _notificationHelper = notificationHelper ?? NotificationHelperService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final NotificationHelperService _notificationHelper;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _hireRequests =>
      _firestore.collection(FirestorePaths.hireRequests);

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection(FirestorePaths.users).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required int age,
    required String phoneNumber,
    required String emergencyContact,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(fullName);
    await user.sendEmailVerification();

    final profile = UserModel(
      uid: user.uid,
      email: email.trim(),
      fullName: fullName,
      age: age,
      phoneNumber: phoneNumber,
      emergencyContact: emergencyContact,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .set(profile.toFirestore());

    return profile;
  }

  Future<UserModel> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    var profile = await getUserProfile(uid);
    if (profile == null) {
      profile = UserModel(
        uid: uid,
        email: email.trim(),
        fullName: credential.user!.displayName ?? 'User',
        age: 0,
        phoneNumber: '',
        emergencyContact: '',
        role: UserRole.patient,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore.collection(FirestorePaths.users).doc(uid).set(profile.toFirestore());
    }
    return profile;
  }

  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'sign-in-cancelled', message: 'Google sign-in cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    var profile = await getUserProfile(user.uid);

    if (profile == null) {
      profile = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        fullName: user.displayName ?? 'User',
        age: 0,
        phoneNumber: user.phoneNumber ?? '',
        emergencyContact: '',
        role: UserRole.patient,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestore.collection(FirestorePaths.users).doc(user.uid).set(profile.toFirestore());
    }

    return profile;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateProfile(UserModel profile) async {
    await _auth.currentUser?.updateDisplayName(profile.fullName);
    await _firestore
        .collection(FirestorePaths.users)
        .doc(profile.uid)
        .update(profile.copyWith().toFirestore());
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _firestore.collection(FirestorePaths.users).doc(uid).update({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<UserModel>> getCaregivers() async {
    final snap = await _firestore
        .collection(FirestorePaths.users)
        .where('role', isEqualTo: 'caregiver')
        .get();
    return snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  Stream<List<UserModel>> watchCaregivers() {
    return _firestore
        .collection(FirestorePaths.users)
        .where('role', isEqualTo: 'caregiver')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  Future<HireRequestModel> createHireRequest({
    required String patientId,
    required String patientName,
    required String patientEmail,
    required String caregiverId,
    required String caregiverName,
    required String caregiverEmail,
    String? message,
  }) async {
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
      createdAt: DateTime.now(),
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
        .snapshots()
        .map((snap) => snap.docs.map((doc) => HireRequestModel.fromFirestore(doc)).toList());
  }

  Stream<List<HireRequestModel>> watchPatientRequests(String patientId) {
    return _hireRequests
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => HireRequestModel.fromFirestore(doc)).toList());
  }

  Future<void> updateRequestStatus(String requestId, RequestStatus status) async {
    String statusString;
    switch (status) {
      case RequestStatus.pending:
        statusString = 'pending';
        break;
      case RequestStatus.accepted:
        statusString = 'accepted';
        break;
      case RequestStatus.rejected:
        statusString = 'rejected';
        break;
      case RequestStatus.cancelled:
        statusString = 'cancelled';
        break;
    }
    await _hireRequests.doc(requestId).update({
      'status': statusString,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore Google sign out errors (user might not have signed in with Google)
    }
    await _auth.signOut();
  }
}
