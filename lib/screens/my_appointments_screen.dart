import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/providers/health_provider.dart';
import 'package:thirdly/screens/appointment_detail_screen.dart';
import 'package:thirdly/utils/app_colors.dart';
import 'package:intl/intl.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<HealthDataProvider>().appointments;
    return Scaffold(
      appBar: AppBar(
        title: Text('My Appointments', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: appointments.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'You have no upcoming appointments. Book a new appointment from the doctors screen.',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: appointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final appt = appointments[index];
                final isConfirmed = appt.status == 'confirmed';
                final color = appt.status == 'pending'
                    ? AppColors.warning
                    : appt.status == 'confirmed'
                        ? AppColors.success
                        : appt.status == 'cancelled'
                            ? AppColors.error
                            : AppColors.secondary;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentDetailScreen(appointment: appt),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appt.doctorName,
                                    style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    appt.doctorSpecialty,
                                    style: GoogleFonts.poppins(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                appt.status.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          DateFormat('EEEE, MMM d • h:mm a').format(appt.dateTime),
                          style: GoogleFonts.poppins(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          appt.problem,
                          style: GoogleFonts.poppins(height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              appt.patientName,
                              style: GoogleFonts.poppins(color: AppColors.textSecondary),
                            ),
                            Text(
                              isConfirmed ? 'Confirmed' : appt.status.capitalize(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
