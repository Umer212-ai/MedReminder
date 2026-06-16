import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:thirdly/core/utils/dose_utils.dart';
import 'package:thirdly/models/vital_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/providers/health_provider.dart';
import 'package:thirdly/screens/medicines_screen.dart';
import 'package:thirdly/widgets/health_add_sheets.dart';
import '../utils/app_colors.dart';

class MedicalScreen extends StatelessWidget {
  const MedicalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medicineProvider = context.watch<MedicineProvider>();
    final health = context.watch<HealthDataProvider>();
    final slots = medicineProvider.todayDoseSlots;
    final isLoading = medicineProvider.isLoading;
    final error = medicineProvider.error;

    VitalModel? bp = health.vitalOfType(VitalType.bloodPressure);
    VitalModel? hr = health.vitalOfType(VitalType.heartRate);
    VitalModel? sugar = health.vitalOfType(VitalType.bloodSugar);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Medical Portfolio',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddMenu(context),
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Vital Statistics'),
            const SizedBox(height: 8),
            Text('Tap + to record vitals', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            _vitalCard(bp, 'Blood Pressure', 'mmHg', Icons.monitor_heart_rounded, AppColors.success),
            const SizedBox(height: 16),
            _vitalCard(hr, 'Heart Rate', 'bpm', Icons.favorite_rounded, AppColors.primary),
            const SizedBox(height: 16),
            _vitalCard(sugar, 'Blood Sugar', 'mg/dL', Icons.opacity_rounded, AppColors.secondary),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(context, 'All My Medicines'),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MedicinesScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: Text(
                    'Manage',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'View, edit, or delete your saved medicines',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (medicineProvider.medicines.isEmpty)
              Text(
                'No medicines saved yet.',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              )
            else
              ...medicineProvider.medicines.take(3).map((med) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    tileColor: theme.cardTheme.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: AppColors.textLight.withValues(alpha: 0.1)),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medication_rounded, color: AppColors.primary),
                    ),
                    title: Text(
                      med.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${med.dosage} • ${med.scheduleTimes.join(', ')}',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MedicinesScreen()),
                      );
                    },
                  ),
                );
              }),
            if (medicineProvider.medicines.length > 3)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MedicinesScreen()),
                    );
                  },
                  child: Text(
                    'View all ${medicineProvider.medicines.length} medicines',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            const SizedBox(height: 40),
            _buildSectionHeader(context, 'Today\'s Medicines'),
            const SizedBox(height: 16),
            if (error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Kharabi: $error',
                  style: GoogleFonts.poppins(color: Colors.red, fontSize: 13),
                ),
              )
            else if (isLoading && slots.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    color: theme.primaryColor,
                  ),
                ),
              )
            else if (slots.isEmpty)
              Text(
                'No doses scheduled for today. Add medicine with schedule times.',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              )
            else
              ...slots.asMap().entries.map((entry) {
                final slot = entry.value;
                final colors = [AppColors.purple, AppColors.orange, AppColors.primary, AppColors.secondary];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _MedicationCard(
                    slot: slot,
                    color: colors[entry.key % colors.length],
                    onTaken: () {
                      final uid = context.read<AppAuthProvider>().uid;
                      if (uid != null) {
                        context.read<MedicineProvider>().markTaken(
                              userId: uid,
                              medicine: slot.medicine,
                              scheduleTime: slot.scheduleTime,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${slot.medicine.name} (${slot.scheduleTime}) marked taken')),
                        );
                      }
                    },
                  ),
                );
              }),
            const SizedBox(height: 40),
            _buildSectionHeader(context, 'Lab Reports & Records'),
            const SizedBox(height: 16),
            if (health.labReports.isEmpty)
              Text('No lab reports. Tap + → Add lab report.', style: GoogleFonts.poppins(color: AppColors.textSecondary))
            else
              ...health.labReports.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _LabResultCard(
                      testName: r.testName,
                      date: DateFormat.yMMMd().format(r.testDate),
                      status: r.status,
                    ),
                  )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }

  Widget _vitalCard(VitalModel? vital, String title, String defaultUnit, IconData icon, Color color) {
    if (vital == null) {
      return _MedicalCard(
        title: title,
        value: '—',
        unit: defaultUnit,
        date: 'Not recorded yet',
        status: 'Add reading',
        color: color,
        icon: icon,
      );
    }
    return _MedicalCard(
      title: vital.title,
      value: vital.value,
      unit: vital.unit.isNotEmpty ? vital.unit : defaultUnit,
      date: DateFormat.MMMd().add_jm().format(vital.createdAt),
      status: vital.status,
      color: color,
      icon: icon,
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.favorite_rounded),
              title: const Text('Add vital reading'),
              onTap: () {
                Navigator.pop(ctx);
                HealthAddSheets.showAddVital(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.science_rounded),
              title: const Text('Add lab report'),
              onTap: () {
                Navigator.pop(ctx);
                HealthAddSheets.showAddLabReport(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String date;
  final String status;
  final Color color;
  final IconData icon;

  const _MedicalCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.date,
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        unit,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final TodayDoseSlot slot;
  final Color color;
  final VoidCallback onTaken;

  const _MedicationCard({
    required this.slot,
    required this.color,
    required this.onTaken,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final medicine = slot.medicine;
    final time = slot.scheduleTime;
    
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medication_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${medicine.dosage} • ${medicine.medicineType}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!slot.taken)
            IconButton(
              onPressed: onTaken,
              icon: const Icon(Icons.check_circle_outline_rounded),
              color: AppColors.success,
              tooltip: 'Mark as taken',
            )
          else
            const Icon(Icons.check_circle_rounded, color: AppColors.success),
        ],
      ),
    );
  }
}

class _LabResultCard extends StatelessWidget {
  final String testName;
  final String date;
  final String status;

  const _LabResultCard({
    required this.testName,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  testName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
