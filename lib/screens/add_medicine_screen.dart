import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/utils/app_colors.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  final _doctorController = TextEditingController();
  final _scheduleController = TextEditingController(text: '08:00');
  final _imageUrlController = TextEditingController();

  String _medicineType = 'tablet';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final List<String> _scheduleTimes = [];

  static const _types = ['tablet', 'capsule', 'syrup', 'injection', 'drops', 'inhaler'];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _doctorController.dispose();
    _scheduleController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _scheduleController.text = formatted);
    }
  }

  void _addScheduleTime() {
    final value = _scheduleController.text.trim();
    if (value.isEmpty) return;
    if (!_scheduleTimes.contains(value)) {
      setState(() {
        _scheduleTimes.add(value);
        _scheduleController.clear();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduleTimes.isEmpty) {
      _addScheduleTime();
      if (_scheduleTimes.isEmpty && _scheduleController.text.trim().isNotEmpty) {
        _scheduleTimes.add(_scheduleController.text.trim());
      }
    }
    if (_scheduleTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one schedule time')),
      );
      return;
    }

    final uid = context.read<AppAuthProvider>().uid;
    if (uid == null) return;

    final provider = context.read<MedicineProvider>();
    final ok = await provider.addMedicine(
      userId: uid,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      medicineType: _medicineType,
      quantity: int.tryParse(_quantityController.text) ?? 1,
      scheduleTimes: List.from(_scheduleTimes),
      startDate: _startDate,
      endDate: _endDate,
      notes: _notesController.text.trim(),
      doctorName: _doctorController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      patientName: context.read<AppAuthProvider>().user?.fullName ?? 'Patient',
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_nameController.text} saved. Reminder 1 min before each dose.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loading = context.watch<MedicineProvider>().isLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Add Medicine', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _label('Medicine Name *'),
            _field(_nameController, 'e.g. Metformin', validator: _required),
            _label('Dosage *'),
            _field(_dosageController, 'e.g. 500mg', validator: _required),
            _label('Medicine Type'),
            DropdownButtonFormField<String>(
              value: _medicineType,
              decoration: _inputDecoration(),
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _medicineType = v ?? 'tablet'),
            ),
            const SizedBox(height: 16),
            _label('Quantity'),
            _field(_quantityController, '1', keyboard: TextInputType.number),
            _label('Doctor Name'),
            _field(_doctorController, 'Dr. name (optional)'),
            _label('Start Date'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(DateFormat.yMMMd().format(_startDate)),
              trailing: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
              onTap: () => _pickDate(isStart: true),
            ),
            _label('End Date (optional)'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_endDate == null ? 'No end date' : DateFormat.yMMMd().format(_endDate!)),
              trailing: const Icon(Icons.event_rounded, color: AppColors.primary),
              onTap: () => _pickDate(isStart: false),
            ),
            _label('Schedule Times * (reminder 1 min before)'),
            Row(
              children: [
                Expanded(
                  child: _field(_scheduleController, 'HH:mm e.g. 08:00'),
                ),
                IconButton(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time_rounded, color: AppColors.primary),
                ),
                IconButton(
                  onPressed: _addScheduleTime,
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.secondary),
                ),
              ],
            ),
            if (_scheduleTimes.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _scheduleTimes
                    .map((t) => Chip(
                          label: Text(t),
                          onDeleted: () => setState(() => _scheduleTimes.remove(t)),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 16),
            _label('Notes'),
            _field(_notesController, 'After breakfast, with water...', maxLines: 3),
            _label('Image URL (optional)'),
            _field(_imageUrlController, 'https://...'),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Save & Schedule Reminders',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 8),
        child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  InputDecoration _inputDecoration() => InputDecoration(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      );

  Widget _field(
    TextEditingController controller,
    String hint, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: _inputDecoration().copyWith(hintText: hint),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}
