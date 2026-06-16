import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/models/appointment_model.dart';
import 'package:thirdly/models/family_link_model.dart';
import 'package:thirdly/models/hire_request_model.dart';
import 'package:thirdly/models/vital_model.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/models/notification_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/providers/caregiver_dashboard_provider.dart';
import 'package:thirdly/providers/health_provider.dart';
import 'package:thirdly/screens/appointment_detail_screen.dart';
import 'package:thirdly/screens/caregiver_profile_edit_screen.dart';
import 'package:thirdly/screens/login_screen.dart';
import 'package:thirdly/screens/notifications_screen.dart';
import 'package:thirdly/screens/patient_detail_screen.dart';
import 'package:thirdly/services/appointment_service.dart';
import 'package:thirdly/services/health_data_service.dart';
import 'package:thirdly/services/hire_request_service.dart';
import 'package:thirdly/services/notification_service.dart';
import 'package:thirdly/services/notification_helper_service.dart';
import 'package:thirdly/services/auth_service.dart';
import 'package:thirdly/utils/app_colors.dart';
import 'package:thirdly/main.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final HireRequestService _hireRequestService = HireRequestService();
  final AppointmentService _appointmentService = AppointmentService();
  final NotificationHelperService _notificationHelper = NotificationHelperService();

  List<HireRequestModel> _hireRequests = [];
  List<AppointmentModel> _appointments = [];
  List<NotificationModel> _notifications = [];
  StreamSubscription? _hireRequestsSub;
  StreamSubscription? _appointmentsSub;
  StreamSubscription? _notificationsSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadHireRequestsAndAppointments();
    
    // Initialize CaregiverDashboardProvider with caregiver's UID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final uid = context.read<AppAuthProvider>().uid;
        if (uid != null) {
          context.read<CaregiverDashboardProvider>().initialize(uid);
        }
      }
    });
  }

  void _loadHireRequestsAndAppointments() {
    final auth = context.read<AppAuthProvider>();
    final uid = auth.uid;
    if (uid == null) return;

    _hireRequestsSub = _hireRequestService.watchCaregiverRequests(uid).listen((requests) {
      if (mounted) {
        setState(() {
          _hireRequests = requests;
        });
      }
    });

    _appointmentsSub = _appointmentService.watchDoctorAppointments(uid).listen((appointments) {
      if (mounted) {
        setState(() {
          _appointments = appointments;
        });
      }
    });

    _notificationsSub = _notificationHelper.getUserNotifications(uid).listen((notifications) {
      if (mounted) {
        setState(() {
          _notifications = notifications;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _hireRequestsSub?.cancel();
    _appointmentsSub?.cancel();
    _notificationsSub?.cancel();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Sign out?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'You will need to sign in again to monitor your patients.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign out',
                style: GoogleFonts.poppins(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
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

  void _openPatientDetail(BuildContext context, FamilyLinkModel link) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, animation, _) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  HealthDataProvider()..listenForPatient(link.patientId),
            ),
            ChangeNotifierProvider(
              create: (ctx) => MedicineProvider(
                scheduler: ctx.read<NotificationService>().scheduler,
              )..listenToPatientMedicines(link.patientId),
            ),
          ],
          child: PatientDetailScreen(patientLink: link),
        ),
        transitionsBuilder: (ctx, animation, _, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  Future<void> _acceptHireRequest(HireRequestModel request) async {
    try {
      await _hireRequestService.acceptRequest(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are now linked with ${request.patientName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectHireRequest(HireRequestModel request) async {
    try {
      await _hireRequestService.rejectRequest(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmAppointment(AppointmentModel appointment) async {
    try {
      await _appointmentService.confirmAppointment(appointment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment with ${appointment.patientName} confirmed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm appointment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _declineAppointment(AppointmentModel appointment) async {
    try {
      await _appointmentService.declineAppointment(appointment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment declined'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline appointment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AppAuthProvider>();
    final caregiverUser = auth.user;
    final provider = context.watch<CaregiverDashboardProvider>();

    final patientCount = provider.patientsCount;
    final compliance = provider.complianceRate;
    final missed = provider.missedDosesCount;
    final alerts = provider.criticalAlerts;
    final upcoming = provider.upcomingMedicines;
    final activities = provider.recentActivities;
    final patients = provider.patients;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final pendingApps = _appointments.where((a) => a.status == 'pending').toList();
    final todayApps = _appointments.where((a) => a.status == 'confirmed' && a.dateTime.isAfter(todayStart) && a.dateTime.isBefore(todayEnd)).toList();
    final upcomingApps = _appointments.where((a) => a.status == 'confirmed' && a.dateTime.isAfter(todayEnd)).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero Header ──────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 240,
              floating: false,
              pinned: true,
              backgroundColor:
                  isDark ? AppColors.backgroundDark : AppColors.primary,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? AppColors.darkMeshGradient
                        : AppColors.primaryGradient,
                  ),
                  child: Stack(
                    children: [
                      // Background decorative icon
                      Positioned(
                        right: -40,
                        top: 20,
                        child: Icon(
                          Icons.health_and_safety_rounded,
                          size: 220,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 70, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Top row: avatar + greeting + actions
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Caregiver Avatar
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.25),
                                    child: Text(
                                      caregiverUser?.fullName.isNotEmpty == true
                                          ? caregiverUser!.fullName
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : 'C',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _greeting(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        caregiverUser?.fullName ?? 'Caregiver',
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Dark mode toggle
                                ValueListenableBuilder<ThemeMode>(
                                  valueListenable: themeNotifier,
                                  builder: (context, mode, _) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          mode == ThemeMode.light
                                              ? Icons.dark_mode_rounded
                                              : Icons.light_mode_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          themeNotifier.value =
                                              mode == ThemeMode.light
                                                  ? ThemeMode.dark
                                                  : ThemeMode.light;
                                        },
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 6),
                                // Sign out
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.logout_rounded,
                                        color: Colors.white, size: 20),
                                    onPressed: () => _signOut(context),
                                    tooltip: 'Sign Out',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Edit Profile
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit_rounded,
                                        color: Colors.white, size: 20),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CaregiverProfileEditScreen(),
                                        ),
                                      );
                                    },
                                    tooltip: 'Edit Profile',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Sub-info row
                            Row(
                              children: [
                                // Active pulse dot
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, _) => Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withValues(
                                        alpha:
                                            0.4 + _pulseController.value * 0.6,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.greenAccent
                                              .withValues(alpha: 0.6),
                                          blurRadius:
                                              6 * _pulseController.value,
                                          spreadRadius:
                                              2 * _pulseController.value,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Active  •  '
                                  'Monitoring $patientCount Patient${patientCount != 1 ? 's' : ''} Today  •  '
                                  '${DateFormat('EEE, MMM d').format(DateTime.now())}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body Content ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Caregiver Profile Summary Card ─────────────────
                  _buildCaregiverProfileCard(caregiverUser),
                  const SizedBox(height: 28),

                  // ── Quick Actions ──────────────────────────────────
                  _sectionHeader('Quick Actions', Icons.bolt_rounded, AppColors.warning),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 28),

                  // ── Summary Statistics ───────────────────────────
                  _sectionHeader('Dashboard Overview', Icons.analytics_rounded, AppColors.primary),
                  const SizedBox(height: 12),
                  _AnimatedStatRow(
                    patientsCount: patientCount,
                    compliance: compliance,
                    missed: missed,
                    alertsCount: alerts.length,
                  ),
                  const SizedBox(height: 32),

                  // ── Pending Hire Requests ─────────────────────────
                  if (_hireRequests.isNotEmpty) ...[
                    _sectionHeader('Pending Hire Requests', Icons.person_add_rounded, AppColors.primary),
                    const SizedBox(height: 12),
                    ..._hireRequests.take(3).map((request) => _HireRequestCard(
                          request: request,
                          onAccept: () => _acceptHireRequest(request),
                          onReject: () => _rejectHireRequest(request),
                        )),
                    const SizedBox(height: 28),
                  ],

                  // ── Today's Appointments ───────────────────────────
                  if (todayApps.isNotEmpty) ...[
                    _sectionHeader("Today's Appointments", Icons.today_rounded, AppColors.success),
                    const SizedBox(height: 12),
                    ...todayApps.map((appointment) => _ConfirmedAppointmentCard(
                          appointment: appointment,
                        )),
                    const SizedBox(height: 28),
                  ],

                  // ── Upcoming Appointments ──────────────────────────
                  if (upcomingApps.isNotEmpty) ...[
                    _sectionHeader('Upcoming Appointments', Icons.calendar_month_rounded, AppColors.secondary),
                    const SizedBox(height: 12),
                    ...upcomingApps.map((appointment) => _ConfirmedAppointmentCard(
                          appointment: appointment,
                        )),
                    const SizedBox(height: 28),
                  ],

                  // ── Pending Appointment Requests ────────────────────
                  if (pendingApps.isNotEmpty) ...[
                    _sectionHeader('Pending Appointment Requests', Icons.calendar_today_rounded, AppColors.secondary),
                    const SizedBox(height: 12),
                    ...pendingApps.map((appointment) => _AppointmentCard(
                          appointment: appointment,
                          onConfirm: () => _confirmAppointment(appointment),
                          onDecline: () => _declineAppointment(appointment),
                        )),
                    const SizedBox(height: 28),
                  ],

                  // ── Critical Alerts ─────────────────────────────
                  if (alerts.isNotEmpty) ...[
                    _sectionHeader('Critical Alerts', Icons.warning_amber_rounded,
                        AppColors.error),
                    const SizedBox(height: 12),
                    ...alerts.take(5).map((alert) => _AlertCard(alert: alert)),
                    const SizedBox(height: 28),
                  ],

                  // ── Recent Notifications ───────────────────────────
                  if (_notifications.isNotEmpty) ...[
                    _sectionHeader('Recent Notifications', Icons.notifications_active_rounded, AppColors.purple),
                    const SizedBox(height: 12),
                    ..._notifications.take(5).map((n) => _DashboardNotificationTile(notification: n)),
                    const SizedBox(height: 28),
                  ],

                  // ── Monitored Patients ──────────────────────────
                  _sectionHeader('Monitored Patients',
                      Icons.people_alt_rounded, AppColors.primary),
                  const SizedBox(height: 12),
                  if (provider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    )
                  else if (patients.isEmpty)
                    _EmptyStateCard(
                        email: caregiverUser?.email ?? '')
                  else
                    ...patients.map((link) => _PatientCard(
                          link: link,
                          status: provider.getPatientStatus(link.patientId),
                          onDetails: () =>
                              _openPatientDetail(context, link),
                        )),

                  const SizedBox(height: 28),

                  // ── Recent Activity ─────────────────────────────
                  if (activities.isNotEmpty) ...[
                    _sectionHeader('Recent Activity',
                        Icons.timeline_rounded, AppColors.secondary),
                    const SizedBox(height: 12),
                    ...activities.take(8).map((a) => _ActivityTile(item: a)),
                    const SizedBox(height: 28),
                  ],

                  // ── Upcoming Medicines ──────────────────────────
                  if (upcoming.isNotEmpty) ...[
                    _sectionHeader('Upcoming Medicines',
                        Icons.schedule_rounded, AppColors.purple),
                    const SizedBox(height: 12),
                    ...upcoming.take(6).map((item) => _UpcomingMedicineTile(item: item)),
                    const SizedBox(height: 28),
                  ],

                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
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

// ── Animated Statistics Row ───────────────────────────────────────────────────

class _AnimatedStatRow extends StatefulWidget {
  final int patientsCount;
  final double compliance;
  final int missed;
  final int alertsCount;

  const _AnimatedStatRow({
    required this.patientsCount,
    required this.compliance,
    required this.missed,
    required this.alertsCount,
  });

  @override
  State<_AnimatedStatRow> createState() => _AnimatedStatRowState();
}

class _AnimatedStatRowState extends State<_AnimatedStatRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, _) {
        final t = _anim.value;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Patients',
                    value: (widget.patientsCount * t).round().toString(),
                    icon: Icons.people_alt_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    label: 'Compliance',
                    value: '${(widget.compliance * t).round()}%',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Missed Doses',
                    value: (widget.missed * t).round().toString(),
                    icon: Icons.medication_liquid_rounded,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    label: 'Alerts',
                    value: (widget.alertsCount * t).round().toString(),
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.1 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alert Card ─────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final CaregiverAlert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCritical = alert.severity == 'critical';
    final color = isCritical ? AppColors.error : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCritical
                  ? Icons.error_rounded
                  : Icons.warning_amber_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  DateFormat('h:mm a').format(alert.timestamp),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isCritical ? 'CRITICAL' : 'WARN',
              style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Patient Card ──────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final FamilyLinkModel link;
  final String status;
  final VoidCallback onDetails;

  const _PatientCard({
    required this.link,
    required this.status,
    required this.onDetails,
  });

  Color _statusColor() {
    switch (status) {
      case 'High Risk':
        return AppColors.error;
      case 'Attention Needed':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  IconData _statusIcon() {
    switch (status) {
      case 'High Risk':
        return Icons.dangerous_rounded;
      case 'Attention Needed':
        return Icons.warning_amber_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _statusColor();
    final hasDoses = link.todayTotal > 0;
    final progress = hasDoses ? (link.todayTaken / link.todayTotal) : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, v, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - v)),
        child: Opacity(opacity: v, child: child),
      ),
      child: GestureDetector(
        onTap: onDetails,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: statusColor.withValues(
                  alpha: status == 'Stable' ? 0.08 : 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          link.patientName.isNotEmpty
                              ? link.patientName[0].toUpperCase()
                              : 'P',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link.patientName,
                            style: GoogleFonts.poppins(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${link.relation}  •  ${link.memberAge} Years',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(), color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Medicine adherence
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today\'s Adherence',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      hasDoses
                          ? '${link.todayTaken} / ${link.todayTotal} medicines taken'
                          : 'No schedule today',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Live vitals mini-row
                StreamBuilder<List<VitalModel>>(
                  stream: HealthDataService().watchVitals(link.patientId),
                  builder: (ctx, snapshot) {
                    final vitals = snapshot.data ?? [];
                    VitalModel? getV(VitalType t) {
                      try {
                        return vitals.firstWhere((v) => v.type == t);
                      } catch (_) {
                        return null;
                      }
                    }

                    final hr = getV(VitalType.heartRate);
                    final bp = getV(VitalType.bloodPressure);
                    final sg = getV(VitalType.bloodSugar);

                    return Row(
                      children: [
                        Expanded(
                          child: _MiniVital(
                              label: 'Pulse',
                              value: hr?.value ?? '—',
                              unit: 'bpm',
                              icon: Icons.favorite_rounded,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniVital(
                              label: 'BP',
                              value: bp?.value ?? '—',
                              unit: 'mmHg',
                              icon: Icons.monitor_heart_rounded,
                              color: AppColors.success),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniVital(
                              label: 'Sugar',
                              value: sg?.value ?? '—',
                              unit: 'mg/dL',
                              icon: Icons.opacity_rounded,
                              color: AppColors.secondary),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDetails,
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: Text('Open Details',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.analytics_outlined, size: 16),
                      label: Text('Records',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mini Vital Tile ───────────────────────────────────────────────────────────

class _MiniVital extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MiniVital({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold)),
                Text(
                  value != '—' ? '$value $unit' : '—',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: value != '—'
                        ? (isDark ? Colors.white : AppColors.textPrimary)
                        : AppColors.textLight,
                  ),
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

// ── Activity Tile ─────────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final ActivityFeedItem item;

  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color;
    final IconData icon;

    switch (item.type) {
      case 'took_med':
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case 'missed_med':
        color = AppColors.error;
        icon = Icons.cancel_rounded;
        break;
      case 'vital_recorded':
        color = AppColors.primary;
        icon = Icons.monitor_heart_rounded;
        break;
      default:
        color = AppColors.secondary;
        icon = Icons.science_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Container(
                width: 1.5,
                height: 24,
                color: AppColors.textLight.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.textLight.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.message,
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('h:mm a').format(item.timestamp),
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming Medicine Tile ────────────────────────────────────────────────────

class _UpcomingMedicineTile extends StatelessWidget {
  final UpcomingMedicineItem item;

  const _UpcomingMedicineTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medication_rounded,
                color: AppColors.purple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.patientName,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  item.medicineName,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  item.dosage,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.time,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.purple),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State Card ──────────────────────────────────────────────────────────

class _EmptyStateCard extends StatefulWidget {
  final String email;
  const _EmptyStateCard({required this.email});

  @override
  State<_EmptyStateCard> createState() => _EmptyStateCardState();
}

class _EmptyStateCardState extends State<_EmptyStateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: AppColors.textLight.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (ctx, child) => Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: child,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primaryLight.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Transform.rotate(
                angle: math.pi / 12,
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Patients Connected',
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'To start monitoring patient health and medications, ask them to add your caregiver email in their MedReminder app:',
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.alternate_email_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: SelectableText(
                    widget.email,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How to connect:',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                const SizedBox(height: 6),
                _howToStep('1', 'Patient opens MedReminder app'),
                _howToStep('2', 'Goes to Home  →  Family Hub'),
                _howToStep('3', 'Taps  " + Add member "'),
                _howToStep('4', 'Enters your caregiver email above'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _howToStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Hire Request Card ─────────────────────────────────────────────────────────────

class _HireRequestCard extends StatelessWidget {
  final HireRequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _HireRequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  void _openPatientDetail(BuildContext context, UserModel patient) {
    final tempLink = FamilyLinkModel(
      id: request.id,
      patientId: request.patientId,
      patientName: patient.fullName,
      memberName: request.caregiverName,
      relation: 'Applicant',
      memberAge: patient.age,
      watcherEmail: request.caregiverEmail,
      watcherId: request.caregiverId,
      todayTaken: 0,
      todayTotal: 0,
      createdAt: request.createdAt,
    );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, animation, _) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  HealthDataProvider()..listenForPatient(tempLink.patientId),
            ),
            ChangeNotifierProvider(
              create: (ctx) => MedicineProvider(
                scheduler: ctx.read<NotificationService>().scheduler,
              )..listenToPatientMedicines(tempLink.patientId),
            ),
          ],
          child: PatientDetailScreen(patientLink: tempLink),
        ),
        transitionsBuilder: (ctx, animation, _, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<UserModel?>(
      future: AuthService().getUserProfile(request.patientId),
      builder: (context, snapshot) {
        final patient = snapshot.data;
        final age = patient?.age ?? 0;
        final gender = patient?.gender ?? 'Not Specified';
        final medicalSummary = patient?.medicalSummary ?? 'No medical summary available.';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.patientName,
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          request.patientEmail,
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Age: ${age > 0 ? age : 'N/A'}',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Gender: $gender',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Medical Summary:',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.textLight.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  medicalSummary,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              if (request.message != null && request.message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Message:',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.message!,
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Accept', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (patient != null)
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _openPatientDetail(context, patient),
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: Text(
                      'View Details',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Appointment Card ─────────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  const _AppointmentCard({
    required this.appointment,
    required this.onConfirm,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: AppColors.secondary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      appointment.doctorSpecialty,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMM d, yyyy • h:mm a').format(appointment.dateTime),
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            appointment.problem,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Decline', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Confirm', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Confirmed Appointment Card ──────────────────────────────────────────────────

class _ConfirmedAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _ConfirmedAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.event_available_rounded, color: AppColors.secondary),
        ),
        title: Text(
          appointment.patientName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(appointment.dateTime),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.secondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              appointment.problem,
              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppointmentDetailScreen(appointment: appointment),
            ),
          );
        },
      ),
    );
  }
}

// ── Dashboard Notification Tile ────────────────────────────────────────────────

class _DashboardNotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _DashboardNotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_rounded, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Caregiver Profile Helper Widgets ───────────────────────────────────────────

extension _CaregiverDashboardScreenStateHelpers on _CaregiverDashboardScreenState {
  Widget _buildCaregiverProfileCard(UserModel? user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (user == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null
                    ? const Icon(Icons.person_rounded, size: 36, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.specialty ?? 'General Caregiver',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CaregiverProfileEditScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                tooltip: 'Edit Profile',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _profileInfoRow(Icons.local_hospital_outlined, 'Clinic / Hospital', user.clinicName ?? 'N/A'),
          _profileInfoRow(Icons.location_on_outlined, 'Location', user.location ?? 'N/A'),
          _profileInfoRow(Icons.school_outlined, 'Qualification', user.qualification ?? 'N/A'),
          _profileInfoRow(Icons.work_history_outlined, 'Experience', '${user.experience ?? '0'} years'),
          _profileInfoRow(Icons.phone_android_outlined, 'Phone', user.phoneNumber),
          if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'About:',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              user.bio!,
              style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
            ),
          ]
        ],
      ),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.edit_rounded,
            label: 'Edit Profile',
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CaregiverProfileEditScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.notifications_rounded,
            label: 'All Alerts',
            color: AppColors.secondary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Quick Action Card ──────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
