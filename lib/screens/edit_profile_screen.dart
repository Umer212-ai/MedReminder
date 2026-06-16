import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/utils/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emergencyController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _clinicController;
  late final TextEditingController _timingController;
  late UserRole _role;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().user!;
    _nameController = TextEditingController(text: user.fullName);
    _ageController = TextEditingController(text: user.age.toString());
    _phoneController = TextEditingController(text: user.phoneNumber);
    _emergencyController = TextEditingController(text: user.emergencyContact);
    _specialtyController = TextEditingController(text: user.specialty ?? '');
    _clinicController = TextEditingController(text: user.clinicName ?? '');
    _timingController = TextEditingController(text: user.availableTiming ?? '');
    _role = user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emergencyController.dispose();
    _specialtyController.dispose();
    _clinicController.dispose();
    _timingController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AppAuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final medicineProvider = context.read<MedicineProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);
    final updated = user.copyWith(
      fullName: _nameController.text.trim(),
      age: int.tryParse(_ageController.text) ?? user.age,
      phoneNumber: _phoneController.text.trim(),
      emergencyContact: _emergencyController.text.trim(),
      role: _role,
      specialty: _role == UserRole.caregiver ? _specialtyController.text.trim() : null,
      clinicName: _role == UserRole.caregiver ? _clinicController.text.trim() : null,
      availableTiming: _role == UserRole.caregiver ? _timingController.text.trim() : null,
    );
    await auth.updateUserProfile(updated);
    medicineProvider.setPatientName(updated.fullName);
    setState(() => _saving = false);
    navigator.pop();
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name *'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age *'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Invalid age';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number *'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyController,
              decoration: const InputDecoration(labelText: 'Emergency Contact *'),
              validator: (v) => _role != UserRole.caregiver && (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: UserRole.patient, child: Text('Patient')),
                DropdownMenuItem(value: UserRole.familyMember, child: Text('Family Member')),
                DropdownMenuItem(value: UserRole.caregiver, child: Text('Caregiver')),
              ],
              onChanged: (v) => setState(() => _role = v ?? UserRole.patient),
            ),
            if (_role == UserRole.caregiver) ...[
              const SizedBox(height: 24),
              Text(
                'Caregiver Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Medical Specialty / Role *',
                  prefixIcon: Icon(Icons.medical_services_outlined, color: AppColors.primary),
                ),
                validator: (v) => _role == UserRole.caregiver && (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clinicController,
                decoration: const InputDecoration(
                  labelText: 'Clinic / Hospital Name *',
                  prefixIcon: Icon(Icons.local_hospital_outlined, color: AppColors.primary),
                ),
                validator: (v) => _role == UserRole.caregiver && (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timingController,
                decoration: const InputDecoration(
                  labelText: 'Available Timing *',
                  prefixIcon: Icon(Icons.access_time_rounded, color: AppColors.primary),
                ),
                validator: (v) => _role == UserRole.caregiver && (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
