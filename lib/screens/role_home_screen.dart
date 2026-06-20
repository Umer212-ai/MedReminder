import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/providers/health_provider.dart';
import 'package:thirdly/screens/home_screen.dart';
import 'package:thirdly/screens/login_screen.dart';
import 'package:thirdly/utils/app_colors.dart';

import 'caregiver_dashboard_screen.dart';
import 'caregiver_profile_setup_screen.dart';
import 'family_dashboard_screen.dart';

/// Routes each user role to the correct home experience.
class RoleHomeScreen extends StatelessWidget {
  const RoleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;
    final role = user?.role ?? UserRole.patient;
    
    switch (role) {
      case UserRole.familyMember:
        return const FamilyDashboardScreen();
      case UserRole.caregiver:
        final isProfileComplete = user != null &&
            user.fullName.isNotEmpty &&
            user.specialty != null && user.specialty!.trim().isNotEmpty &&
            user.clinicName != null && user.clinicName!.trim().isNotEmpty &&
            user.location != null && user.location!.trim().isNotEmpty &&
            user.qualification != null && user.qualification!.trim().isNotEmpty &&
            user.experience != null && user.experience!.trim().isNotEmpty &&
            user.phoneNumber.isNotEmpty;

        if (!isProfileComplete) {
          return const CaregiverProfileSetupScreen();
        } else {
          return const CaregiverDashboardScreen();
        }
      case UserRole.patient:
        return const HomeScreen();
    }
  }
}

class _WatcherHomeShell extends StatelessWidget {
  final String title;
  final IconData icon;

  const _WatcherHomeShell({required this.title, required this.icon});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign out?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You will need to sign in again to view linked patients.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sign out',
              style: GoogleFonts.poppins(color: AppColors.error),
            ),
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
    final user = context.watch<AppAuthProvider>().user;
    final patients = context.watch<HealthDataProvider>().watchedPatients;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.fullName ?? ''}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        user?.role == UserRole.caregiver
                            ? 'Monitor assigned patients and medicine adherence.'
                            : 'View linked family members and their daily medicine progress.',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (patients.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.textLight.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                'No patients linked yet.\n\nAsk the patient to add your email (${user?.email ?? ''}) in Family Hub → Add member, then re-login.',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            )
          else
            ...patients.map((link) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  title: Text(
                    link.patientName,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${link.relation} • monitoring as ${link.memberName}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${link.todayTaken}/${link.todayTotal}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'taken today',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
