import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/models/doctor_model.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/services/auth_service.dart';
import 'package:thirdly/utils/app_colors.dart';
import 'package:thirdly/widgets/health_add_sheets.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorDetailScreen extends StatefulWidget {
  final UserModel? caregiver;
  final DoctorModel? doctor;

  const DoctorDetailScreen({
    super.key,
    this.caregiver,
    this.doctor,
  }) : assert(caregiver != null || doctor != null, 'Either caregiver or doctor must be provided');

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  bool _hiring = false;

  String get _name => widget.caregiver?.fullName ?? widget.doctor?.name ?? 'Healthcare Professional';
  String get _specialty => widget.caregiver?.specialty ?? widget.doctor?.specialty ?? 'Specialist';
  String get _phone => widget.caregiver?.phoneNumber ?? widget.doctor?.phone ?? '';
  String get _clinic => widget.caregiver?.clinicName ?? widget.doctor?.clinic ?? '';
  String get _email => widget.caregiver?.email ?? '';
  String get _timing => widget.caregiver?.availableTiming ?? 'Flexible hours';
  bool get _isCaregiver => widget.caregiver != null;

  Future<void> _makeCall() async {
    if (_phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }
    final uri = Uri.parse('tel:${_phone.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not place a call to this number')),
        );
      }
    }
  }

  Future<void> _hireCaregiver() async {
    if (widget.caregiver == null) return;
    final caregiver = widget.caregiver!;

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

    final authProvider = context.read<AppAuthProvider>();
    final uid = authProvider.uid;
    final user = authProvider.user;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (uid == null || user == null) return;

    setState(() => _hiring = true);

    try {
      await context.read<AuthService>().createHireRequest(
        patientId: uid,
        patientName: user.fullName,
        patientEmail: user.email,
        caregiverId: caregiver.uid,
        caregiverName: caregiver.fullName,
        caregiverEmail: caregiver.email,
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Request sent to ${caregiver.fullName}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _hiring = false);
      }
    }
  }

  String _generateBio() {
    return 'Dr. $_name is an experienced healthcare specialist in $_specialty. Currently consulting at $_clinic, offering professional services with dedicated attention. Committed to ensuring premium care, patient adherence, and healthy recovery pathways.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _isCaregiver ? AppColors.primary : AppColors.secondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Header Card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkMeshGradient
                    : LinearGradient(
                        colors: [color, color.withValues(alpha: 0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Initial Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _name.isNotEmpty ? _name[0].toUpperCase() : 'D',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Name
                  Text(
                    _name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Specialty
                  Text(
                    _specialty,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isCaregiver ? 'REGISTERED CAREGIVER' : 'SAVED DOCTOR',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Bio Section
            _buildDetailCard(
              title: 'About Specialist',
              icon: Icons.info_outline_rounded,
              color: color,
              child: Text(
                _generateBio(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.6,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Clinic details
            if (_clinic.isNotEmpty) ...[
              _buildDetailCard(
                title: 'Clinic / Hospital',
                icon: Icons.local_hospital_outlined,
                color: color,
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _clinic,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Available timing
            _buildDetailCard(
              title: 'Available Hours',
              icon: Icons.access_time_rounded,
              color: color,
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _timing,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact details
            _buildDetailCard(
              title: 'Contact Information',
              icon: Icons.contact_page_outlined,
              color: color,
              child: Column(
                children: [
                  if (_phone.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.phone_rounded, color: color, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            _phone,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_email.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.email_outlined, color: color, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _email,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Quick Actions Button Bar
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _makeCall,
                      icon: Icon(Icons.phone_rounded, color: color),
                      label: Text(
                        'Call Now',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_isCaregiver) ...[
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _hiring ? null : _hireCaregiver,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _hiring
                            ? CircularProgressIndicator(color: color)
                            : Text(
                                'Hire Caregiver',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: color,
                                ),
                              ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            HealthAddSheets.showBookAppointment(
                              context,
                              doctor: widget.doctor,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Book Appointment',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_isCaregiver) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      HealthAddSheets.showBookAppointment(
                        context,
                        caregiver: widget.caregiver,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Book Appointment Now',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
