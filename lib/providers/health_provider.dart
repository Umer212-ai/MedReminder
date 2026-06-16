import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:thirdly/models/appointment_model.dart';
import 'package:thirdly/models/doctor_model.dart';
import 'package:thirdly/models/family_link_model.dart';
import 'package:thirdly/models/lab_report_model.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/models/vital_model.dart';
import 'package:thirdly/services/health_data_service.dart';

class HealthDataProvider extends ChangeNotifier {
  HealthDataProvider({HealthDataService? service})
      : _service = service ?? HealthDataService();

  final HealthDataService _service;

  List<VitalModel> _vitals = [];
  List<LabReportModel> _labReports = [];
  List<FamilyLinkModel> _myFamily = [];
  List<FamilyLinkModel> _watchedPatients = [];
  List<DoctorModel> _doctors = [];
  List<AppointmentModel> _appointments = [];

  StreamSubscription? _vitalsSub;
  StreamSubscription? _labsSub;
  StreamSubscription? _familySub;
  StreamSubscription? _watcherSub;
  StreamSubscription? _doctorsSub;
  StreamSubscription? _appointmentsSub;

  List<VitalModel> get vitals => _vitals;
  List<LabReportModel> get labReports => _labReports;
  List<FamilyLinkModel> get myFamily => _myFamily;
  List<FamilyLinkModel> get watchedPatients => _watchedPatients;
  List<DoctorModel> get doctors => _doctors;
  List<AppointmentModel> get appointments => _appointments;

  VitalModel? vitalOfType(VitalType type) => _service.latestVital(_vitals, type);

  void listenForPatient(String patientId) {
    _cancelAll();
    _vitalsSub = _service.watchVitals(patientId).listen((v) {
      _vitals = v;
      notifyListeners();
    });
    _labsSub = _service.watchLabReports(patientId).listen((v) {
      _labReports = v;
      notifyListeners();
    });
    _familySub = _service.watchFamilyByPatient(patientId).listen((v) {
      _myFamily = v;
      notifyListeners();
    });
    _doctorsSub = _service.watchDoctors(patientId).listen((v) {
      _doctors = v;
      notifyListeners();
    });
    _appointmentsSub = _service.watchAppointments(patientId).listen((v) {
      _appointments = v;
      notifyListeners();
    });
  }

  void listenForWatcher(String watcherId) {
    _cancelAll();
    _watcherSub = _service.watchFamilyForWatcher(watcherId).listen((v) {
      _watchedPatients = v;
      notifyListeners();
    });
  }

  Future<void> claimLinksIfNeeded(UserModel user) async {
    if (user.role == UserRole.familyMember || user.role == UserRole.caregiver) {
      await _service.claimFamilyLinks(user.uid, user.email);
      listenForWatcher(user.uid);
    }
  }

  Future<void> addVital({
    required String userId,
    required VitalType type,
    required String value,
    required String unit,
    String status = 'Recorded',
  }) =>
      _service.addVital(userId: userId, type: type, value: value, unit: unit, status: status);

  Future<void> addLabReport({
    required String userId,
    required String testName,
    required String status,
  }) =>
      _service.addLabReport(userId: userId, testName: testName, status: status);

  Future<void> addFamilyMember({
    required String patientId,
    required String patientName,
    required String memberName,
    required String relation,
    required int memberAge,
    required String watcherEmail,
    String? watcherId,
  }) =>
      _service.addFamilyLink(
        patientId: patientId,
        patientName: patientName,
        memberName: memberName,
        relation: relation,
        memberAge: memberAge,
        watcherEmail: watcherEmail,
        watcherId: watcherId,
      );

  Future<void> addDoctor({
    required String userId,
    required String name,
    required String specialty,
    required String phone,
    required String clinic,
  }) =>
      _service.addDoctor(
        userId: userId,
        name: name,
        specialty: specialty,
        phone: phone,
        clinic: clinic,
      );

  Future<void> bookAppointment(AppointmentModel appointment) =>
      _service.addAppointment(appointment);

  void _cancelAll() {
    _vitalsSub?.cancel();
    _labsSub?.cancel();
    _familySub?.cancel();
    _watcherSub?.cancel();
    _doctorsSub?.cancel();
    _appointmentsSub?.cancel();
  }

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }
}
