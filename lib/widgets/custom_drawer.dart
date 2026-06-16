import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/screens/add_medicine_screen.dart';
import 'package:thirdly/screens/login_screen.dart';
import 'package:thirdly/screens/medical_screen.dart';
import 'package:thirdly/screens/emergency_screen.dart';
import 'package:thirdly/screens/family_monitoring_screen.dart';
import 'package:thirdly/screens/voice_reminder_screen.dart';
import 'package:thirdly/screens/health_report_screen.dart';
import 'package:thirdly/screens/doctors_screen.dart';
import 'package:thirdly/screens/premium_plan_screen.dart';
import 'package:thirdly/screens/notifications_screen.dart';
import 'package:thirdly/screens/settings_screen.dart';
import 'package:thirdly/screens/ai_chat_screen.dart';
import 'package:thirdly/screens/accessibility_screen.dart';
import '../utils/app_colors.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
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
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<AppAuthProvider>().user;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkMeshGradient : AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, user?.fullName ?? 'Guest', user?.email ?? ''),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: Colors.white24, height: 1),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildDrawerItem(context, icon: Icons.dashboard_outlined, title: 'Dashboard Overview', onTap: () => Navigator.pop(context)),
                    _buildDrawerItem(context, icon: Icons.medical_services_outlined, title: 'Medical Records', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalScreen())); }),
                    _buildDrawerItem(context, icon: Icons.emergency_outlined, title: 'Emergency Center', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen())); }),
                    _buildDrawerItem(context, icon: Icons.family_restroom_outlined, title: 'Family Monitoring', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyMonitoringScreen())); }),
                    _buildDrawerItem(context, icon: Icons.mic_outlined, title: 'Voice Reminders', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceReminderScreen())); }),
                    _buildDrawerItem(context, icon: Icons.assessment_outlined, title: 'Health Analytics', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthReportScreen())); }),
                    _buildDrawerItem(context, icon: Icons.local_hospital_outlined, title: 'Doctors & Clinics', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorsScreen())); }),
                    _buildDrawerItem(context, icon: Icons.smart_toy_outlined, title: 'AI Health Assistant', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen())); }),
                    _buildDrawerItem(context, icon: Icons.workspace_premium_outlined, title: 'Premium Plans', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPlanScreen())); }),
                    _buildDrawerItem(context, icon: Icons.accessibility_new_outlined, title: 'Accessibility Settings', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilityScreen())); }),
                    _buildDrawerItem(context, icon: Icons.notifications_outlined, title: 'Notifications', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())); }),
                    _buildDrawerItem(context, icon: Icons.settings_outlined, title: 'App Settings', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
                  ],
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String email) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.person_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(email, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMedicineScreen()));
            },
            icon: const Icon(Icons.medication_rounded, size: 20),
            label: Text('Add Medicine', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            label: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: Colors.white54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }
}
