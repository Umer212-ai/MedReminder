import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/core/utils/dose_utils.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/providers/health_provider.dart';
import 'package:thirdly/screens/add_medicine_screen.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_drawer.dart';
import 'medical_screen.dart';
import 'emergency_screen.dart';
import 'family_monitoring_screen.dart';
import 'voice_reminder_screen.dart';
import 'health_report_screen.dart';
import 'doctors_screen.dart';
import 'ai_chat_screen.dart';
import 'add_screen.dart';
import 'appointment_detail_screen.dart';
import 'my_appointments_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const HomeTab(),
    const MedicalScreen(),
    const EmergencyScreen(),
    const FamilyMonitoringScreen(),
    const VoiceReminderScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _screens[_currentIndex],
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
            onTap: (index) {
              if (index == 4) {
                _openDrawer();
              } else {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Overview',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.medical_services_outlined),
                activeIcon: Icon(Icons.medical_services_rounded),
                label: 'Medical',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emergency_outlined),
                activeIcon: Icon(Icons.emergency_rounded),
                label: 'Urgent',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.family_restroom_outlined),
                activeIcon: Icon(Icons.family_restroom_rounded),
                label: 'Family',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_rounded),
                activeIcon: Icon(Icons.menu_open_rounded),
                label: 'Menu',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const AddScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AppAuthProvider>();
    final medicineProvider = context.watch<MedicineProvider>();
    final healthProvider = context.watch<HealthDataProvider>();
    final userName = auth.user?.fullName ?? 'Guest';
    final taken = medicineProvider.todayTakenDoses;
    final total = medicineProvider.todayTotalDoses;
    final remaining = medicineProvider.todayRemainingDoses;
    final slots = medicineProvider.todayDoseSlots;
    final appointments = healthProvider.appointments;
    
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 360,
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
                    right: -30,
                    top: 40,
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 240,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back,',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  userName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ValueListenableBuilder<ThemeMode>(
                                  valueListenable: themeNotifier,
                                  builder: (context, mode, _) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          mode == ThemeMode.light
                                              ? Icons.dark_mode_rounded
                                              : Icons.light_mode_rounded,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          themeNotifier.value =
                                              mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                                        },
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.white, Colors.white.withValues(alpha: 0.5)],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppColors.primary,
                                    child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Expanded(
                              child: _GlassCard(
                                title: 'Today Taken',
                                value: '$taken',
                                unit: '/ $total',
                                subtitle: '$remaining remaining today',
                                icon: Icons.check_circle_outline_rounded,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _GlassCard(
                                title: 'Missed',
                                value: '${medicineProvider.todayMissedDoses}',
                                unit: 'doses',
                                subtitle: 'Past time, not taken',
                                icon: Icons.warning_amber_rounded,
                                color: Colors.cyanAccent,
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
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader(context, 'Premium Services', () {}),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.0,
                children: [
                  _ServiceCard(
                    title: 'Health Insight',
                    icon: Icons.analytics_rounded,
                    color: AppColors.primary,
                    description: 'Full Report',
                    onTap: () => _navigateTo(context, const HealthReportScreen()),
                  ),
                  _ServiceCard(
                    title: 'Care Network',
                    icon: Icons.local_hospital_rounded,
                    color: AppColors.secondary,
                    description: 'Find Doctors',
                    onTap: () => _navigateTo(context, const DoctorsScreen()),
                  ),
                  _ServiceCard(
                    title: 'Family Hub',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.purple,
                    description: 'Stay Connected',
                    onTap: () => _navigateTo(context, const FamilyMonitoringScreen()),
                  ),
                  _ServiceCard(
                    title: 'AI Assistant',
                    icon: Icons.auto_awesome_rounded,
                    color: AppColors.pink,
                    description: 'Smart Help',
                    onTap: () => _navigateTo(context, const AIChatScreen()),
                  ),
                ],
              ),
              if (appointments.isNotEmpty) ...[
                const SizedBox(height: 40),
                _buildSectionHeader(context, 'Upcoming Appointments', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()),
                  );
                }),
                const SizedBox(height: 16),
                ...appointments.take(3).toList().asMap().entries.map((e) {
                  final appt = e.value;
                  final colors = [AppColors.primary, AppColors.secondary, AppColors.purple];
                  final isNext = e.key == 0;
                  final timeStr = DateFormat('EEEE, MMM d, h:mm a').format(appt.dateTime);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AppointmentCard(
                      doctor: appt.doctorName,
                      specialty: appt.doctorSpecialty,
                      time: timeStr,
                      image: Icons.person_rounded,
                      color: colors[e.key % colors.length],
                      isNext: isNext,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppointmentDetailScreen(appointment: appt),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
              const SizedBox(height: 40),
              _buildSectionHeader(context, 'Today\'s Doses', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMedicineScreen()));
              }),
              const SizedBox(height: 12),
              if (total > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: taken / total,
                    minHeight: 10,
                    backgroundColor: AppColors.textLight.withValues(alpha: 0.15),
                    color: AppColors.success,
                  ),
                ),
              const SizedBox(height: 16),
              if (slots.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    'No doses scheduled for today. Add a medicine with today\'s times using +.',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary),
                  ),
                )
              else
                ...slots.map((slot) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TodayDoseCard(slot: slot),
                    )),
              const SizedBox(height: 40),
              _PremiumBanner(),
              const SizedBox(height: 40),
              _HealthTipCard(),
              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.headlineMedium?.color,
            letterSpacing: -0.5,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'See All',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _GlassCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: isDark ? 0.15 : 0.25),
                color.withValues(alpha: isDark ? 0.05 : 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Icon(Icons.more_vert_rounded, color: Colors.white.withValues(alpha: 0.4), size: 16),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
              isDark ? color.withValues(alpha: 0.05) : color.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.15 : 0.06),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayDoseCard extends StatelessWidget {
  final TodayDoseSlot slot;

  const _TodayDoseCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = slot.taken
        ? AppColors.success
        : slot.missed
            ? AppColors.error
            : AppColors.primary;
    final statusLabel = slot.taken
        ? 'Taken'
        : slot.missed
            ? 'Missed'
            : 'Pending';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.medicine.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${slot.medicine.dosage} @ ${slot.scheduleTime}',
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                Text(statusLabel, style: GoogleFonts.poppins(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (!slot.taken)
            IconButton(
              onPressed: () {
                final uid = context.read<AppAuthProvider>().uid;
                if (uid == null) return;
                context.read<MedicineProvider>().markTaken(
                      userId: uid,
                      medicine: slot.medicine,
                      scheduleTime: slot.scheduleTime,
                    );
              },
              icon: const Icon(Icons.check_circle_outline_rounded),
              color: AppColors.success,
              tooltip: 'Mark taken',
            ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final String doctor;
  final String specialty;
  final String time;
  final IconData image;
  final Color color;
  final bool isNext;
  final VoidCallback? onTap;

  const _AppointmentCard({
    required this.doctor,
    required this.specialty,
    required this.time,
    required this.image,
    required this.color,
    this.isNext = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
        color: isNext ? AppColors.primary : (isDark ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isNext ? Colors.transparent : color.withValues(alpha: isDark ? 0.2 : 0.1),
        ),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                )
              ]
            : [
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.1 : 0.02),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isNext ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(image, color: isNext ? Colors.white : color, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNext)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'NEXT SESSION',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Text(
                  doctor,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isNext ? Colors.white : theme.textTheme.titleMedium?.color,
                  ),
                ),
                Text(
                  specialty,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isNext ? Colors.white.withValues(alpha: 0.7) : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isNext ? Colors.white.withValues(alpha: 0.1) : theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              time.split(',').last.trim(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isNext ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkMeshGradient : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Icon(
              Icons.stars_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'PREMIUM CARE',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Complete Family Health Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Unlock advanced analytics, AI consultations, and real-time family health alerts.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Upgrade Now',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthTipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: isDark ? 0.15 : 0.1),
            AppColors.secondary.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.secondary.withValues(alpha: isDark ? 0.3 : 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Tip',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  'Drinking warm water in the morning helps boost metabolism.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
