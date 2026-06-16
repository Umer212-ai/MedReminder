import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/providers/caregiver_dashboard_provider.dart';
import 'package:thirdly/providers/health_provider.dart';
import 'package:thirdly/screens/role_home_screen.dart';
import 'package:thirdly/utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyController = TextEditingController();
  bool _obscurePassword = true;
  UserRole _role = UserRole.patient;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AppAuthProvider>();
    final success = await auth.register(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      age: int.tryParse(_ageController.text) ?? 0,
      phoneNumber: _phoneController.text.trim(),
      emergencyContact: _emergencyController.text.trim(),
      role: _role,
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
        MaterialPageRoute(builder: (_) => const RoleHomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join MedReminder for smart care',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _field(_nameController, 'Full Name', Icons.person_outline),
                const SizedBox(height: 16),
                _field(_emailController, 'Email', Icons.email_outlined,
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _field(_passwordController, 'Password', Icons.lock_outline,
                    obscure: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    )),
                const SizedBox(height: 16),
                _field(_ageController, 'Age', Icons.cake_outlined,
                    keyboard: TextInputType.number),
                const SizedBox(height: 16),
                _field(_phoneController, 'Phone Number', Icons.phone_outlined,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 16),
                _field(_emergencyController, 'Emergency Contact', Icons.emergency_outlined,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 20),
                Text('Role', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserRole>(
                  value: _role,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.cardTheme.color,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: const [
                    DropdownMenuItem(value: UserRole.patient, child: Text('Patient')),
                    DropdownMenuItem(value: UserRole.familyMember, child: Text('Family Member')),
                    DropdownMenuItem(value: UserRole.caregiver, child: Text('Caregiver')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? UserRole.patient),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Register', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffix,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return '$label is required';
        if (label == 'Email' && !v.contains('@')) return 'Enter a valid email';
        if (label == 'Password' && v.length < 6) return 'At least 6 characters';
        return null;
      },
    );
  }
}
