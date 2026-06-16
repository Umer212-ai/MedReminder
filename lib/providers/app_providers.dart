import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:thirdly/core/utils/firebase_errors.dart';
import 'package:thirdly/models/medicine_model.dart';
import 'package:thirdly/models/reminder_log_model.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/core/utils/dose_utils.dart';
import 'package:thirdly/services/auth_service.dart';
import 'package:thirdly/services/health_data_service.dart';
import 'package:thirdly/services/medicine_service.dart';
import 'package:thirdly/services/notification_service.dart';
import 'package:thirdly/services/reminder_scheduler_service.dart';

class AppAuthProvider extends ChangeNotifier {
  AppAuthProvider({
    AuthService? authService,
    NotificationService? notificationService,
  })  : _authService = authService ?? AuthService(),
        _notificationService = notificationService ?? NotificationService();

  final AuthService _authService;
  final NotificationService _notificationService;

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _authService.currentUser != null;
  String? get uid => _authService.currentUser?.uid;

  Future<void> _initNotificationsSafely() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  Future<void> init() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _user = await _authService.getUserProfile(firebaseUser.uid);
      await _initNotificationsSafely();
    }
    notifyListeners();
  }

  UserRole? get role => _user?.role;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.login(email, password);
      _error = null;
      notifyListeners();
      await _initNotificationsSafely();
      return true;
    } catch (e) {
      _error = firebaseErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required int age,
    required String phoneNumber,
    required String emergencyContact,
    required UserRole role,
  }) async {
    _setLoading(true);
    try {
      _user = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        age: age,
        phoneNumber: phoneNumber,
        emergencyContact: emergencyContact,
        role: role,
      );
      _error = null;
      notifyListeners();
      await _initNotificationsSafely();
      return true;
    } catch (e) {
      _error = firebaseErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      _user = await _authService.signInWithGoogle();
      _error = null;
      notifyListeners();
      await _initNotificationsSafely();
      return true;
    } catch (e) {
      _error = firebaseErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordReset(email);
      _error = null;
      return true;
    } catch (e) {
      _error = firebaseErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserProfile(UserModel profile) async {
    await _authService.updateProfile(profile);
    _user = profile;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

class MedicineProvider extends ChangeNotifier {
  MedicineProvider({
    MedicineService? medicineService,
    ReminderSchedulerService? scheduler,
    HealthDataService? healthDataService,
  })  : _medicineService = medicineService ?? MedicineService(),
        _scheduler = scheduler ?? ReminderSchedulerService(),
        _healthDataService = healthDataService ?? HealthDataService();

  final MedicineService _medicineService;
  final ReminderSchedulerService _scheduler;
  final HealthDataService _healthDataService;

  List<MedicineModel> _medicines = [];
  List<ReminderLogModel> _todayLogs = [];
  bool _loading = false;
  String? _error;
  double _completionRate = 0;
  StreamSubscription<List<MedicineModel>>? _medicineSubscription;
  StreamSubscription<List<ReminderLogModel>>? _todayLogsSub;
  String? _currentUserId;
  String _patientName = 'Patient';

  List<MedicineModel> get medicines => _medicines;
  List<ReminderLogModel> get todayLogs => _todayLogs;
  bool get isLoading => _loading;
  String? get error => _error;
  double get completionRate => _completionRate;

  List<TodayDoseSlot> get todayDoseSlots => buildTodayDoseSlots(
        medicines: _medicines,
        todayLogs: _todayLogs,
      );

  int get todayTotalDoses => todayDoseSlots.length;
  int get todayTakenDoses =>
      todayDoseSlots.where((s) => s.taken).length;
  int get todayRemainingDoses => todayTotalDoses - todayTakenDoses;
  int get todayMissedDoses =>
      todayDoseSlots.where((s) => s.missed && !s.taken).length;

  double get todayProgress =>
      todayTotalDoses == 0 ? 0 : (todayTakenDoses / todayTotalDoses) * 100;

  void setPatientName(String name) {
    _patientName = name.isEmpty ? 'Patient' : name;
  }

  void listenToMedicines(String userId) {
    // Only create a new listener if the userId has changed
    if (_currentUserId == userId && _medicineSubscription != null) {
      return;
    }

    // Cancel the old subscription if it exists
    _medicineSubscription?.cancel();
    _todayLogsSub?.cancel();
    _currentUserId = userId;

    _medicineSubscription = _medicineService.watchUserMedicines(userId).listen((list) async {
      _medicines = list;
      notifyListeners();
      await _scheduler.rescheduleAll(medicines: list, patientName: _patientName);
      await _loadCompletionRate(userId);
      await _syncFamilyStats(userId);
    });
    _todayLogsSub = _medicineService.watchTodayLogs(userId).listen((logs) {
      _todayLogs = logs;
      notifyListeners();
      _syncFamilyStats(userId);
    });
    _loadCompletionRate(userId);
  }

  void listenToPatientMedicines(String patientId) {
    if (_currentUserId == patientId && _medicineSubscription != null) return;
    _medicineSubscription?.cancel();
    _todayLogsSub?.cancel();
    _currentUserId = patientId;
    _medicineSubscription =
        _medicineService.watchUserMedicines(patientId).listen((list) {
      _medicines = list;
      notifyListeners();
    });
    _todayLogsSub = _medicineService.watchTodayLogs(patientId).listen((logs) {
      _todayLogs = logs;
      notifyListeners();
    });
  }

  Future<void> _syncFamilyStats(String patientId) async {
    await _healthDataService.syncTodayStatsForPatient(
      patientId: patientId,
      todayTaken: todayTakenDoses,
      todayTotal: todayTotalDoses,
    );
  }

  @override
  void dispose() {
    _medicineSubscription?.cancel();
    _todayLogsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCompletionRate(String userId) async {
    _completionRate = await _medicineService.getWeeklyCompletionRate(userId);
    notifyListeners();
  }

  Future<bool> addMedicine({
    required String userId,
    required String name,
    required String dosage,
    String medicineType = 'tablet',
    int quantity = 1,
    List<String>? scheduleTimes,
    DateTime? startDate,
    DateTime? endDate,
    String notes = '',
    String doctorName = '',
    String? imageUrl,
    required String patientName,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final medicine = await _medicineService.addMedicine(
        userId: userId,
        name: name,
        dosage: dosage,
        medicineType: medicineType,
        quantity: quantity,
        scheduleTimes: scheduleTimes ?? ['08:00'],
        startDate: startDate,
        endDate: endDate,
        notes: notes,
        doctorName: doctorName,
        imageUrl: imageUrl,
      );
      await _scheduler.scheduleMedicine(medicine: medicine, patientName: patientName);
      await _loadCompletionRate(userId);
      
      // Force refresh medicines list to ensure UI updates immediately
      final medicines = await _medicineService.watchUserMedicines(userId).first;
      _medicines = medicines;
      
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markTaken({
    required String userId,
    required MedicineModel medicine,
    required String scheduleTime,
  }) async {
    await _medicineService.logDose(
      userId: userId,
      medicineId: medicine.id,
      medicineName: medicine.name,
      scheduleTime: scheduleTime,
      status: ReminderStatus.taken,
    );
    await _loadCompletionRate(userId);
    await _syncFamilyStats(userId);
  }

  Future<bool> updateMedicine({
    required MedicineModel medicine,
    required String name,
    required String dosage,
    String medicineType = 'tablet',
    int quantity = 1,
    List<String>? scheduleTimes,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    String notes = '',
    String doctorName = '',
    String? imageUrl,
    required String patientName,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final updated = medicine.copyWith(
        name: name,
        dosage: dosage,
        medicineType: medicineType,
        quantity: quantity,
        scheduleTimes: scheduleTimes ?? medicine.scheduleTimes,
        startDate: startDate,
        endDate: endDate,
        clearEndDate: clearEndDate,
        notes: notes,
        doctorName: doctorName,
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );
      await _medicineService.updateMedicine(updated);
      await _scheduler.cancelMedicine(medicine);
      await _scheduler.scheduleMedicine(medicine: updated, patientName: patientName);
      await _loadCompletionRate(medicine.userId);
      await _syncFamilyStats(medicine.userId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMedicine({
    required MedicineModel medicine,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      await _scheduler.cancelMedicine(medicine);
      await _medicineService.deleteMedicine(medicine.id);
      await _loadCompletionRate(medicine.userId);
      await _syncFamilyStats(medicine.userId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
