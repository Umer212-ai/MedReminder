import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/screens/edit_profile_screen.dart';
import 'package:thirdly/widgets/auth_wrapper.dart';
import '../utils/app_colors.dart';
import '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileSection(),
            const SizedBox(height: 32),
            _SettingsSection(
              title: 'Account Settings',
              items: [
                _SettingsItem(
                  icon: Icons.person_rounded,
                  label: 'Personal Information',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.lock_rounded,
                  label: 'Security & Password',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_rounded,
                  label: 'Privacy Policy',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),
            _SettingsSection(
              title: 'App Preferences',
              items: [
                _SettingsItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notification Settings',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.language_rounded,
                  label: 'App Language',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark Mode Theme',
                  onTap: () {
                    themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                  },
                  trailing: Switch.adaptive(
                    value: isDark,
                    onChanged: (value) {
                      themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _SettingsSection(
              title: 'Support & Help',
              items: [
                _SettingsItem(
                  icon: Icons.help_center_rounded,
                  label: 'Help Center',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.contact_support_rounded,
                  label: 'Customer Support',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.info_rounded,
                  label: 'About MedReminder',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),
            _SettingsSection(
              title: 'Account Actions',
              items: [
                _SettingsItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  onTap: () async {
                    await context.read<AppAuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                        (_) => false,
                      );
                    }
                  },
                  color: AppColors.error,
                  showChevron: false,
                ),
                _SettingsItem(
                  icon: Icons.delete_forever_rounded,
                  label: 'Delete Account',
                  onTap: () {},
                  color: AppColors.error,
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Text(
                    'MedReminder Premium',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Build v2.4.0 • Latest Update 2024',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<AppAuthProvider>().user;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Guest',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user?.role.name.toUpperCase() ?? 'PATIENT',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_rounded, size: 20),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, color: AppColors.textLight.withValues(alpha: 0.05)),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;
  final bool showChevron;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.color,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (color ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color ?? AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showChevron)
              Icon(Icons.chevron_right_rounded, color: theme.textTheme.bodySmall?.color, size: 20),
          ],
        ),
      ),
    );
  }
}
