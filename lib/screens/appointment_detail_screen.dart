import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/models/appointment_model.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/services/appointment_service.dart';
import 'package:thirdly/utils/app_colors.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late AppointmentModel _appointment;
  bool _saving = false;
  final AppointmentService _appointmentService = AppointmentService();

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
  }

  bool get _isCaregiver =>
      context.read<AppAuthProvider>().user?.role == UserRole.caregiver;

  Future<void> _updateAppointment(Map<String, dynamic> updates) async {
    setState(() => _saving = true);
    try {
      if (updates.containsKey('caregiverNotes')) {
        await _appointmentService.updateAppointmentNotes(
          appointmentId: _appointment.id,
          caregiverNotes: updates['caregiverNotes'] as String,
        );
      }
      if (updates.containsKey('followUpDate')) {
        await _appointmentService.scheduleFollowUp(
          appointmentId: _appointment.id,
          followUpDate: updates['followUpDate'] as DateTime,
        );
      }
      if (updates.containsKey('status')) {
        if (updates['status'] == 'completed') {
          await _appointmentService.completeAppointment(
            appointmentId: _appointment.id,
            caregiverNotes: _appointment.caregiverNotes,
            followUpDate: _appointment.followUpDate,
          );
        }
      }
      
      // Refresh appointment data
      final auth = context.read<AppAuthProvider>();
      if (auth.user?.role == UserRole.caregiver) {
        final appointments = await _appointmentService.watchDoctorAppointments(_appointment.doctorId).first;
        if (mounted) {
          final updated = appointments.firstWhere((a) => a.id == _appointment.id);
          setState(() => _appointment = updated);
        }
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Appointment updated',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save changes',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showAddNotes() async {
    final controller = TextEditingController(text: _appointment.caregiverNotes ?? '');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
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
                'Add Caregiver Notes',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Describe your recommendations or observations',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final notes = controller.text.trim();
                  Navigator.pop(ctx);
                  await _updateAppointment({'caregiverNotes': notes});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Save Notes', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scheduleFollowUp() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selectedDate == null) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (selectedTime == null) return;

    final followUpDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    await _updateAppointment({'followUpDate': followUpDate});
  }

  Future<void> _markCompleted() async {
    await _updateAppointment({'status': 'completed', 'completedAt': DateTime.now()});
  }

  Widget _infoTile(String title, String value, {IconData? icon, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (color ?? AppColors.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color ?? AppColors.primary, size: 22),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _appointment.status == 'confirmed'
        ? AppColors.success
        : _appointment.status == 'pending'
            ? AppColors.warning
            : _appointment.status == 'completed'
                ? AppColors.primary
                : AppColors.error;
    final dateText = DateFormat('EEEE, MMM d • h:mm a').format(_appointment.dateTime);
    final followUpText = _appointment.followUpDate != null
        ? DateFormat('EEEE, MMM d • h:mm a').format(_appointment.followUpDate!)
        : 'No follow-up scheduled';

    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: theme.iconTheme,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _appointment.doctorName,
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _appointment.doctorSpecialty,
                              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _appointment.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _infoTile('Patient', _appointment.patientName, icon: Icons.person, color: AppColors.secondary),
                  _infoTile('When', dateText, icon: Icons.calendar_month_rounded, color: AppColors.primary),
                  _infoTile('Reason', _appointment.problem, icon: Icons.info_outline, color: AppColors.purple),
                  _infoTile('Follow-up', followUpText, icon: Icons.repeat, color: AppColors.secondary),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_appointment.caregiverNotes != null && _appointment.caregiverNotes!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Caregiver Notes', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Text(
                      _appointment.caregiverNotes ?? '',
                      style: GoogleFonts.poppins(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            if (_appointment.caregiverNotes != null && _appointment.caregiverNotes!.isNotEmpty)
              const SizedBox(height: 24),
            if (_isCaregiver) ...[
              ElevatedButton(
                onPressed: _saving ? null : _showAddNotes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Add Notes / Recommendations', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saving ? null : _scheduleFollowUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Schedule Follow-up', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
            ],
            if (_isCaregiver && _appointment.status != 'completed')
              ElevatedButton(
                onPressed: _saving ? null : _markCompleted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Mark Appointment Completed', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            if (!_isCaregiver && _appointment.status == 'confirmed')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'This appointment is confirmed. You will receive a notification when the caregiver updates notes or marks it completed.',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, height: 1.5),
                ),
              ),
            if (!_isCaregiver && _appointment.status == 'cancelled')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'This appointment was declined or cancelled. Please book another appointment if needed.',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, height: 1.5),
                ),
              ),
            if (_saving) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
