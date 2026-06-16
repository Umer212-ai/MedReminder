import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/utils/app_colors.dart';

class CaregiverProfileEditScreen extends StatefulWidget {
  const CaregiverProfileEditScreen({super.key});

  @override
  State<CaregiverProfileEditScreen> createState() => _CaregiverProfileEditScreenState();
}

class _CaregiverProfileEditScreenState extends State<CaregiverProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _clinicController;
  late final TextEditingController _locationController;
  late final TextEditingController _qualificationController;
  late final TextEditingController _experienceController;
  late final TextEditingController _bioController;

  bool _saving = false;

  final List<String> _specialtySuggestions = [
    'General Physician',
    'Cardiology Specialist',
    'Geriatric Caregiver',
    'Pediatric Care',
    'Neurologist',
    'Physical Therapist',
  ];

  final List<String> _qualificationSuggestions = [
    'MBBS',
    'MD',
    'RN (Registered Nurse)',
    'LPN (Licensed Practical Nurse)',
    'CNA (Certified Nursing Assistant)',
    'BSc Nursing',
    'MSc Nursing',
    'Physiotherapy Degree',
    'Other Certification',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _specialtyController = TextEditingController(text: user?.specialty ?? '');
    _clinicController = TextEditingController(text: user?.clinicName ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
    _qualificationController = TextEditingController(text: user?.qualification ?? '');
    _experienceController = TextEditingController(text: user?.experience ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _clinicController.dispose();
    _locationController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AppAuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);

    try {
      final updated = user.copyWith(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        specialty: _specialtyController.text.trim(),
        clinicName: _clinicController.text.trim(),
        location: _locationController.text.trim(),
        qualification: _qualificationController.text.trim(),
        experience: _experienceController.text.trim(),
        bio: _bioController.text.trim(),
      );

      await auth.updateUserProfile(updated);
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Full Name
                    _buildTextField(
                      label: 'Full Name *',
                      hint: 'Dr. John Doe',
                      icon: Icons.person_outline_rounded,
                      controller: _nameController,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Phone Number
                    _buildTextField(
                      label: 'Phone Number *',
                      hint: '+1 234 567 890',
                      icon: Icons.phone_android_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Phone is required'
                              : null,
                    ),
                    const SizedBox(height: 20),

                    // Specialty
                    _buildTextField(
                      label: 'Medical Specialty / Role *',
                      hint: 'e.g. Geriatric Caregiver, Pediatric Nurse',
                      icon: Icons.medical_services_outlined,
                      controller: _specialtyController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Specialty is required'
                              : null,
                    ),
                    const SizedBox(height: 8),
                    _buildSuggestionsList(
                      suggestions: _specialtySuggestions,
                      controller: _specialtyController,
                    ),
                    const SizedBox(height: 20),

                    // Clinic Name
                    _buildTextField(
                      label: 'Clinic / Hospital / Agency Name *',
                      hint: 'e.g. City Health Clinic, Private Practice',
                      icon: Icons.local_hospital_outlined,
                      controller: _clinicController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Clinic name is required'
                              : null,
                    ),
                    const SizedBox(height: 20),

                    // Location
                    _buildTextField(
                      label: 'Location / City *',
                      hint: 'e.g. New York, NY',
                      icon: Icons.location_on_outlined,
                      controller: _locationController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Location is required'
                              : null,
                    ),
                    const SizedBox(height: 20),

                    // Qualification
                    _buildTextField(
                      label: 'Qualification / Degree *',
                      hint: 'e.g. MBBS, RN, BSc Nursing',
                      icon: Icons.school_outlined,
                      controller: _qualificationController,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Qualification is required'
                              : null,
                    ),
                    const SizedBox(height: 8),
                    _buildSuggestionsList(
                      suggestions: _qualificationSuggestions,
                      controller: _qualificationController,
                    ),
                    const SizedBox(height: 20),

                    // Experience
                    _buildTextField(
                      label: 'Experience (years) *',
                      hint: 'e.g. 5',
                      icon: Icons.work_outline,
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Experience is required';
                        }
                        final val = int.tryParse(value.trim());
                        if (val == null || val < 0) {
                          return 'Invalid experience';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Bio
                    _buildTextField(
                      label: 'Bio / About (optional)',
                      hint: 'Tell patients about yourself and your approach to care',
                      icon: Icons.description_outlined,
                      controller: _bioController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _saving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Save Profile Changes',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: theme.cardTheme.color,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.textLight.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.textLight.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsList({
    required List<String> suggestions,
    required TextEditingController controller,
  }) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final text = suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              onPressed: () {
                setState(() {
                  controller.text = text;
                });
              },
            ),
          );
        },
      ),
    );
  }
}
