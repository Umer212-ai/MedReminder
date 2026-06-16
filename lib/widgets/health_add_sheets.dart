import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/models/appointment_model.dart';
import 'package:thirdly/models/doctor_model.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/models/vital_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/providers/health_provider.dart';
import 'package:thirdly/utils/app_colors.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class HealthAddSheets {
  static Future<void> showAddVital(
    BuildContext context, {
    VitalType initialType = VitalType.bloodPressure,
    String? overrideUserId,
  }) async {
    final uid = overrideUserId ?? context.read<AppAuthProvider>().uid;
    if (uid == null) return;

    VitalType type = initialType;
    final valueCtrl = TextEditingController();
    final unitCtrl = TextEditingController(
      text: initialType == VitalType.heartRate
          ? 'bpm'
          : initialType == VitalType.bloodSugar
              ? 'mg/dL'
              : initialType == VitalType.weight
                  ? 'kg'
                  : initialType == VitalType.temperature
                      ? '°C'
                      : 'mmHg',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Vital',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<VitalType>(
              value: type,
              items: const [
                DropdownMenuItem(
                  value: VitalType.bloodPressure,
                  child: Text('Blood Pressure'),
                ),
                DropdownMenuItem(
                  value: VitalType.heartRate,
                  child: Text('Heart Rate'),
                ),
                DropdownMenuItem(
                  value: VitalType.bloodSugar,
                  child: Text('Blood Sugar'),
                ),
                DropdownMenuItem(
                  value: VitalType.weight,
                  child: Text('Weight'),
                ),
                DropdownMenuItem(
                  value: VitalType.temperature,
                  child: Text('Temperature'),
                ),
              ],
              onChanged: (v) {
                type = v ?? VitalType.bloodPressure;
                if (type == VitalType.heartRate) {
                  unitCtrl.text = 'bpm';
                } else if (type == VitalType.bloodSugar) {
                  unitCtrl.text = 'mg/dL';
                } else if (type == VitalType.weight) {
                  unitCtrl.text = 'kg';
                } else if (type == VitalType.temperature) {
                  unitCtrl.text = '°C';
                } else {
                  unitCtrl.text = 'mmHg';
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              decoration: const InputDecoration(
                labelText: 'Value (e.g. 120/80 or 72)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitCtrl,
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (valueCtrl.text.trim().isEmpty) return;
                await context.read<HealthDataProvider>().addVital(
                  userId: uid,
                  type: type,
                  value: valueCtrl.text.trim(),
                  unit: unitCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showAddLabReport(
    BuildContext context, {
    String? overrideUserId,
  }) async {
    final uid = overrideUserId ?? context.read<AppAuthProvider>().uid;
    if (uid == null) return;
    final nameCtrl = TextEditingController();
    final statusCtrl = TextEditingController(text: 'Complete');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Lab Report',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Test name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: statusCtrl,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await context.read<HealthDataProvider>().addLabReport(
                  userId: uid,
                  testName: nameCtrl.text.trim(),
                  status: statusCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showAddFamilyMember(BuildContext context) async {
    final uid = context.read<AppAuthProvider>().uid;
    if (uid == null) return;
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Family Member',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter their MedReminder signup email so they can see your health updates.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: relationCtrl,
              decoration: const InputDecoration(labelText: 'Relation'),
            ),
            TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Their email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
                final patientName =
                    context.read<AppAuthProvider>().user?.fullName ?? 'Patient';
                await context.read<HealthDataProvider>().addFamilyMember(
                  patientId: uid,
                  patientName: patientName,
                  memberName: nameCtrl.text.trim(),
                  relation: relationCtrl.text.trim(),
                  memberAge: int.tryParse(ageCtrl.text) ?? 0,
                  watcherEmail: emailCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showAddDoctor(BuildContext context) async {
    final uid = context.read<AppAuthProvider>().uid;
    if (uid == null) return;
    final nameCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final clinicCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Doctor',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Doctor name'),
            ),
            TextField(
              controller: specCtrl,
              decoration: const InputDecoration(labelText: 'Specialty'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: clinicCtrl,
              decoration: const InputDecoration(labelText: 'Clinic / Hospital'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                await context.read<HealthDataProvider>().addDoctor(
                  userId: uid,
                  name: nameCtrl.text.trim(),
                  specialty: specCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  clinic: clinicCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showBookAppointment(
    BuildContext context, {
    UserModel? caregiver,
    DoctorModel? doctor,
  }) async {
    final uid = context.read<AppAuthProvider>().uid;
    if (uid == null) return;

    final patientName = context.read<AppAuthProvider>().user?.fullName ?? 'Patient';

    final docId = caregiver?.uid ?? doctor?.id ?? '';
    final docName = caregiver?.fullName ?? doctor?.name ?? '';
    final docSpec = caregiver?.specialty ?? doctor?.specialty ?? 'Specialist';

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final problemCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Book Appointment',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scheduling appointment with $docName ($docSpec)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Date Picker
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2)),
                    ),
                    leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                    title: Text(
                      'Select Date',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight),
                    ),
                    subtitle: Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.arrow_drop_down_rounded, size: 28),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Time Picker
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2)),
                    ),
                    leading: const Icon(Icons.access_time_rounded, color: AppColors.primary),
                    title: Text(
                      'Select Time',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight),
                    ),
                    subtitle: Text(
                      selectedTime.format(context),
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.arrow_drop_down_rounded, size: 28),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Reason/Problem TextField
                  TextField(
                    controller: problemCtrl,
                    maxLines: 3,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Describe symptoms / problem',
                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Submit Button
                  ElevatedButton(
                    onPressed: () async {
                      final finalDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      final appt = AppointmentModel(
                        id: const Uuid().v4(),
                        patientId: uid,
                        patientName: patientName,
                        doctorId: docId,
                        doctorName: docName,
                        doctorSpecialty: docSpec,
                        dateTime: finalDateTime,
                        problem: problemCtrl.text.trim().isEmpty ? 'General Consultation' : problemCtrl.text.trim(),
                        status: 'pending',
                        createdAt: DateTime.now(),
                      );
                      await context.read<HealthDataProvider>().bookAppointment(appt);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Appointment booked with $docName',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Booking',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
