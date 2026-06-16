import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import 'package:thirdly/widgets/auth_wrapper.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: 'Healthcare at Your Fingertips',
      description: 'Access medical records, appointments, and health reports all in one premium experience.',
      icon: Icons.health_and_safety_rounded,
      color: AppColors.primary,
    ),
    OnboardingData(
      title: 'Family Monitoring',
      description: 'Keep track of your family members\' health and wellness with real-time proactive updates.',
      icon: Icons.family_restroom_rounded,
      color: AppColors.secondary,
    ),
    OnboardingData(
      title: 'Emergency Assistance',
      description: 'Get instant help in emergencies with one-tap emergency contacts and high-priority alerts.',
      icon: Icons.emergency_rounded,
      color: AppColors.error,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      markOnboardingComplete();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(data: _onboardingData[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        height: 6,
                        width: _currentPage == index ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.textLight.withValues(alpha: isDark ? 0.2 : 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                  Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        _currentPage == _onboardingData.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      'Skip introduction',
                      style: GoogleFonts.poppins(
                        color: theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: isDark ? 0.05 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: isDark ? 0.1 : 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: data.color.withValues(alpha: isDark ? 0.1 : 0.05),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  data.icon,
                  size: 100,
                  color: data.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
          Text(
            data.title,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.displayLarge?.color,
              height: 1.1,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            data.description,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: theme.textTheme.bodyMedium?.color,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
