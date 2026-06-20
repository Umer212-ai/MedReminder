import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:thirdly/core/constants/firestore_paths.dart';
import 'package:thirdly/core/utils/dose_utils.dart';
import 'package:thirdly/models/appointment_model.dart';
import 'package:thirdly/models/family_link_model.dart';
import 'package:thirdly/models/lab_report_model.dart';
import 'package:thirdly/models/medicine_model.dart';
import 'package:thirdly/models/notification_model.dart';
import 'package:thirdly/models/reminder_log_model.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/models/vital_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/providers/caregiver_dashboard_provider.dart';
import 'package:thirdly/providers/health_provider.dart';
import 'package:thirdly/screens/appointment_detail_screen.dart';
import 'package:thirdly/screens/login_screen.dart';
import 'package:thirdly/screens/patient_detail_screen.dart';
import 'package:thirdly/services/health_data_service.dart';
import 'package:thirdly/services/medicine_service.dart';
import 'package:thirdly/services/notification_helper_service.dart';
import 'package:thirdly/services/notification_service.dart';
import 'package:thirdly/utils/app_colors.dart';
import 'package:thirdly/main.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const BouncingScrollPhysics(),
        children: const [
          _FamilyHomeTab(),
          _FamilyPatientsTab(),
          _FamilySOSTab(),
          _FamilyNotificationsTab(),
          _FamilySettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            elevation: 0,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textLight,
            onTap: _onTabTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline_rounded),
                activeIcon: Icon(Icons.people_rounded),
                label: 'Patients',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sos_outlined),
                activeIcon: Icon(Icons.sos_rounded),
                label: 'SOS',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_none_rounded),
                activeIcon: Icon(Icons.notifications_active_rounded),
                label: 'Alerts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dropdown Selector for Patients ─────────────────────────────────────────────
class _PatientDropdown extends StatelessWidget {
  final List<FamilyLinkModel> patients;
  final FamilyLinkModel? selectedPatient;
  final ValueChanged<FamilyLinkModel?> onChanged;

