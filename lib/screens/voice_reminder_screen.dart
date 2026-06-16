import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class VoiceReminderScreen extends StatefulWidget {
  const VoiceReminderScreen({super.key});

  @override
  State<VoiceReminderScreen> createState() => _VoiceReminderScreenState();
}

class _VoiceReminderScreenState extends State<VoiceReminderScreen> {
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Voice Reminders', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
              'Smart Voice Reminders',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.displayLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set voice reminders for medications and appointments using AI recognition.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isRecording = !_isRecording),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: _isRecording 
                          ? LinearGradient(colors: [AppColors.error, AppColors.error.withValues(alpha: 0.7)])
                          : AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording ? AppColors.error : AppColors.primary).withValues(alpha: 0.4),
                            blurRadius: _isRecording ? 40 : 20,
                            spreadRadius: _isRecording ? 10 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isRecording ? 'Listening...' : 'Tap to Record',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isRecording
                        ? 'We are capturing your reminder'
                        : 'Record a new health reminder',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isRecording = !_isRecording),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording ? AppColors.error : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isRecording ? 'Stop Recording' : 'Start New Recording',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Reminders',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 16),
            _ReminderCard(
              title: 'Morning Medication',
              time: '8:00 AM',
              type: 'Medication',
              icon: Icons.medication_rounded,
              color: AppColors.primary,
              isActive: true,
            ),
            const SizedBox(height: 16),
            _ReminderCard(
              title: 'Doctor Appointment',
              time: '2:00 PM',
              type: 'Appointment',
              icon: Icons.event_rounded,
              color: AppColors.secondary,
              isActive: true,
            ),
            const SizedBox(height: 32),
            Text(
              'Recent Recordings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _RecordingCard(
              title: 'Weekly Checkup Note',
              duration: '0:45',
              date: 'Today, 10:30 AM',
            ),
            const SizedBox(height: 12),
            _RecordingCard(
              title: 'Medication Side Effects',
              duration: '1:20',
              date: 'Yesterday, 4:15 PM',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final String title;
  final String time;
  final String type;
  final IconData icon;
  final Color color;
  final bool isActive;

  const _ReminderCard({
    required this.title,
    required this.time,
    required this.type,
    required this.icon,
    required this.color,
    required this.isActive,
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
              borderRadius: BorderRadius.circular(20),
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
                Text(
                  type,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch.adaptive(
                value: isActive,
                onChanged: (v) {},
                activeColor: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordingCard extends StatelessWidget {
  final String title;
  final String duration;
  final String date;

  const _RecordingCard({
    required this.title,
    required this.duration,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
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
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            duration,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
