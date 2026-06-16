import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/providers/health_provider.dart';
import 'package:thirdly/widgets/health_add_sheets.dart';
import '../utils/app_colors.dart';

class FamilyMonitoringScreen extends StatelessWidget {
  const FamilyMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = context.watch<AppAuthProvider>().user?.role ?? UserRole.patient;
    final isPatient = role == UserRole.patient;
    final family = isPatient
        ? context.watch<HealthDataProvider>().myFamily
        : context.watch<HealthDataProvider>().watchedPatients;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Family Health Hub', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        actions: [
          if (isPatient)
            IconButton(
              icon: const Icon(Icons.person_add_rounded),
              onPressed: () => HealthAddSheets.showAddFamilyMember(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            isPatient ? 'Your Family Circle' : 'Linked Patients',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isPatient
                ? 'Add family by their signup email. They will see your medicine progress after login.'
                : 'Patients who added your email appear here.',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (family.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPatient
                    ? 'No family members yet. Tap + to add name, relation, and their MedReminder email.'
                    : 'No links yet. Ask the patient to add your registered email in their Family Hub.',
                style: GoogleFonts.poppins(height: 1.5),
              ),
            )
          else
            ...family.map((link) {
              final name = isPatient ? link.memberName : link.memberName;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary),
                  ),
                  title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    isPatient
                        ? '${link.relation} • ${link.memberAge} yrs • ${link.watcherEmail}'
                        : 'Relation: ${link.relation}',
                  ),
                  trailing: Icon(
                    link.isLinked ? Icons.link_rounded : Icons.link_off_rounded,
                    color: link.isLinked ? AppColors.success : AppColors.textLight,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