  const _PatientDropdown({
    required this.patients,
    required this.selectedPatient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FamilyLinkModel>(
          value: selectedPatient,
          isExpanded: true,
          dropdownColor: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          hint: Text(
            'Select Patient',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
          items: patients.map((link) {
            return DropdownMenuItem<FamilyLinkModel>(
              value: link,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      link.patientName.isNotEmpty ? link.patientName[0].toUpperCase() : 'P',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${link.patientName} (${link.relation})',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Tab 0: Home / Overview ─────────────────────────────────────────────────────
class _FamilyHomeTab extends StatelessWidget {
  const _FamilyHomeTab();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;
    final provider = context.watch<CaregiverDashboardProvider>();
    final patients = provider.patients;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirestorePaths.emergencyAlerts)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, sosSnapshot) {
        final activeSOSList = sosSnapshot.data?.docs ?? [];
        // Filter alerts that belong to patients linked to this family member
        final linkedPatientIds = patients.map((p) => p.patientId).toSet();
        final activeSOS = activeSOSList.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return linkedPatientIds.contains(data?['userId']);
        }).toList();

        // Calculate total medicines active today across patients
        int totalMedicinesCount = 0;
        for (final p in patients) {
          final snap = provider.upcomingMedicines.where((m) => m.patientId == p.patientId);
          totalMedicinesCount += snap.length;
        }

        return StreamBuilder<List<AppointmentModel>>(
          stream: HealthDataService().watchAppointmentsForPatients(
            patients.map((p) => p.patientId).toList(),
          ),
          builder: (context, apptSnapshot) {
            final appointments = apptSnapshot.data ?? [];
            final upcomingAppointments = appointments
                .where((a) => a.status == 'confirmed' && a.dateTime.isAfter(DateTime.now()))
                .toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverAppBar(
                  expandedHeight: 280,
                  floating: false,
                  pinned: true,
                  backgroundColor: isDark ? AppColors.backgroundDark : AppColors.primary,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: isDark ? AppColors.darkMeshGradient : AppColors.primaryGradient,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -40,
                            top: 10,
                            child: Icon(
                              Icons.family_restroom_rounded,
                              size: 240,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 70, 24, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _greeting(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          user?.fullName ?? 'Family Member',
                                          style: GoogleFonts.poppins(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const CircleAvatar(
                                      radius: 26,
                                      backgroundColor: Colors.white24,
                                      child: Icon(Icons.family_restroom_rounded, color: Colors.white, size: 28),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Stats Cards in Glassmorphism
                                Row(
                                  children: [
                                    Expanded(
                                      child: _GlassStatCard(
                                        title: 'Patients',
                                        value: '${provider.patientsCount}',
                                        subtitle: 'Linked',
                                        icon: Icons.people_outline_rounded,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _GlassStatCard(
                                        title: 'Today Doses',
                                        value: '$totalMedicinesCount',
                                        subtitle: 'Scheduled',
                                        icon: Icons.medication_outlined,
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _GlassStatCard(
                                        title: 'Appointments',
                                        value: '${upcomingAppointments.length}',
                                        subtitle: 'Upcoming',
                                        icon: Icons.calendar_month_outlined,
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // SOS PULSING WARNING
                      if (activeSOS.isNotEmpty) ...[
                        _buildSOSWarningCard(context, activeSOS),
                        const SizedBox(height: 24),
                      ],

                      // Quick Actions Section
                      _sectionHeader('Quick Actions', Icons.bolt_rounded, AppColors.warning),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.25,
                        children: [
                          _QuickActionCard(
                            title: 'Medicines',
                            subtitle: 'Check schedules',
                            icon: Icons.medication_rounded,
                            color: AppColors.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FamilyMedicinesScreen()),
                            ),
                          ),
                          _QuickActionCard(
                            title: 'Vitals Log',
                            subtitle: 'Latest readings',
                            icon: Icons.monitor_heart_rounded,
                            color: AppColors.secondary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FamilyVitalsScreen()),
                            ),
                          ),
                          _QuickActionCard(
                            title: 'Lab Reports',
                            subtitle: 'Report history',
                            icon: Icons.science_rounded,
                            color: AppColors.purple,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FamilyLabReportsScreen()),
                            ),
                          ),
                          _QuickActionCard(
                            title: 'Appointments',
                            subtitle: 'Follow-ups & details',
                            icon: Icons.calendar_month_rounded,
                            color: AppColors.orange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FamilyAppointmentsScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Recent Activity Timeline
                      _sectionHeader('Recent Patient Activity', Icons.timeline_rounded, AppColors.primary),
                      const SizedBox(height: 12),
                      if (provider.recentActivities.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            'No activities logged today.',
                            style: GoogleFonts.poppins(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ...provider.recentActivities.take(5).map((activity) {
                          return _TimelineTile(activity: activity);
                        }),
                      const SizedBox(height: 32),

                      // Recent Notifications
                      _sectionHeader('Recent Notifications', Icons.notifications_none_rounded, AppColors.purple),
                      const SizedBox(height: 12),
                      StreamBuilder<List<NotificationModel>>(
                        stream: NotificationHelperService().getUserNotifications(user?.uid ?? ''),
                        builder: (context, notifSnap) {
                          final notifications = notifSnap.data ?? [];
                          if (notifications.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.cardTheme.color,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
                              ),
                              child: Text(
                                'No notifications yet.',
                                style: GoogleFonts.poppins(color: AppColors.textSecondary),
                              ),
                            );
                          }
                          return Column(
                            children: notifications.take(3).map((n) {
                              return _MiniNotificationTile(notification: n);
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSOSWarningCard(BuildContext context, List<QueryDocumentSnapshot> activeSOS) {
    final firstSOS = activeSOS.first.data() as Map<String, dynamic>;
    final patientName = firstSOS['userName'] ?? 'A linked patient';
    final location = firstSOS['location'] ?? 'Unknown location';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.error, width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMERGENCY ALERT',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  '$patientName triggered an SOS!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Location: $location',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Dial phone if available or open SOS page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please proceed to SOS screen for actions.')),
              );
            },
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.error, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _GlassStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: isDark ? 0.15 : 0.25),
                color.withValues(alpha: isDark ? 0.05 : 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.06),
                isDark ? color.withValues(alpha: 0.04) : color.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: isDark ? 0.25 : 0.1), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final ActivityFeedItem activity;

  const _TimelineTile({required this.activity});

  IconData _iconFor() {
    switch (activity.type) {
      case 'took_med':
        return Icons.check_circle_rounded;
      case 'missed_med':
        return Icons.error_rounded;
      case 'vital_recorded':
        return Icons.monitor_heart_rounded;
      case 'lab_added':
        return Icons.science_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _colorFor() {
    switch (activity.type) {
      case 'took_med':
        return AppColors.success;
      case 'missed_med':
        return AppColors.error;
      case 'vital_recorded':
        return AppColors.info;
      case 'lab_added':
        return AppColors.purple;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorFor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(), color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.message,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('h:mm a • EEE').format(activity.timestamp),
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniNotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _MiniNotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: notification.isRead ? Colors.transparent : AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  notification.body,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Linked Patients ─────────────────────────────────────────────────────
class _FamilyPatientsTab extends StatelessWidget {
  const _FamilyPatientsTab();

  void _openPatientDetail(BuildContext context, FamilyLinkModel link) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, animation, _) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => HealthDataProvider()..listenForPatient(link.patientId),
            ),
            ChangeNotifierProvider(
              create: (ctx) => MedicineProvider(
                scheduler: ctx.read<NotificationService>().scheduler,
              )..listenToPatientMedicines(link.patientId),
            ),
          ],
          child: PatientDetailScreen(patientLink: link),
        ),
        transitionsBuilder: (ctx, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CaregiverDashboardProvider>();
    final patients = provider.patients;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Linked Patients', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : patients.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  itemCount: patients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final link = patients[index];
                    final progress = link.todayTotal > 0 ? (link.todayTaken / link.todayTotal) : 0.0;
                    final status = provider.getPatientStatus(link.patientId);

                    Color statusColor = AppColors.success;
                    if (status == 'High Risk') {
                      statusColor = AppColors.error;
                    } else if (status == 'Attention Needed') {
                      statusColor = AppColors.warning;
                    }

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                      child: InkWell(
                        onTap: () => _openPatientDetail(context, link),
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      link.patientName.isNotEmpty
                                          ? link.patientName[0].toUpperCase()
                                          : 'P',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
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
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${link.relation} • Age ${link.memberAge}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      status,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Today Adherence',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${link.todayTaken}/${link.todayTotal} Doses',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: AppColors.textLight.withValues(alpha: 0.15),
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 72, color: AppColors.textLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No Linked Patients',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ask your patient family member to add you via family email linkage.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: SOS & Emergency ─────────────────────────────────────────────────────
class _FamilySOSTab extends StatelessWidget {
  const _FamilySOSTab();

  void _callNumber(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CaregiverDashboardProvider>();
    final patients = provider.patients;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Emergency Hub', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirestorePaths.emergencyAlerts)
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, snapshot) {
          final sosList = snapshot.data?.docs ?? [];
          final linkedPatientIds = patients.map((p) => p.patientId).toSet();

          // Filter active alerts for our linked patients
          final filteredSOS = sosList.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return linkedPatientIds.contains(data?['userId']);
          }).toList();

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              // Top Panic Banner
              if (filteredSOS.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.emergencyGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'ACTIVE SOS ALERTS',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...filteredSOS.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['userName'] ?? 'Patient';
                        final location = data['location'] ?? 'Unknown location';
                        final time = data['createdAt'] != null
                            ? DateFormat('h:mm a').format((data['createdAt'] as Timestamp).toDate())
                            : 'Just now';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    time,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Location: $location',
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              Text(
                'Linked Patients Contact Details',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (patients.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'No patient links available to show contacts.',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary),
                  ),
                )
              else
                ...patients.map((link) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(link.patientId).get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData || !userSnap.data!.exists) {
                        return const SizedBox.shrink();
                      }
                      final user = UserModel.fromFirestore(userSnap.data!);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                                    child: Icon(Icons.person_rounded, color: AppColors.error),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          link.patientName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Phone: ${user.phoneNumber.isNotEmpty ? user.phoneNumber : "N/A"}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (user.phoneNumber.isNotEmpty)
                                    IconButton(
                                      onPressed: () => _callNumber(user.phoneNumber),
                                      icon: const Icon(Icons.call_rounded, color: AppColors.success),
                                    ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                                    child: Icon(Icons.contact_phone_rounded, color: AppColors.warning),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Patient Emergency Contact',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          user.emergencyContact.isNotEmpty ? user.emergencyContact : "Not set",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (user.emergencyContact.isNotEmpty)
                                    IconButton(
                                      onPressed: () {
                                        // Match any phone number format in emergencyContact string
                                        final match = RegExp(r'\+?\d[\d -]{6,14}\d').firstMatch(user.emergencyContact);
                                        if (match != null) {
                                          _callNumber(match.group(0)!);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Cannot parse dialable number from contact details.')),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.call_rounded, color: AppColors.warning),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

// ── Tab 3: Notifications Screen ──────────────────────────────────────────────
class _FamilyNotificationsTab extends StatefulWidget {
  const _FamilyNotificationsTab();

  @override
  State<_FamilyNotificationsTab> createState() => _FamilyNotificationsTabState();
}

class _FamilyNotificationsTabState extends State<_FamilyNotificationsTab> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Appointments',
    'Medicines',
    'Caregiver Notes',
    'SOS Alerts'
  ];

  bool _matchesCategory(NotificationType type, String category) {
    if (category == 'All') return true;
    switch (category) {
      case 'Appointments':
        return type == NotificationType.appointmentConfirmed ||
            type == NotificationType.appointmentDeclined ||
            type == NotificationType.appointmentCompleted ||
            type == NotificationType.newAppointmentRequest;
      case 'Medicines':
        return type == NotificationType.medicineReminder ||
            type == NotificationType.patientMissedMedicine;
      case 'Caregiver Notes':
        return type == NotificationType.newNoteAdded ||
            type == NotificationType.followUpScheduled;
      case 'SOS Alerts':
        return type == NotificationType.emergencySOSTriggered;
      default:
        return false;
    }
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentConfirmed:
        return Icons.event_available_rounded;
      case NotificationType.appointmentDeclined:
        return Icons.event_busy_rounded;
      case NotificationType.appointmentCompleted:
        return Icons.check_circle_rounded;
      case NotificationType.newNoteAdded:
        return Icons.note_add_rounded;
      case NotificationType.followUpScheduled:
        return Icons.repeat_rounded;
      case NotificationType.medicineReminder:
        return Icons.medication_rounded;
      case NotificationType.newHireRequest:
        return Icons.person_add_rounded;
      case NotificationType.newAppointmentRequest:
        return Icons.event_rounded;
      case NotificationType.patientMissedMedicine:
        return Icons.medication_liquid_rounded;
      case NotificationType.newVitalAdded:
        return Icons.monitor_heart_rounded;
      case NotificationType.emergencySOSTriggered:
        return Icons.sos_rounded;
    }
  }

  Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentConfirmed:
        return AppColors.success;
      case NotificationType.appointmentDeclined:
        return AppColors.error;
      case NotificationType.appointmentCompleted:
        return AppColors.primary;
      case NotificationType.newNoteAdded:
        return AppColors.info;
      case NotificationType.followUpScheduled:
        return AppColors.secondary;
      case NotificationType.medicineReminder:
        return AppColors.primary;
      case NotificationType.newHireRequest:
        return AppColors.purple;
      case NotificationType.newAppointmentRequest:
        return AppColors.secondary;
      case NotificationType.patientMissedMedicine:
        return AppColors.warning;
      case NotificationType.newVitalAdded:
        return AppColors.info;
      case NotificationType.emergencySOSTriggered:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final uid = context.read<AppAuthProvider>().uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Notification Logs', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        actions: [
          if (uid != null)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Mark all as read',
              onPressed: () async {
                await NotificationHelperService().markAllAsRead(uid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All alerts marked read')),
                  );
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal category chips selector
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: theme.cardTheme.color,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: uid == null
                ? const SizedBox.shrink()
                : StreamBuilder<List<NotificationModel>>(
                    stream: NotificationHelperService().getUserNotifications(uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      final allNotifications = snapshot.data ?? [];
                      final notifications = allNotifications
                          .where((n) => _matchesCategory(n.type, _selectedCategory))
                          .toList();

                      if (notifications.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined,
                                  size: 64, color: AppColors.textLight.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'No alerts in this category',
                                style: GoogleFonts.poppins(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          final icon = _iconFor(notif.type);
                          final color = _colorFor(notif.type);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: notif.isRead
                                  ? theme.cardTheme.color
                                  : (isDark
                                      ? AppColors.primary.withValues(alpha: 0.08)
                                      : AppColors.primary.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: notif.isRead
                                    ? AppColors.textLight.withValues(alpha: 0.1)
                                    : AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              title: Text(
                                notif.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.body,
                                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(notif.createdAt),
                                    style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight),
                                  ),
                                ],
                              ),
                              trailing: !notif.isRead
                                  ? Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                if (!notif.isRead) {
                                  NotificationHelperService().markAsRead(notif.id);
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 4: Profile & Settings ──────────────────────────────────────────────────
class _FamilySettingsTab extends StatefulWidget {
  const _FamilySettingsTab();

  @override
  State<_FamilySettingsTab> createState() => _FamilySettingsTabState();
}

class _FamilySettingsTabState extends State<_FamilySettingsTab> {
  bool _notifAppointments = true;
  bool _notifMedicines = true;
  bool _notifSOS = true;

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Confirming will require you to log back in.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign out', style: GoogleFonts.poppins(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<AppAuthProvider>().logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profile & Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          // Profile Details Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.family_restroom_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Family Member',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        user?.email ?? 'email@domain.com',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text('Notification Preferences', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _notifAppointments,
                  onChanged: (val) => setState(() => _notifAppointments = val),
                  title: Text('Appointment Updates', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _notifMedicines,
                  onChanged: (val) => setState(() => _notifMedicines = val),
                  title: Text('Medicine Adherence Alerts', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _notifSOS,
                  onChanged: (val) => setState(() => _notifSOS = val),
                  title: Text('SOS Emergency Triggers', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text('App Customizations', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
            ),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, _) {
                return SwitchListTile(
                  value: mode == ThemeMode.dark,
                  onChanged: (val) {
                    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  },
                  title: Text('Dark Theme Mode', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  activeColor: AppColors.primary,
                  secondary: Icon(mode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                );
              },
            ),
          ),
          const SizedBox(height: 48),

          OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: Text(
              'Logout Profile',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SUB-SCREEN: FamilyMedicinesScreen ─────────────────────────────────────────
class FamilyMedicinesScreen extends StatefulWidget {
  const FamilyMedicinesScreen({super.key});

  @override
  State<FamilyMedicinesScreen> createState() => _FamilyMedicinesScreenState();
}

class _FamilyMedicinesScreenState extends State<FamilyMedicinesScreen> {
  FamilyLinkModel? _selectedPatient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patients = context.watch<CaregiverDashboardProvider>().patients;

    // Set default selected patient if not set
    if (_selectedPatient == null && patients.isNotEmpty) {
      _selectedPatient = patients.first;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Medicine Overview', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: patients.isEmpty
          ? _buildNoPatients(context)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _PatientDropdown(
                    patients: patients,
                    selectedPatient: _selectedPatient,
                    onChanged: (link) => setState(() => _selectedPatient = link),
                  ),
                ),
                if (_selectedPatient != null)
                  Expanded(
                    child: StreamBuilder<List<MedicineModel>>(
                      stream: MedicineService().watchUserMedicines(_selectedPatient!.patientId),
                      builder: (context, medSnapshot) {
                        final medicines = medSnapshot.data ?? [];
                        return StreamBuilder<List<ReminderLogModel>>(
                          stream: MedicineService().watchTodayLogs(_selectedPatient!.patientId),
                          builder: (context, logSnapshot) {
                            if (medSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final todayLogs = logSnapshot.data ?? [];
                            final todayDoses = buildTodayDoseSlots(medicines: medicines, todayLogs: todayLogs);

                            final takenDoses = todayDoses.where((d) => d.taken).toList();
                            final missedDoses = todayDoses.where((d) => d.missed && !d.taken).toList();
                            final pendingDoses = todayDoses.where((d) => !d.taken && !d.missed).toList();

                            return ListView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              children: [
                                // Taken Section
                                if (takenDoses.isNotEmpty) ...[
                                  _sectionHeader(context, 'Taken Today', AppColors.success),
                                  const SizedBox(height: 8),
                                  ...takenDoses.map((d) => _DoseTile(slot: d, color: AppColors.success)),
                                  const SizedBox(height: 20),
                                ],

                                // Missed Section
                                if (missedDoses.isNotEmpty) ...[
                                  _sectionHeader(context, 'Missed Doses', AppColors.error),
                                  const SizedBox(height: 8),
                                  ...missedDoses.map((d) => _DoseTile(slot: d, color: AppColors.error)),
                                  const SizedBox(height: 20),
                                ],

                                // Pending Section
                                _sectionHeader(context, 'Active / Upcoming Doses', AppColors.primary),
                                const SizedBox(height: 8),
                                if (pendingDoses.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.cardTheme.color,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'No pending doses for today.',
                                      style: GoogleFonts.poppins(color: AppColors.textSecondary),
                                    ),
                                  )
                                else
                                  ...pendingDoses.map((d) => _DoseTile(slot: d, color: AppColors.primary)),

                                const SizedBox(height: 24),
                                _sectionHeader(context, 'All Active Medicines', AppColors.purple),
                                const SizedBox(height: 8),
                                if (medicines.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.cardTheme.color,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text('No active medicines.', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                                  )
                                else
                                  ...medicines.map((m) {
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: ListTile(
                                        title: Text(m.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${m.dosage} • ${m.scheduleTimes.join(", ")}'),
                                        trailing: Icon(Icons.medication_rounded, color: AppColors.primary),
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 40),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildNoPatients(BuildContext context) {
    return Center(
      child: Text('No patients linked yet.', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
    );
  }
}

class _DoseTile extends StatelessWidget {
  final TodayDoseSlot slot;
  final Color color;

  const _DoseTile({required this.slot, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.medicine.name,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${slot.medicine.dosage} @ ${slot.scheduleTime}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(
            slot.taken
                ? Icons.check_circle_outline_rounded
                : slot.missed
                    ? Icons.error_outline_rounded
                    : Icons.schedule_rounded,
            color: color,
          ),
        ],
      ),
    );
  }
}

// ── SUB-SCREEN: FamilyVitalsScreen ───────────────────────────────────────────
class FamilyVitalsScreen extends StatefulWidget {
  const FamilyVitalsScreen({super.key});

  @override
  State<FamilyVitalsScreen> createState() => _FamilyVitalsScreenState();
}

class _FamilyVitalsScreenState extends State<FamilyVitalsScreen> {
  FamilyLinkModel? _selectedPatient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patients = context.watch<CaregiverDashboardProvider>().patients;

    if (_selectedPatient == null && patients.isNotEmpty) {
      _selectedPatient = patients.first;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Vitals Observation', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: patients.isEmpty
          ? const Center(child: Text('No patients linked yet.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _PatientDropdown(
                    patients: patients,
                    selectedPatient: _selectedPatient,
                    onChanged: (link) => setState(() => _selectedPatient = link),
                  ),
                ),
                if (_selectedPatient != null)
                  Expanded(
                    child: StreamBuilder<List<VitalModel>>(
                      stream: HealthDataService().watchVitals(_selectedPatient!.patientId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final vitals = snapshot.data ?? [];
                        final heartRate = vitals.where((v) => v.type == VitalType.heartRate).firstOrNull;
                        final bloodPressure = vitals.where((v) => v.type == VitalType.bloodPressure).firstOrNull;
                        final bloodSugar = vitals.where((v) => v.type == VitalType.bloodSugar).firstOrNull;

                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            // Latest Readings Row
                            Row(
                              children: [
                                Expanded(
                                  child: _VitalReadingCard(
                                    title: 'Heart Rate',
                                    value: heartRate?.value ?? '--',
                                    unit: 'bpm',
                                    icon: Icons.favorite_rounded,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _VitalReadingCard(
                                    title: 'Blood Pressure',
                                    value: bloodPressure?.value ?? '--',
                                    unit: 'mmHg',
                                    icon: Icons.monitor_heart_rounded,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _VitalReadingCard(
                              title: 'Blood Sugar',
                              value: bloodSugar?.value ?? '--',
                              unit: 'mg/dL',
                              icon: Icons.opacity_rounded,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(height: 24),

                            Text('All Readings History', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),

                            if (vitals.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: theme.cardTheme.color,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text('No vitals records available.', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                              )
                            else
                              ...vitals.map((v) => _VitalHistoryTile(vital: v)),
                            const SizedBox(height: 40),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

class _VitalReadingCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _VitalReadingCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VitalHistoryTile extends StatelessWidget {
  final VitalModel vital;

  const _VitalHistoryTile({required this.vital});

  Color get _color {
    switch (vital.type) {
      case VitalType.heartRate:
        return AppColors.error;
      case VitalType.bloodPressure:
        return AppColors.success;
      case VitalType.bloodSugar:
        return AppColors.secondary;
      default:
        return AppColors.primary;
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
    final color = _color;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vital.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(
                  DateFormat('h:mm a • d MMM').format(vital.createdAt),
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${vital.value} ${vital.unit}',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ── SUB-SCREEN: FamilyLabReportsScreen ────────────────────────────────────────
class FamilyLabReportsScreen extends StatefulWidget {
  const FamilyLabReportsScreen({super.key});

  @override
  State<FamilyLabReportsScreen> createState() => _FamilyLabReportsScreenState();
}

class _FamilyLabReportsScreenState extends State<FamilyLabReportsScreen> {
  FamilyLinkModel? _selectedPatient;

  void _showReportDetails(BuildContext context, LabReportModel report) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final color = report.status.toLowerCase() == 'abnormal' ? AppColors.error : AppColors.success;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lab Report Summary', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text(report.testName, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Test Date', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                  Text(DateFormat('dd MMMM yyyy').format(report.testDate), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status Indicator', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      report.status.toUpperCase(),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: color, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Close Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patients = context.watch<CaregiverDashboardProvider>().patients;

    if (_selectedPatient == null && patients.isNotEmpty) {
      _selectedPatient = patients.first;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Lab Records', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: patients.isEmpty
          ? const Center(child: Text('No patients linked yet.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _PatientDropdown(
                    patients: patients,
                    selectedPatient: _selectedPatient,
                    onChanged: (link) => setState(() => _selectedPatient = link),
                  ),
                ),
                if (_selectedPatient != null)
                  Expanded(
                    child: StreamBuilder<List<LabReportModel>>(
                      stream: HealthDataService().watchLabReports(_selectedPatient!.patientId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final reports = snapshot.data ?? [];

                        if (reports.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.science_outlined, size: 64, color: AppColors.textLight),
                                const SizedBox(height: 12),
                                Text('No lab reports uploaded.', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          itemCount: reports.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final report = reports[index];
                            final color = report.status.toLowerCase() == 'abnormal' ? AppColors.error : AppColors.success;

                            return Container(
                              decoration: BoxDecoration(
                                color: theme.cardTheme.color,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
                              ),
                              child: ListTile(
                                onTap: () => _showReportDetails(context, report),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.science_rounded, color: color, size: 20),
                                ),
                                title: Text(
                                  report.testName,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  DateFormat('dd MMM yyyy').format(report.testDate),
                                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    report.status,
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: color, fontSize: 10),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

// ── SUB-SCREEN: FamilyAppointmentsScreen ──────────────────────────────────────
class FamilyAppointmentsScreen extends StatefulWidget {
  const FamilyAppointmentsScreen({super.key});

  @override
  State<FamilyAppointmentsScreen> createState() => _FamilyAppointmentsScreenState();
}

class _FamilyAppointmentsScreenState extends State<FamilyAppointmentsScreen> {
  FamilyLinkModel? _selectedPatient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patients = context.watch<CaregiverDashboardProvider>().patients;

    if (_selectedPatient == null && patients.isNotEmpty) {
      _selectedPatient = patients.first;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Appointment Hub', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: patients.isEmpty
          ? const Center(child: Text('No patients linked yet.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _PatientDropdown(
                    patients: patients,
                    selectedPatient: _selectedPatient,
                    onChanged: (link) => setState(() => _selectedPatient = link),
                  ),
                ),
                if (_selectedPatient != null)
                  Expanded(
                    child: StreamBuilder<List<AppointmentModel>>(
                      stream: HealthDataService().watchAppointments(_selectedPatient!.patientId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final appointments = snapshot.data ?? [];
                        final upcoming = appointments.where((a) => a.status != 'completed' && a.status != 'cancelled').toList();
                        final completed = appointments.where((a) => a.status == 'completed').toList();

                        return DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              TabBar(
                                labelColor: AppColors.primary,
                                unselectedLabelColor: AppColors.textSecondary,
                                indicatorColor: AppColors.primary,
                                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                tabs: const [
                                  Tab(text: 'Upcoming'),
                                  Tab(text: 'Completed'),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _buildAppointmentsList(context, upcoming, 'No upcoming appointments.'),
                                    _buildAppointmentsList(context, completed, 'No completed appointments.'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildAppointmentsList(BuildContext context, List<AppointmentModel> list, String emptyMsg) {
    if (list.isEmpty) {
      return Center(
        child: Text(emptyMsg, style: GoogleFonts.poppins(color: AppColors.textSecondary)),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final apt = list[index];
        final isCompleted = apt.status == 'completed';
        final statusColor = isCompleted
            ? AppColors.primary
            : apt.status == 'confirmed'
                ? AppColors.success
                : AppColors.warning;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: apt)),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        apt.doctorName,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          apt.status.toUpperCase(),
                          style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    apt.doctorSpecialty,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEE, d MMM yyyy • h:mm a').format(apt.dateTime),
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (apt.caregiverNotes != null && apt.caregiverNotes!.isNotEmpty) ...[
                    const Divider(height: 20),
                    Text(
                      'Caregiver Notes:',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    Text(
                      apt.caregiverNotes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
