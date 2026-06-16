import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thirdly/core/constants/firestore_paths.dart';
import 'package:thirdly/models/medicine_model.dart';
import 'package:thirdly/models/reminder_log_model.dart';
import 'package:uuid/uuid.dart';

class MedicineService {
  MedicineService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _medicines =>
      _firestore.collection(FirestorePaths.medicines);

  CollectionReference<Map<String, dynamic>> get _reminders =>
      _firestore.collection(FirestorePaths.reminders);

  Stream<List<MedicineModel>> watchUserMedicines(String userId) {
    return _medicines
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map(MedicineModel.fromFirestore)
            .where((med) => med.isActive)
            .toList());
  }

  Future<MedicineModel> addMedicine({
    required String userId,
    required String name,
    required String dosage,
    String medicineType = 'tablet',
    int quantity = 1,
    List<String> scheduleTimes = const ['08:00'],
    DateTime? startDate,
    DateTime? endDate,
    String notes = '',
    String doctorName = '',
    String? imageUrl,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final medicine = MedicineModel(
      id: id,
      userId: userId,
      name: name,
      dosage: dosage,
      medicineType: medicineType,
      quantity: quantity,
      scheduleTimes: scheduleTimes,
      startDate: startDate ?? now,
      endDate: endDate,
      notes: notes,
      doctorName: doctorName,
      imageUrl: imageUrl,
      createdAt: now,
      updatedAt: now,
    );
    await _medicines.doc(id).set(medicine.toFirestore());
    return medicine;
  }

  Future<void> updateMedicine(MedicineModel medicine) async {
    await _medicines.doc(medicine.id).update(medicine.toFirestore());
  }

  Future<void> deleteMedicine(String medicineId) async {
    await _medicines.doc(medicineId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logDose({
    required String userId,
    required String medicineId,
    required String medicineName,
    required String scheduleTime,
    required ReminderStatus status,
    DateTime? scheduledAt,
  }) async {
    final id = _uuid.v4();
    final log = ReminderLogModel(
      id: id,
      userId: userId,
      medicineId: medicineId,
      medicineName: medicineName,
      scheduleTime: scheduleTime,
      scheduledAt: scheduledAt ?? DateTime.now(),
      status: status,
      completedAt: status == ReminderStatus.taken ? DateTime.now() : null,
    );
    await _reminders.doc(id).set(log.toFirestore());
  }

  Stream<List<ReminderLogModel>> watchTodayLogs(String userId) {
    final start = DateTime.now();
    final dayStart = DateTime(start.year, start.month, start.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return _reminders
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map(ReminderLogModel.fromFirestore)
            .where((log) => log.scheduledAt.isAfter(dayStart) && log.scheduledAt.isBefore(dayEnd))
            .toList());
  }

  Future<double> getWeeklyCompletionRate(String userId) async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final snap = await _reminders
        .where('userId', isEqualTo: userId)
        .get();

    if (snap.docs.isEmpty) return 0;
    final logs = snap.docs
        .map(ReminderLogModel.fromFirestore)
        .where((log) => log.scheduledAt.isAfter(weekAgo))
        .toList();
    
    if (logs.isEmpty) return 0;
    final taken = logs.where((l) => l.status == ReminderStatus.taken).length;
    return (taken / logs.length) * 100;
  }
}
