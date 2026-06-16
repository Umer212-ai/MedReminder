import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/providers/caregiver_dashboard_provider.dart';
import 'package:thirdly/providers/health_provider.dart';
import 'package:thirdly/screens/role_home_screen.dart';
import 'package:thirdly/screens/register_screen.dart';
import 'package:thirdly/utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AppAuthProvider>();
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final user = auth.user;
        if (user != null) {
          final meds = context.read<MedicineProvider>();
          final health = context.read<HealthDataProvider>();
          meds.setPatientName(user.fullName);
          if (user.role == UserRole.patient) {
            health.listenForPatient(user.uid);
            meds.listenToMedicines(user.uid);
          } else if (user.role == UserRole.caregiver) {
            health.claimLinksIfNeeded(user);
            context.read<CaregiverDashboardProvider>().initialize(user.uid);
          } else {
            health.claimLinksIfNeeded(user);
          }
        }
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const RoleHomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first')),
      );
      return;
    }
    final auth = context.read<AppAuthProvider>();
    final ok = await auth.resetPassword(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Password reset email sent' : (auth.error ?? 'Failed')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<AppAuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleHomeScreen()),
      );
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.displayLarge?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sign in to your MedReminder dashboard',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 56),
                    _buildTextField(
                      context: context,
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'you@example.com',
                      icon: Icons.alternate_email_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email is required';
                        if (!value.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      context: context,
                      controller: _passwordController,
                      label: 'Password',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: AppColors.textLight,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password is required';
                        if (value.length < 6) return 'At least 6 characters required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      height: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: auth.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Social Login',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: auth.isLoading ? null : _googleSignIn,
                      child: _buildSocialButton(context, 'G', Colors.red.withValues(alpha: 0.1)),
                    ),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New to MedReminder? ',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: Text(
                            'Create Account',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: theme.cardTheme.color,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(BuildContext context, String label, Color color) {
    return Center(
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
