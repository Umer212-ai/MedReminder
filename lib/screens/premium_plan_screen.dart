import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class PremiumPlanScreen extends StatelessWidget {
  const PremiumPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Premium Experience', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
            Text(
              'Unlock Full Potential',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.displayLarge?.color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a plan that fits your healthcare journey and family needs.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 32),
            _PlanCard(
              title: 'Standard',
              price: '\$9.90',
              period: '/mo',
              features: [
                'Complete Health Tracking',
                'Medication History',
                'Basic Health Analytics',
                '2 Emergency Contacts',
              ],
              color: AppColors.primary,
              isPopular: false,
            ),
            const SizedBox(height: 24),
            _PlanCard(
              title: 'Family Plus',
              price: '\$19.90',
              period: '/mo',
              features: [
                'Everything in Standard',
                'Monitor up to 5 Family Members',
                'Advanced AI Health Insights',
                'Priority Physician Support',
                'Unlimited Cloud Storage',
              ],
              color: AppColors.secondary,
              isPopular: true,
            ),
            const SizedBox(height: 24),
            _PlanCard(
              title: 'Organization',
              price: '\$49.90',
              period: '/mo',
              features: [
                'Unlimited Family Members',
                'Custom Health Reports',
                'API Data Export',
                '24/7 Dedicated Care Team',
                'Multiple Profile Access',
              ],
              color: AppColors.purple,
              isPopular: false,
            ),
            const SizedBox(height: 48),
            Text(
              'Premium Advantages',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _FeatureRow(
              icon: Icons.family_restroom_rounded,
              title: 'Comprehensive Family Care',
              description: 'Stay connected with your loved ones\' health status in real-time.',
            ),
            const SizedBox(height: 20),
            _FeatureRow(
              icon: Icons.auto_awesome_rounded,
              title: 'AI-Powered Insights',
              description: 'Get personalized recommendations based on your unique health data.',
            ),
            const SizedBox(height: 20),
            _FeatureRow(
              icon: Icons.verified_user_rounded,
              title: 'Bank-Grade Security',
              description: 'Your medical data is encrypted and protected with industry-leading standards.',
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'All plans include a 14-day free trial. No credit card required to start.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
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

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final Color color;
  final bool isPopular;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.color,
    required this.isPopular,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isPopular ? color : AppColors.textLight.withValues(alpha: 0.1),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPopular ? color : Colors.black).withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: Text(
                  'RECOMMENDED',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: theme.textTheme.displayLarge?.color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      period,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Icon(Icons.verified_rounded, color: color, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: theme.textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      'Upgrade Now',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
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

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
