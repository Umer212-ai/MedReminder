import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:thirdly/models/appointment_model.dart';
import 'package:thirdly/models/family_link_model.dart';
import 'package:thirdly/models/lab_report_model.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/models/vital_model.dart';
import 'package:thirdly/services/appointment_service.dart';
import 'package:thirdly/services/auth_service.dart';
import 'package:thirdly/services/health_data_service.dart';
import 'package:thirdly/services/medicine_service.dart';
import 'package:thirdly/models/medicine_model.dart';
import 'package:thirdly/utils/app_colors.dart';
import 'package:thirdly/screens/appointment_detail_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final FamilyLinkModel patientLink;

  const PatientDetailScreen({super.key, required this.patientLink});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final link = widget.patientLink;
    final hasDoses = link.todayTotal > 0;
    final progress = hasDoses ? (link.todayTaken / link.todayTotal) : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.darkMeshGradient
                      : AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar + name
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  link.patientName.isNotEmpty
                                      ? link.patientName[0].toUpperCase()
                                      : 'P',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    link.patientName,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${link.relation}  •  ${link.memberAge} years',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Adherence bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's Adherence",
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              hasDoses
                                  ? '${link.todayTaken}/${link.todayTotal} doses'
                                  : 'No schedule today',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: progress),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOut,
                            builder: (_, v, __) => LinearProgressIndicator(
                              value: v,
                              minHeight: 8,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.25),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              isScrollable: true,
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Medicines'),
                Tab(text: 'Vitals'),
                Tab(text: 'Lab Reports'),
                Tab(text: 'Appointments'),
                Tab(text: 'Emergency'),
              ],
            ),
          ),

          // ── Tab Content ───────────────────────────────────────────────
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PatientProfileTab(patientId: link.patientId, patientLink: link),
                _MedicinesTab(
                    patientId: link.patientId,
                    todayTaken: link.todayTaken,
                    todayTotal: link.todayTotal),
                _VitalsTab(patientId: link.patientId),
                _LabReportsTab(patientId: link.patientId),
                _AppointmentHistoryTab(patientId: link.patientId),
                _EmergencyContactTab(patientId: link.patientId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vitals Tab ────────────────────────────────────────────────────────────────

class _VitalsTab extends StatelessWidget {
  final String patientId;

  const _VitalsTab({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VitalModel>>(
      stream: HealthDataService().watchVitals(patientId),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final vitals = snapshot.data ?? [];
        if (vitals.isEmpty) {
          return _emptyState(
            context,
            icon: Icons.monitor_heart_outlined,
            message: 'No vitals recorded yet.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: vitals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) => _VitalTile(vital: vitals[i]),
        );
      },
    );
  }
}

class _VitalTile extends StatelessWidget {
  final VitalModel vital;
  const _VitalTile({required this.vital});

  Color get _color {
    switch (vital.type) {
      case VitalType.heartRate:
        return AppColors.primary;
      case VitalType.bloodPressure:
        return AppColors.success;
      case VitalType.bloodSugar:
        return AppColors.secondary;
      default:
        return AppColors.purple;
    }
  }

  IconData get _icon {
    switch (vital.type) {
      case VitalType.heartRate:
        return Icons.favorite_rounded;
      case VitalType.bloodPressure:
        return Icons.monitor_heart_rounded;
      case VitalType.bloodSugar:
        return Icons.opacity_rounded;
      default:
        return Icons.thermostat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vital.title,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                Text(
                  '${vital.value} ${vital.unit}',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM d, h:mm a').format(vital.createdAt),
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

// ── Medicines Tab ─────────────────────────────────────────────────────────────

class _MedicinesTab extends StatelessWidget {
  final String patientId;
  final int todayTaken;
  final int todayTotal;

  const _MedicinesTab(
      {required this.patientId, required this.todayTaken, required this.todayTotal});

  @override
  Widget build(BuildContext context) {
    if (todayTotal == 0) {
      return _emptyState(
        context,
        icon: Icons.medication_outlined,
        message: 'No medicines scheduled for today.',
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Summary",
            style:
                GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
              label: 'Total doses', value: '$todayTotal', color: AppColors.primary),
          _SummaryRow(
              label: 'Doses taken', value: '$todayTaken', color: AppColors.success),
          _SummaryRow(
            label: 'Doses remaining',
            value: '${todayTotal - todayTaken}',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppColors.textSecondary)),
          Text(
            value,
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Shared empty state ────────────────────────────────────────────────────────

Widget _emptyState(BuildContext context,
    {required IconData icon, required String message}) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: AppColors.textLight),
        const SizedBox(height: 16),
        Text(
          message,
          style: GoogleFonts.poppins(
              fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// ── Patient Profile Tab ───────────────────────────────────────────────────────

class _PatientProfileTab extends StatelessWidget {
  final String patientId;
  final FamilyLinkModel patientLink;

  const _PatientProfileTab({required this.patientId, required this.patientLink});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _emptyState(ctx, icon: Icons.person_outline, message: 'Patient profile not found.');
        }
        final user = UserModel.fromFirestore(snapshot.data!);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'P',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patientLink.relation,
                          style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _profileInfoCard(context, [
              _profileRow(context, Icons.email_outlined, 'Email', user.email, AppColors.primary),
              _profileRow(context, Icons.phone_outlined, 'Phone', user.phoneNumber.isNotEmpty ? user.phoneNumber : 'Not provided', AppColors.secondary),
              _profileRow(context, Icons.cake_outlined, 'Age', user.age > 0 ? '${user.age} years' : 'Unknown', AppColors.purple),
              if (user.gender != null && user.gender!.isNotEmpty)
                _profileRow(context, Icons.wc_outlined, 'Gender', user.gender!, AppColors.info),
            ]),
            const SizedBox(height: 16),
            if (user.medicalSummary != null && user.medicalSummary!.isNotEmpty) ...
              [
                _sectionLabel(context, 'Medical Summary'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    user.medicalSummary!,
                    style: GoogleFonts.poppins(fontSize: 14, height: 1.6),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            _sectionLabel(context, 'Emergency Contact'),
            const SizedBox(height: 8),
            _profileInfoCard(context, [
              _profileRow(context, Icons.emergency_outlined, 'Contact', user.emergencyContact.isNotEmpty ? user.emergencyContact : 'Not provided', AppColors.error),
            ]),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.4),
    );
  }

  Widget _profileInfoCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
      ),
      child: Column(children: children),
    );
  }

  Widget _profileRow(BuildContext context, IconData icon, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                Text(value,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lab Reports Tab ───────────────────────────────────────────────────────────

class _LabReportsTab extends StatelessWidget {
  final String patientId;

  const _LabReportsTab({required this.patientId});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return AppColors.success;
      case 'abnormal':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<LabReportModel>>(
      stream: HealthDataService().watchLabReports(patientId),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data ?? [];
        if (reports.isEmpty) {
          return _emptyState(ctx, icon: Icons.science_outlined, message: 'No lab reports found for this patient.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final report = reports[i];
            final color = _statusColor(report.status);
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.science_rounded, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.testName,
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(report.testDate),
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      report.status,
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Appointment History Tab ───────────────────────────────────────────────────

class _AppointmentHistoryTab extends StatelessWidget {
  final String patientId;

  const _AppointmentHistoryTab({required this.patientId});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<AppointmentModel>>(
      stream: HealthDataService().watchAppointments(patientId),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final appointments = snapshot.data ?? [];
        if (appointments.isEmpty) {
          return _emptyState(ctx, icon: Icons.calendar_month_outlined, message: 'No appointments found for this patient.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: appointments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final apt = appointments[i];
            final color = _statusColor(apt.status);
            return GestureDetector(
              onTap: () => Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => AppointmentDetailScreen(appointment: apt),
              )),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_statusIcon(apt.status), color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apt.doctorName,
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            apt.doctorSpecialty,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, yyyy • h:mm a').format(apt.dateTime),
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            apt.status.toUpperCase(),
                            style: GoogleFonts.poppins(
                                fontSize: 10, fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: AppColors.textLight),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Emergency Contact Tab ─────────────────────────────────────────────────────

class _EmergencyContactTab extends StatelessWidget {
  final String patientId;

  const _EmergencyContactTab({required this.patientId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _emptyState(ctx, icon: Icons.emergency_outlined, message: 'Patient data not found.');
        }
        final user = UserModel.fromFirestore(snapshot.data!);
        final hasContact = user.emergencyContact.isNotEmpty;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // SOS Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.error.withValues(alpha: 0.9), AppColors.error.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency Contact',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          hasContact ? 'Contact info available below' : 'No emergency contact set',
                          style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (hasContact) ...
              [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      _contactRow(Icons.person_outline, 'Name / Contact', user.emergencyContact, AppColors.error),
                      const Divider(height: 24),
                      _contactRow(Icons.phone_outlined, 'Patient Phone', user.phoneNumber.isNotEmpty ? user.phoneNumber : 'Not provided', AppColors.primary),
                    ],
                  ),
                ),
              ]
            else
              _emptyState(ctx, icon: Icons.person_off_outlined, message: 'This patient has not set an emergency contact.'),
          ],
        );
      },
    );
  }

  Widget _contactRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
