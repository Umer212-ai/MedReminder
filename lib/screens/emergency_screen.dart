import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/services/emergency_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  Future<void> _triggerSos(BuildContext context) async {
    final auth = context.read<AppAuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final emergency = context.read<EmergencyService>();
    await emergency.sendEmergencyAlert(
      userId: user.uid,
      userName: user.fullName,
    );

    if (user.emergencyContact.isNotEmpty) {
      final uri = Uri.parse('tel:${user.emergencyContact}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency alert sent to your care network'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final uid = context.watch<AppAuthProvider>().uid;
    final emergencyService = context.read<EmergencyService>();
    
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
            backgroundColor: AppColors.error,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emergency_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: Text(
                'Emergency Center',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSOSButton(context, () => _triggerSos(context)),
                  const SizedBox(height: 40),
                  _buildSectionHeader(context, 'Emergency Contacts'),
                  const SizedBox(height: 16),
                  if (uid == null)
                    const Text('Sign in to manage emergency contacts')
                  else
                    StreamBuilder(
                      stream: emergencyService.watchContacts(uid),
                      builder: (context, snapshot) {
                        final contacts = snapshot.data ?? [];
                        if (contacts.isEmpty) {
                          final ec = context.watch<AppAuthProvider>().user?.emergencyContact;
                          if (ec != null && ec.isNotEmpty) {
                            return _EmergencyContactCard(
                              name: 'Primary Emergency',
                              phone: ec,
                              relation: 'Profile contact',
                              color: AppColors.primary,
                              onCall: () => launchUrl(Uri.parse('tel:$ec')),
                            );
                          }
                          return Text(
                            'Add emergency contact in profile registration',
                            style: GoogleFonts.poppins(color: AppColors.textSecondary),
                          );
                        }
                        return Column(
                          children: contacts.map((c) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _EmergencyContactCard(
                                name: c.name,
                                phone: c.phone,
                                relation: c.relation,
                                color: c.isPrimary ? AppColors.primary : AppColors.secondary,
                                onCall: () => launchUrl(Uri.parse('tel:${c.phone}')),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  const SizedBox(height: 40),
                  _buildSectionHeader(context, 'Nearby Hospitals'),
                  const SizedBox(height: 16),
                  _HospitalCard(
                    name: 'City General Hospital',
                    address: '123 Main St, New York',
                    distance: '2.5 km',
                    phone: '+1 234 567 8903',
                  ),
                  const SizedBox(height: 16),
                  _HospitalCard(
                    name: 'St. Mary\'s Medical Center',
                    address: '456 Oak Ave, New York',
                    distance: '3.2 km',
                    phone: '+1 234 567 8904',
                  ),
                  const SizedBox(height: 40),
                  _buildSectionHeader(context, 'Critical Medical Info'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Blood Type', value: 'O+', color: AppColors.error),
                        const Divider(height: 32),
                        _InfoRow(label: 'Allergies', value: 'Penicillin', color: AppColors.error),
                        const Divider(height: 32),
                        _InfoRow(label: 'Conditions', value: 'Diabetes Type 2', color: AppColors.error),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton(BuildContext context, VoidCallback onSos) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'In an Emergency?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Press the button below to alert emergency services and your primary contacts.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: onSos,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.error, AppColors.error.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.2),
                    blurRadius: 10,
                    offset: const Offset(-5, -5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'SOS',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final String relation;
  final Color color;
  final VoidCallback? onCall;

  const _EmergencyContactCard({
    required this.name,
    required this.phone,
    required this.relation,
    required this.color,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.person_rounded, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  relation,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.call_rounded, color: AppColors.success),
              onPressed: onCall,
            ),
          ),
        ],
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final String name;
  final String address;
  final String distance;
  final String phone;

  const _HospitalCard({
    required this.name,
    required this.address,
    required this.distance,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(28),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  distance,
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.phone_rounded, size: 18, color: theme.textTheme.bodyMedium?.color),
              const SizedBox(width: 8),
              Text(
                phone,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.directions_rounded, color: AppColors.primary),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
