import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/models/doctor_model.dart';
import 'package:thirdly/models/hire_request_model.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/providers/health_provider.dart';
import 'package:thirdly/screens/doctor_detail_screen.dart';
import 'package:thirdly/services/auth_service.dart';
import 'package:thirdly/widgets/health_add_sheets.dart';
import '../utils/app_colors.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  List<UserModel> _caregivers = [];
  bool _loadingCaregivers = false;
  List<HireRequestModel> _hireRequests = [];
  StreamSubscription? _hireRequestsSub;

  @override
  void initState() {
    super.initState();
    _loadCaregivers();
    _listenHireRequests();
  }

  @override
  void dispose() {
    _hireRequestsSub?.cancel();
    super.dispose();
  }

  void _listenHireRequests() {
    final uid = context.read<AppAuthProvider>().uid;
    if (uid == null) return;
    _hireRequestsSub = context
        .read<AuthService>()
        .watchPatientRequests(uid)
        .listen((requests) {
      if (mounted) setState(() => _hireRequests = requests);
    });
  }

  /// Returns the hire status for a specific caregiver:
  /// null = no request, 'pending', 'accepted', 'rejected', 'cancelled'
  RequestStatus? _getHireStatus(String caregiverId) {
    try {
      final req = _hireRequests.firstWhere(
        (r) => r.caregiverId == caregiverId,
      );
      return req.status;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadCaregivers() async {
    setState(() => _loadingCaregivers = true);
    try {
      final caregivers = await context.read<AuthService>().getCaregivers();
      if (mounted) {
        setState(() => _caregivers = caregivers);
      }
    } catch (e) {
      debugPrint('Error loading caregivers: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingCaregivers = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final doctors = context.watch<HealthDataProvider>().doctors;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.darkMeshGradient : AppColors.primaryGradient,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 100, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Your Specialist',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Access world-class healthcare professionals at your fingertips.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: Text(
                'Healthcare Directory',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                onPressed: () => HealthAddSheets.showAddDoctor(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: TextField(
                      style: GoogleFonts.poppins(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: 'Search by name, specialty, or clinic...',
                        hintStyle: GoogleFonts.poppins(color: AppColors.textLight.withValues(alpha: 0.6)),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: theme.cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Core Specialties'),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _CategoryCard(icon: Icons.local_hospital_rounded, label: 'General', color: AppColors.primary),
                        const SizedBox(width: 16),
                        _CategoryCard(icon: Icons.favorite_rounded, label: 'Cardiology', color: AppColors.error),
                        const SizedBox(width: 16),
                        _CategoryCard(icon: Icons.psychology_rounded, label: 'Neurology', color: AppColors.purple),
                        const SizedBox(width: 16),
                        _CategoryCard(icon: Icons.accessibility_new_rounded, label: 'Orthopedic', color: AppColors.secondary),
                        const SizedBox(width: 16),
                        _CategoryCard(icon: Icons.child_care_rounded, label: 'Pediatrics', color: AppColors.orange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Available Caregivers'),
                  const SizedBox(height: 12),
                  if (_loadingCaregivers)
                    const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  else if (_caregivers.isEmpty)
                    Text(
                      'No caregivers registered yet.',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary),
                    )
                  else
                    ..._caregivers.asMap().entries.map((e) {
                      final caregiver = e.value;
                      final colors = [AppColors.primary, AppColors.secondary, AppColors.purple];
                      final hireStatus = _getHireStatus(caregiver.uid);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CaregiverCard(
                          caregiver: caregiver,
                          color: colors[e.key % colors.length],
                          hireStatus: hireStatus,
                          onHire: () => _hireCaregiver(caregiver),
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'Your Doctors'),
                  const SizedBox(height: 12),
                  if (doctors.isEmpty)
                    Text(
                      'No doctors saved. Tap + to add your doctor (name, specialty, phone, clinic).',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary),
                    )
                  else
                    ...doctors.asMap().entries.map((e) {
                      final d = e.value;
                      final colors = [AppColors.primary, AppColors.secondary, AppColors.purple];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _DoctorCard(
                          doctor: d,
                          rating: 5.0,
                          reviews: 0,
                          image: Icons.person_rounded,
                          color: colors[e.key % colors.length],
                        ),
                      );
                    }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'Explore All',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _hireCaregiver(UserModel caregiver) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hire as Consultant',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Do you want to send a hire request to ${caregiver.fullName}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Send Request',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Send hire request to caregiver
    final authProvider = context.read<AppAuthProvider>();
    final uid = authProvider.uid;
    final user = authProvider.user;
    if (uid == null || user == null) return;

    try {
      await context.read<AuthService>().createHireRequest(
        patientId: uid,
        patientName: user.fullName,
        patientEmail: user.email,
        caregiverId: caregiver.uid,
        caregiverName: caregiver.fullName,
        caregiverEmail: caregiver.email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request sent to ${caregiver.fullName}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send request',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _CaregiverCard extends StatelessWidget {
  final UserModel caregiver;
  final Color color;
  final RequestStatus? hireStatus;
  final VoidCallback onHire;

  const _CaregiverCard({
    required this.caregiver,
    required this.color,
    required this.onHire,
    this.hireStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAccepted = hireStatus == RequestStatus.accepted;
    final isPending = hireStatus == RequestStatus.pending;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorDetailScreen(caregiver: caregiver),
            ),
          );
        },
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: color.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.6)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        caregiver.fullName.isNotEmpty
                            ? caregiver.fullName[0].toUpperCase()
                            : 'C',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                caregiver.fullName,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Doctor',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (caregiver.specialty != null && caregiver.specialty!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            caregiver.specialty!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (caregiver.clinicName != null && caregiver.clinicName!.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.local_hospital_rounded, size: 14, color: AppColors.textLight),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  caregiver.clinicName!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (caregiver.availableTiming != null && caregiver.availableTiming!.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.access_time_filled_rounded, size: 14, color: AppColors.textLight),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  caregiver.availableTiming!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            const Icon(
                              Icons.email_rounded,
                              size: 14,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                caregiver.email,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (caregiver.phoneNumber.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_rounded,
                                size: 14,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                caregiver.phoneNumber,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.health_and_safety_rounded,
                    size: 18,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAccepted
                          ? 'Hired — Ready to book'
                          : 'Available for consultation',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isAccepted ? AppColors.success : null,
                      ),
                    ),
                  ),
                  // Show buttons based on hire status
                  if (isAccepted)
                    // Accepted → show Book Now
                    ElevatedButton.icon(
                      onPressed: () {
                        HealthAddSheets.showBookAppointment(context, caregiver: caregiver);
                      },
                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                      label: Text(
                        'Book Now',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    )
                  else if (isPending)
                    // Pending → show disabled pending chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Request Pending',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // No request or rejected/cancelled → show Hire button
                    ElevatedButton.icon(
                      onPressed: onHire,
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: Text(
                        'Hire',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CategoryCard({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: color, size: 34),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final double rating;
  final int reviews;
  final IconData image;
  final Color color;

  const _DoctorCard({
    required this.doctor,
    required this.rating,
    required this.reviews,
    required this.image,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final experience = doctor.clinic.isNotEmpty ? doctor.clinic : doctor.phone;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorDetailScreen(doctor: doctor),
            ),
          );
        },
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(image, color: color, size: 48),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          doctor.specialty,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              rating.toString(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($reviews reviews)',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.history_edu_rounded, size: 18, color: AppColors.textLight),
                  const SizedBox(width: 8),
                  Text(
                    experience,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      HealthAddSheets.showBookAppointment(context, doctor: doctor);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Book Now',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  final String name;
  final String address;
  final String distance;
  final double rating;
  final bool isOpen;

  const _ClinicCard({
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: (isOpen ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOpen ? 'OPEN NOW' : 'CLOSED',
                  style: GoogleFonts.poppins(
                    color: isOpen ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 6),
              Text(
                rating.toString(),
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(width: 16),
              Icon(Icons.near_me_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                distance,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
