import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  bool _largeText = false;
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _screenReader = false;
  double _textScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Accessibility', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
              'User Experience',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.displayLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Customize the application interface to match your specific accessibility needs.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 32),
            _AccessibilitySection(
              title: 'Visual Display',
              items: [
                _ToggleItem(
                  icon: Icons.text_fields_rounded,
                  label: 'Enhanced Legibility',
                  subtitle: 'Increase text weight for better readability',
                  value: _largeText,
                  onChanged: (value) => setState(() => _largeText = value),
                ),
                _ToggleItem(
                  icon: Icons.contrast_rounded,
                  label: 'High Contrast Mode',
                  subtitle: 'Optimized visibility for visual impairments',
                  value: _highContrast,
                  onChanged: (value) => setState(() => _highContrast = value),
                ),
                _SliderItem(
                  icon: Icons.format_size_rounded,
                  label: 'Interface Scaling',
                  subtitle: 'Adjust overall text and UI element scale',
                  value: _textScale,
                  onChanged: (value) => setState(() => _textScale = value),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _AccessibilitySection(
              title: 'Motion & Interactions',
              items: [
                _ToggleItem(
                  icon: Icons.animation_rounded,
                  label: 'Reduce Visual Motion',
                  subtitle: 'Simplify animations and transitions',
                  value: _reduceMotion,
                  onChanged: (value) => setState(() => _reduceMotion = value),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _AccessibilitySection(
              title: 'Audio Assistance',
              items: [
                _ToggleItem(
                  icon: Icons.volume_up_rounded,
                  label: 'Voice Guidance',
                  subtitle: 'Enable audio feedback for all interactions',
                  value: _screenReader,
                  onChanged: (value) => setState(() => _screenReader = value),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _AccessibilitySection(
              title: 'Priority Controls',
              items: [
                _ActionItem(
                  icon: Icons.emergency_rounded,
                  label: 'Emergency SOS Shortcut',
                  subtitle: 'Instant access to critical services',
                  onTap: () {},
                  color: AppColors.error,
                ),
                _ActionItem(
                  icon: Icons.mic_rounded,
                  label: 'Voice Navigation',
                  subtitle: 'Control the app using voice commands',
                  onTap: () {},
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'These settings help make the app more accessible for everyone, ensuring a seamless healthcare experience.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color,
                        height: 1.5,
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

class _AccessibilitySection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _AccessibilitySection({
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

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SliderItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final double value;
  final ValueChanged<double> onChanged;

  const _SliderItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withValues(alpha: 0.1),
            min: 0.5,
            max: 1.5,
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.textTheme.bodySmall?.color, size: 20),
          ],
        ),
      ),
    );
  }
}
