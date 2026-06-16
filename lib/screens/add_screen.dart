import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thirdly/models/vital_model.dart';
import 'package:thirdly/screens/add_medicine_screen.dart';
import 'package:thirdly/screens/doctors_screen.dart';
import 'package:thirdly/widgets/health_add_sheets.dart';
import '../utils/app_colors.dart';
import 'dart:ui';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final List<Map<String, dynamic>> _recentActivities = [];
  bool _isSaving = false;

  Future<void> _addRecord(String type, String title, String detail, IconData icon, Color color) async {
    setState(() => _isSaving = true);

    if (mounted) {
      setState(() {
        _recentActivities.insert(0, {
          'title': title,
          'detail': detail,
          'icon': icon,
          'color': color,
          'time': 'Just now',
        });
        _isSaving = false;
      });
      Navigator.pop(context);
      _showSuccessFeedback(title);
    }
  }

  void _showSuccessFeedback(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text('$title added successfully!', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddForm(String title, IconData icon, Color color) {
    final titleController = TextEditingController();
    final detailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'New $title',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildLabel('Record Name / Title'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: titleController,
                    hint: 'e.g., Morning Aspirin',
                    validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('Additional Details'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: detailController,
                    hint: 'e.g., 50mg after breakfast',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () {
                          if (formKey.currentState!.validate()) {
                            setModalState(() {}); // Update local modal state
                            _addRecord(title, titleController.text, detailController.text, icon, color);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                            : Text(
                                'Save Record',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: AppColors.textLight.withValues(alpha: 0.5)),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Add New Record', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
              'Quick Creation',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select what you would like to add to your health profile.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            _AddOptionCard(
              icon: Icons.medication_rounded,
              title: 'Medication',
              description: 'Add a new medication reminder',
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _AddOptionCard(
              icon: Icons.event_rounded,
              title: 'Appointment',
              description: 'Schedule a new appointment',
              color: AppColors.secondary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorsScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _AddOptionCard(
              icon: Icons.family_restroom_rounded,
              title: 'Family Member',
              description: 'Link by their signup email (patient only)',
              color: AppColors.purple,
              onTap: () => HealthAddSheets.showAddFamilyMember(context),
            ),
            const SizedBox(height: 16),
            _AddOptionCard(
              icon: Icons.assessment_rounded,
              title: 'Lab Report',
              description: 'Upload a lab report entry',
              color: AppColors.info,
              onTap: () => HealthAddSheets.showAddLabReport(context),
            ),
            
            if (_recentActivities.isNotEmpty) ...[
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recently Added',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _recentActivities.clear()),
                    child: Text('Clear', style: GoogleFonts.poppins(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _recentActivities.length,
                  itemBuilder: (context, index) {
                    final item = _recentActivities[index];
                    return _RecentItemCard(item: item);
                  },
                ),
              ),
            ],

            const SizedBox(height: 40),
            Text(
              'Quick Metrics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
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
              child: Column(
                children: [
                  _QuickAddRow(
                    icon: Icons.favorite_rounded,
                    label: 'Heart Rate',
                    color: AppColors.error,
                    onTap: () => HealthAddSheets.showAddVital(
                          context,
                          initialType: VitalType.heartRate,
                        ),
                  ),
                  const Divider(height: 32),
                  _QuickAddRow(
                    icon: Icons.bloodtype_rounded,
                    label: 'Blood Pressure',
                    color: AppColors.primary,
                    onTap: () => HealthAddSheets.showAddVital(
                          context,
                          initialType: VitalType.bloodPressure,
                        ),
                  ),
                  const Divider(height: 32),
                  _QuickAddRow(
                    icon: Icons.water_drop_rounded,
                    label: 'Blood Sugar',
                    color: Colors.blue,
                    onTap: () => HealthAddSheets.showAddVital(
                          context,
                          initialType: VitalType.bloodSugar,
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

class _AddOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _AddOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.2 : 0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.1 : 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline_rounded, color: color.withValues(alpha: 0.5), size: 24),
          ],
        ),
      ),
    );
  }
}

class _RecentItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _RecentItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = item['color'] as Color;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item['icon'] as IconData, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            item['title'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            item['detail'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            item['time'] as String,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _QuickAddRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAddRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
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
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.add_rounded, color: theme.textTheme.bodySmall?.color, size: 18),
          ],
        ),
      ),
    );
  }
}
