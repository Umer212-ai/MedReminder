import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class HealthReportScreen extends StatelessWidget {
  const HealthReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
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
                        'Overall Health Score',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '85',
                            style: GoogleFonts.poppins(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '/100',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Condition: Excellent',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: Text(
                'Health Analysis',
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
                  _buildSectionHeader(context, 'Vital Metrics'),
                  const SizedBox(height: 16),
                  _MetricCard(
                    title: 'Heart Rate',
                    value: '72',
                    unit: 'bpm',
                    icon: Icons.favorite_rounded,
                    color: AppColors.error,
                    progress: 0.72,
                  ),
                  const SizedBox(height: 16),
                  _MetricCard(
                    title: 'Blood Pressure',
                    value: '120/80',
                    unit: 'mmHg',
                    icon: Icons.monitor_heart_rounded,
                    color: AppColors.primary,
                    progress: 0.8,
                  ),
                  const SizedBox(height: 16),
                  _MetricCard(
                    title: 'Sleep Quality',
                    value: '7.5',
                    unit: 'hours',
                    icon: Icons.bedtime_rounded,
                    color: AppColors.purple,
                    progress: 0.85,
                  ),
                  const SizedBox(height: 40),
                  _buildSectionHeader(context, 'Weekly Performance'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(28),
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
                        _ProgressRow(day: 'Mon', value: 0.7, color: AppColors.primary),
                        const SizedBox(height: 18),
                        _ProgressRow(day: 'Tue', value: 0.8, color: AppColors.primary),
                        const SizedBox(height: 18),
                        _ProgressRow(day: 'Wed', value: 0.75, color: AppColors.primary),
                        const SizedBox(height: 18),
                        _ProgressRow(day: 'Thu', value: 0.9, color: AppColors.primary),
                        const SizedBox(height: 18),
                        _ProgressRow(day: 'Fri', value: 0.85, color: AppColors.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildSectionHeader(context, 'Expert Recommendations'),
                  const SizedBox(height: 16),
                  _RecommendationCard(
                    icon: Icons.water_drop_rounded,
                    title: 'Hydration Goal',
                    description: 'Increase daily water intake to 3L for better kidney function.',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _RecommendationCard(
                    icon: Icons.directions_run_rounded,
                    title: 'Active Recovery',
                    description: 'Light cardio session recommended for tomorrow morning.',
                    color: AppColors.secondary,
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final double progress;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          value,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleMedium?.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            unit,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String day;
  final double value;
  final Color color;

  const _ProgressRow({required this.day, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            day,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.primary.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '${(value * 100).toInt()}%',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleSmall?.color,
          ),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _RecommendationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
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
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
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
      ),
    );
  }
}
