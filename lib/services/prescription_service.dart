import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:thirdly/core/constants/firestore_paths.dart';
import 'package:thirdly/models/prescription_model.dart';
import 'package:uuid/uuid.dart';

class PrescriptionService {
  PrescriptionService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  Stream<List<PrescriptionModel>> watchPrescriptions(String userId) {
    return _firestore
        .collection(FirestorePaths.prescriptions)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PrescriptionModel.fromFirestore).toList());
  }

  Future<String> uploadPrescription({
    required String userId,
    required File imageFile,
    required String title,
    String category = 'general',
    String? notes,
  }) async {
    final id = _uuid.v4();
    final ref = _storage.ref().child('prescriptions/$userId/$id.jpg');
    await ref.putFile(imageFile);
    final imageUrl = await ref.getDownloadURL();

    final prescription = PrescriptionModel(
      id: id,
      userId: userId,
      title: title,
      category: category,
      imageUrl: imageUrl,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(FirestorePaths.prescriptions)
        .doc(id)
        .set(prescription.toFirestore());

    return id;
  }

  Future<void> deletePrescription(String id) async {
    await _firestore.collection(FirestorePaths.prescriptions).doc(id).delete();
  }
}
