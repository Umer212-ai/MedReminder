import 'package:intl/intl.dart';
import 'package:thirdly/core/utils/dose_utils.dart';
import 'package:thirdly/models/doctor_model.dart';
import 'package:thirdly/models/family_link_model.dart';
import 'package:thirdly/models/lab_report_model.dart';
import 'package:thirdly/models/medicine_model.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/models/vital_model.dart';

class HealthAssistantContext {
  final UserModel? user;
  final List<MedicineModel> medicines;
  final List<TodayDoseSlot> todaySlots;
  final List<VitalModel> vitals;
  final List<LabReportModel> labReports;
  final List<DoctorModel> doctors;
  final List<FamilyLinkModel> watchedPatients;
  final double weeklyCompliance;

  const HealthAssistantContext({
    this.user,
    this.medicines = const [],
    this.todaySlots = const [],
    this.vitals = const [],
    this.labReports = const [],
    this.doctors = const [],
    this.watchedPatients = const [],
    this.weeklyCompliance = 0,
  });
}

class AiHealthAssistantService {
  String reply(String userMessage, HealthAssistantContext ctx) {
    final msg = userMessage.trim();
    if (msg.isEmpty) {
      return _disclaimer(_greeting(ctx));
    }

    final q = msg.toLowerCase();
    final urdu = _isUrduOrRomanUrdu(q);

    if (_matches(q, ['hello', 'hi', 'hey', 'salam', 'assalam', 'adaab', 'kaise ho', 'kese ho'])) {
      return _disclaimer(_greeting(ctx, urdu: urdu));
    }

    if (_matches(q, ['help', 'madad', 'kya kar sakte', 'what can you', 'commands', 'features'])) {
      return _disclaimer(_help(ctx, urdu: urdu));
    }

    if (ctx.user?.role == UserRole.caregiver || ctx.user?.role == UserRole.familyMember) {
      if (_matches(q, ['patient', 'monitor', 'linked', 'family', 'meray patient', 'mere patient'])) {
        return _disclaimer(_watchedPatients(ctx, urdu: urdu));
      }
    }

    if (_matches(q, ['profile', 'details', 'meri details', 'my info', 'about me', 'mera naam', 'who am i'])) {
      return _disclaimer(_profile(ctx, urdu: urdu));
    }

    if (_matches(q, ['medicine', 'medicines', 'tablet', 'tablets', 'dawa', 'dawai', 'dawaiyan', 'medication', 'drug', 'pills', 'capsule', 'syrup'])) {
      final named = _findMedicineByName(q, ctx.medicines);
      if (named != null) {
        return _disclaimer(_singleMedicine(named, ctx, urdu: urdu));
      }
      return _disclaimer(_allMedicines(ctx, urdu: urdu));
    }

    if (_matches(q, ['today', 'aaj', 'schedule', 'dose', 'doses', 'reminder', 'kab leni', 'kab lu', 'time'])) {
      return _disclaimer(_todayDoses(ctx, urdu: urdu));
    }

    if (_matches(q, ['missed', 'miss', 'bhool', 'reh gayi', 'na li', 'nahi li', 'skip'])) {
      return _disclaimer(_missedDoses(ctx, urdu: urdu));
    }

    if (_matches(q, ['taken', 'li hai', 'complete', 'adherence', 'compliance', 'progress', 'kitni li'])) {
      return _disclaimer(_adherence(ctx, urdu: urdu));
    }

    if (_matches(q, ['blood pressure', 'bp', 'pressure', 'shugar', 'sugar', 'glucose', 'heart', 'pulse', 'bpm', 'weight', 'temperature', 'temp', 'vital', 'vitals'])) {
      return _disclaimer(_vitals(ctx, q, urdu: urdu));
    }

    if (_matches(q, ['lab', 'report', 'test', 'result', 'reports'])) {
      return _disclaimer(_labReports(ctx, urdu: urdu));
    }

    if (_matches(q, ['doctor', 'doctors', 'specialist', 'clinic', 'physician'])) {
      return _disclaimer(_doctors(ctx, urdu: urdu));
    }

    if (_matches(q, ['emergency', 'sos', 'contact', 'emergency contact', 'fones'])) {
      return _disclaimer(_emergency(ctx, urdu: urdu));
    }

    if (_matches(q, ['side effect', 'safe', 'khana', 'food', 'khali pet', 'empty stomach', 'alcohol', 'pregnant'])) {
      return _disclaimer(_generalAdvice(ctx, q, urdu: urdu));
    }

    final named = _findMedicineByName(q, ctx.medicines);
    if (named != null) {
      return _disclaimer(_singleMedicine(named, ctx, urdu: urdu));
    }

    return _disclaimer(_smartFallback(ctx, msg, urdu: urdu));
  }

  bool _isUrduOrRomanUrdu(String q) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(q) ||
        _matches(q, [
          'meri', 'mera', 'mere', 'aaj', 'dawa', 'dawai', 'kab', 'kya', 'hai', 'hen',
          'batao', 'bata', 'kitni', 'kaise', 'kese', 'salam', 'shukriya',
        ]);
  }

  bool _matches(String q, List<String> keywords) {
    return keywords.any((k) => q.contains(k));
  }

  MedicineModel? _findMedicineByName(String q, List<MedicineModel> medicines) {
    for (final med in medicines) {
      final name = med.name.toLowerCase();
      if (name.length >= 3 && q.contains(name)) return med;
    }
    for (final med in medicines) {
      final parts = med.name.toLowerCase().split(RegExp(r'\s+'));
      for (final part in parts) {
        if (part.length >= 4 && q.contains(part)) return med;
      }
    }
    return null;
  }

  VitalModel? _vitalOf(List<VitalModel> vitals, VitalType type) {
    try {
      return vitals.firstWhere((v) => v.type == type);
    } catch (_) {
      return null;
    }
  }

  String _greeting(HealthAssistantContext ctx, {bool urdu = false}) {
    final name = ctx.user?.fullName.split(' ').first ?? 'there';
    if (ctx.user?.role == UserRole.caregiver) {
      final count = ctx.watchedPatients.length;
      if (urdu) {
        return 'Assalam o Alaikum $name! Main aap ka AI Health Assistant hoon. '
            'Aap $count patient${count == 1 ? '' : 's'} monitor kar rahe hain. '
            'Medicines, vitals, ya patient status ke bare mein pooch sakte hain.';
      }
      return 'Hello $name! I\'m your AI Health Assistant. '
          'You\'re monitoring $count patient${count == 1 ? '' : 's'}. '
          'Ask me about patient adherence, vitals, or today\'s medicine schedule.';
    }

    final medCount = ctx.medicines.length;
    final taken = ctx.todaySlots.where((s) => s.taken).length;
    final total = ctx.todaySlots.length;

    if (urdu) {
      return 'Assalam o Alaikum $name! Main aap ki health profile dekh sakta hoon. '
          'Aap ke paas $medCount medicine${medCount == 1 ? '' : 's'} hain. '
          'Aaj $taken/$total doses complete ho chuki hain. '
          'Pooch sakte hain: "Meri medicines?", "Aaj ke doses?", "Blood pressure kya hai?"';
    }
    return 'Hello $name! I can see your health profile in MedReminder. '
        'You have $medCount active medicine${medCount == 1 ? '' : 's'}. '
        'Today you\'ve completed $taken of $total scheduled doses. '
        'Try asking: "What medicines am I taking?", "Today\'s doses", or "My blood pressure".';
  }

  String _help(HealthAssistantContext ctx, {bool urdu = false}) {
    if (urdu) {
      return 'Main yeh cheezen bata sakta hoon:\\n'
          '• Meri medicines / tablets list\\n'
          '• Aaj ke doses aur timing\\n'
          '• Missed ya li hui doses\\n'
          '• Blood pressure, sugar, heart rate\\n'
          '• Lab reports aur doctors\\n'
          '• Aap ki profile details\\n\\n'
          'Example: "Metformin kab leni hai?" ya "Aaj konsi medicine reh gayi?"';
    }
    return 'I can answer using your real MedReminder data:\\n'
        '• Your medicines & tablet schedules\\n'
        '• Today\'s doses (taken, pending, missed)\\n'
        '• Vitals: BP, heart rate, blood sugar\\n'
        '• Lab reports & linked doctors\\n'
        '• Profile & emergency contact\\n\\n'
        'Examples: "What tablets am I taking?" or "Did I miss any dose today?"';
  }

  String _profile(HealthAssistantContext ctx, {bool urdu = false}) {
    final u = ctx.user;
    if (u == null) {
      return urdu ? 'Profile load nahi ho saki. Dobara login karein.' : 'Could not load your profile. Please log in again.';
    }

    final lines = <String>[
      urdu ? '👤 Aap ki Profile' : '👤 Your Profile',
      '${urdu ? 'Naam' : 'Name'}: ${u.fullName}',
      '${urdu ? 'Umar' : 'Age'}: ${u.age} ${urdu ? 'saal' : 'years'}',
      '${urdu ? 'Role' : 'Role'}: ${_roleLabel(u.role, urdu: urdu)}',
      '${urdu ? 'Phone' : 'Phone'}: ${u.phoneNumber.isNotEmpty ? u.phoneNumber : (urdu ? 'Set nahi' : 'Not set')}',
      '${urdu ? 'Emergency' : 'Emergency'}: ${u.emergencyContact.isNotEmpty ? u.emergencyContact : (urdu ? 'Set nahi' : 'Not set')}',
    ];

    if (u.gender != null && u.gender!.isNotEmpty) {
      lines.add('${urdu ? 'Gender' : 'Gender'}: ${u.gender}');
    }
    if (u.medicalSummary != null && u.medicalSummary!.isNotEmpty) {
      lines.add('${urdu ? 'Medical summary' : 'Medical summary'}: ${u.medicalSummary}');
    }

    return lines.join('\\n');
  }

  String _roleLabel(UserRole role, {bool urdu = false}) {
    switch (role) {
      case UserRole.caregiver:
        return urdu ? 'Caregiver' : 'Caregiver';
      case UserRole.familyMember:
        return urdu ? 'Family Member' : 'Family Member';
      case UserRole.patient:
        return urdu ? 'Patient' : 'Patient';
    }
  }

  String _allMedicines(HealthAssistantContext ctx, {bool urdu = false}) {
    if (ctx.medicines.isEmpty) {
      return urdu
          ? 'Abhi koi medicine save nahi hai. Home → Add Medicine se add karein.'
          : 'You don\'t have any medicines saved yet. Add them from Home → My Medicines.';
    }

    final buffer = StringBuffer(
      urdu
          ? '💊 Aap ki ${ctx.medicines.length} medicine${ctx.medicines.length == 1 ? '' : 's'}:\\n'
          : '💊 Your ${ctx.medicines.length} medicine${ctx.medicines.length == 1 ? '' : 's'}:\\n',
    );

    for (var i = 0; i < ctx.medicines.length; i++) {
      final med = ctx.medicines[i];
      buffer.writeln('${i + 1}. ${med.name} (${med.dosage})');
      buffer.writeln('   ${urdu ? 'Qism' : 'Type'}: ${med.medicineType}');
      buffer.writeln('   ${urdu ? 'Time' : 'Schedule'}: ${med.scheduleTimes.join(', ')}');
      if (med.doctorName.isNotEmpty) {
        buffer.writeln('   ${urdu ? 'Doctor' : 'Doctor'}: ${med.doctorName}');
      }
      if (med.notes.isNotEmpty) {
        buffer.writeln('   ${urdu ? 'Note' : 'Note'}: ${med.notes}');
      }
      buffer.writeln('');
    }

    return buffer.toString().trim();
  }

  String _singleMedicine(MedicineModel med, HealthAssistantContext ctx, {bool urdu = false}) {
    final todayForMed = ctx.todaySlots.where((s) => s.medicine.id == med.id).toList();
    final taken = todayForMed.where((s) => s.taken).length;
    final missed = todayForMed.where((s) => s.missed && !s.taken).length;
    final pending = todayForMed.where((s) => !s.taken && !s.missed).length;

    final buffer = StringBuffer(
      urdu ? '💊 ${med.name} – Details\\n' : '💊 ${med.name} – Details\\n',
    );
    buffer.writeln('${urdu ? 'Dosage' : 'Dosage'}: ${med.dosage}');
    buffer.writeln('${urdu ? 'Type' : 'Type'}: ${med.medicineType}');
    buffer.writeln('${urdu ? 'Quantity' : 'Quantity'}: ${med.quantity}');
    buffer.writeln('${urdu ? 'Schedule' : 'Schedule'}: ${med.scheduleTimes.join(', ')}');
    buffer.writeln(
      '${urdu ? 'Start' : 'Start'}: ${DateFormat.yMMMd().format(med.startDate)}',
    );
    if (med.endDate != null) {
      buffer.writeln('${urdu ? 'End' : 'End'}: ${DateFormat.yMMMd().format(med.endDate!)}');
    }
    if (med.doctorName.isNotEmpty) {
      buffer.writeln('${urdu ? 'Prescribed by' : 'Prescribed by'}: ${med.doctorName}');
    }
    if (med.notes.isNotEmpty) {
      buffer.writeln('${urdu ? 'Instructions' : 'Instructions'}: ${med.notes}');
    }

    if (todayForMed.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln(urdu ? '📅 Aaj ka status:' : '📅 Today\'s status:');
      buffer.writeln('${urdu ? 'Li' : 'Taken'}: $taken | ${urdu ? 'Pending' : 'Pending'}: $pending | ${urdu ? 'Missed' : 'Missed'}: $missed');
      for (final slot in todayForMed) {
        final status = slot.taken
            ? (urdu ? '✅ Li' : '✅ Taken')
            : slot.missed
                ? (urdu ? '❌ Missed' : '❌ Missed')
                : (urdu ? '⏳ Pending' : '⏳ Pending');
        buffer.writeln('   ${slot.scheduleTime} – $status');
      }
    }

    return buffer.toString().trim();
  }

  String _todayDoses(HealthAssistantContext ctx, {bool urdu = false}) {
    if (ctx.todaySlots.isEmpty) {
      return urdu
          ? 'Aaj koi dose schedule nahi hai. Medicines add karein ya check karein ke schedule times set hain.'
          : 'No doses scheduled for today. Add medicines or check that schedule times are set.';
    }

    final buffer = StringBuffer(
      urdu ? '📅 Aaj ke doses (${ctx.todaySlots.length}):\\n' : '📅 Today\'s doses (${ctx.todaySlots.length}):\\n',
    );

    for (final slot in ctx.todaySlots) {
      final status = slot.taken
          ? (urdu ? '✅ Li' : '✅ Taken')
          : slot.missed
              ? (urdu ? '❌ Missed' : '❌ Missed')
              : (urdu ? '⏳ Abhi leni hai' : '⏳ Pending');
      buffer.writeln('• ${slot.scheduleTime} – ${slot.medicine.name} (${slot.medicine.dosage}) – $status');
    }

    return buffer.toString().trim();
  }

  String _missedDoses(HealthAssistantContext ctx, {bool urdu = false}) {
    final missed = ctx.todaySlots.where((s) => s.missed && !s.taken).toList();
    if (missed.isEmpty) {
      return urdu
          ? '🎉 Aaj koi dose miss nahi hui. Bohat acha!'
          : '🎉 Great news — you haven\'t missed any doses today!';
    }

    final buffer = StringBuffer(
      urdu
          ? '⚠️ Aaj ${missed.length} dose${missed.length == 1 ? '' : 's'} miss hui:\\n'
          : '⚠️ You missed ${missed.length} dose${missed.length == 1 ? '' : 's'} today:\\n',
    );
    for (final slot in missed) {
      buffer.writeln('• ${slot.medicine.name} – ${slot.scheduleTime} (${slot.medicine.dosage})');
    }
    buffer.writeln('');
    buffer.writeln(
      urdu
          ? 'Doctor se consult karein agar doses bar bar miss ho rahi hain.'
          : 'If doses are often missed, speak with your doctor about adjusting your schedule.',
    );
    return buffer.toString().trim();
  }

  String _adherence(HealthAssistantContext ctx, {bool urdu = false}) {
    final taken = ctx.todaySlots.where((s) => s.taken).length;
    final total = ctx.todaySlots.length;
    final pct = total == 0 ? 0 : ((taken / total) * 100).round();
    final weekly = ctx.weeklyCompliance.round();

    if (urdu) {
      return '📊 Medicine Adherence\\n'
          'Aaj: $taken/$total doses ($pct%)\\n'
          'Is hafte ka average: $weekly%\\n\\n'
          '${pct >= 80 ? 'Bohat acha! Schedule par hain.' : 'Thori improvement ki zaroorat hai — reminders on rakhein.'}';
    }
    return '📊 Medicine Adherence\\n'
        'Today: $taken/$total doses ($pct%)\\n'
        'Weekly average: $weekly%\\n\\n'
        '${pct >= 80 ? 'Great job staying on track!' : 'Try enabling reminders to improve consistency.'}';
  }

  String _vitals(HealthAssistantContext ctx, String q, {bool urdu = false}) {
    if (ctx.vitals.isEmpty) {
      return urdu
          ? 'Abhi koi vital record nahi hai. Medical tab se BP, sugar, heart rate add karein.'
          : 'No vitals recorded yet. Add readings from the Medical tab.';
    }

    final showAll = _matches(q, ['vital', 'vitals', 'health']);
    final types = <VitalType>[];

    if (showAll ||
        _matches(q, ['bp', 'blood pressure', 'pressure'])) {
      types.add(VitalType.bloodPressure);
    }
    if (showAll || _matches(q, ['heart', 'pulse', 'bpm'])) {
      types.add(VitalType.heartRate);
    }
    if (showAll || _matches(q, ['sugar', 'glucose', 'shugar'])) {
      types.add(VitalType.bloodSugar);
    }
    if (showAll || _matches(q, ['weight', 'wazan'])) {
      types.add(VitalType.weight);
    }
    if (showAll || _matches(q, ['temp', 'temperature', 'fever'])) {
      types.add(VitalType.temperature);
    }

    if (types.isEmpty) {
      types.addAll(VitalType.values);
    }

    final lines = <String>[urdu ? '🩺 Aap ke latest vitals:' : '🩺 Your latest vitals:'];
    for (final type in types) {
      final vital = _vitalOf(ctx.vitals, type);
      final label = vital?.title ?? type.name;
      if (vital != null) {
        lines.add(
          '• $label: ${vital.value} ${vital.unit} (${DateFormat.MMMd().add_jm().format(vital.createdAt)})',
        );
        if (type == VitalType.bloodPressure) {
          final insight = _bpInsight(vital.value, urdu: urdu);
          if (insight.isNotEmpty) lines.add(insight);
        }
      } else {
        lines.add('• $label: ${urdu ? 'Record nahi' : 'Not recorded'}');
      }
    }

    return lines.join('\n');
  }

  String _bpInsight(String value, {bool urdu = false}) {
    final parts = value.split('/');
    if (parts.length != 2) return '';
    final sys = int.tryParse(parts[0].trim());
    final dia = int.tryParse(parts[1].trim());
    if (sys == null || dia == null) return '';

    if (sys > 130 || dia > 80) {
      return urdu
          ? '  ⚠️ BP thori high lag rahi hai — doctor se consult karein.'
          : '  ⚠️ BP appears elevated — please consult your doctor.';
    }
    if (sys < 90 || dia < 60) {
      return urdu
          ? '  ⚠️ BP low lag rahi hai — agar weakness ho to doctor se baat karein.'
          : '  ⚠️ BP appears low — contact your doctor if you feel unwell.';
    }
    return urdu ? '  ✅ BP normal range mein lag rahi hai.' : '  ✅ BP appears within normal range.';
  }

  String _labReports(HealthAssistantContext ctx, {bool urdu = false}) {
    if (ctx.labReports.isEmpty) {
      return urdu
          ? 'Koi lab report nahi mili. Medical tab se add kar sakte hain.'
          : 'No lab reports found. You can add them from the Medical tab.';
    }

    final buffer = StringBuffer(urdu ? '🧪 Lab Reports:\\n' : '🧪 Lab Reports:\\n');
    for (final r in ctx.labReports.take(8)) {
      buffer.writeln(
        '• ${r.testName} – ${r.status} (${DateFormat.yMMMd().format(r.testDate)})',
      );
    }
    return buffer.toString().trim();
  }

  String _doctors(HealthAssistantContext ctx, {bool urdu = false}) {
    if (ctx.doctors.isEmpty) {
      return urdu
          ? 'Koi doctor linked nahi hai. Doctors screen se add karein.'
          : 'No doctors linked yet. Add them from the Doctors screen.';
    }

    final buffer = StringBuffer(urdu ? '👨‍⚕️ Aap ke doctors:\\n' : '👨‍⚕️ Your doctors:\\n');
    for (final d in ctx.doctors) {
      buffer.writeln('• ${d.name} – ${d.specialty}');
      if (d.clinic.isNotEmpty) buffer.writeln('  ${d.clinic}');
      if (d.phone.isNotEmpty) buffer.writeln('  📞 ${d.phone}');
    }
    return buffer.toString().trim();
  }

  String _emergency(HealthAssistantContext ctx, {bool urdu = false}) {
    final contact = ctx.user?.emergencyContact ?? '';
    if (contact.isEmpty) {
      return urdu
          ? 'Emergency contact set nahi hai. Settings → Edit Profile se add karein.'
          : 'No emergency contact set. Add one in Settings → Edit Profile.';
    }
    return urdu
        ? '🚨 Emergency Contact: $contact\\nSerious situation mein Emergency tab bhi use karein.'
        : '🚨 Emergency Contact: $contact\\nFor urgent situations, also use the Emergency tab in the app.';
  }

  String _watchedPatients(HealthAssistantContext ctx, {bool urdu = false}) {
    if (ctx.watchedPatients.isEmpty) {
      return urdu
          ? 'Abhi koi patient linked nahi. Patient ko Family Hub se aap ka email add karwana hoga.'
          : 'No linked patients yet. Ask patients to add your email in Family Hub.';
    }

    final buffer = StringBuffer(
      urdu
          ? '👥 Linked Patients (${ctx.watchedPatients.length}):\\n'
          : '👥 Linked Patients (${ctx.watchedPatients.length}):\\n',
    );
    for (final p in ctx.watchedPatients) {
      buffer.writeln(
        '• ${p.patientName} – ${p.todayTaken}/${p.todayTotal} doses today (${p.relation})',
      );
    }
    return buffer.toString().trim();
  }

  String _generalAdvice(HealthAssistantContext ctx, String q, {bool urdu = false}) {
    final med = _findMedicineByName(q, ctx.medicines);
    final medName = med?.name ?? (urdu ? 'medicine' : 'your medicine');

    if (urdu) {
      return '💡 $medName ke bare mein general advice:\\n'
          '• Hamesha doctor ki di hui dosage follow karein\\n'
          '• Khali pet ya khana ke sath — doctor ke mutabiq\\n'
          '• Side effects hon to foran doctor se rabta karein\\n\\n'
          'Main exact medical advice nahi de sakta — yeh sirf general guidance hai.';
    }
    return '💡 General guidance about $medName:\\n'
        '• Always follow your prescribed dosage\\n'
        '• Take with or without food as your doctor advised\\n'
        '• Report any side effects to your doctor promptly\\n\\n'
        'I cannot give exact medical advice — please confirm with your healthcare provider.';
  }

  String _smartFallback(HealthAssistantContext ctx, String original, {bool urdu = false}) {
    final summary = <String>[];
    if (ctx.medicines.isNotEmpty) {
      summary.add(urdu
          ? '${ctx.medicines.length} medicines'
          : '${ctx.medicines.length} medicines');
    }
    if (ctx.todaySlots.isNotEmpty) {
      final taken = ctx.todaySlots.where((s) => s.taken).length;
      summary.add(urdu
          ? 'aaj $taken/${ctx.todaySlots.length} doses'
          : '$taken/${ctx.todaySlots.length} doses today');
    }
    if (ctx.vitals.isNotEmpty) {
      summary.add(urdu ? '${ctx.vitals.length} vitals' : '${ctx.vitals.length} vitals logged');
    }

    final dataHint = summary.isEmpty
        ? (urdu ? 'Abhi thora data kam hai — medicines aur vitals add karein.' : 'Limited data available — add medicines and vitals for better answers.')
        : (urdu ? 'Aap ke profile mein: ${summary.join(', ')}.' : 'In your profile I see: ${summary.join(', ')}.');

    if (urdu) {
      return 'Main "$original" samajh gaya lekin exact jawab nahi de sakta.\\n\\n'
          '$dataHint\\n\\n'
          'Try karein:\\n'
          '• "Meri medicines batao"\\n'
          '• "Aaj ke doses"\\n'
          '• "Blood pressure kya hai?"';
    }
    return 'I understood "$original" but need a clearer health question.\\n\\n'
        '$dataHint\\n\\n'
        'Try asking:\\n'
        '• "What medicines am I taking?"\\n'
        '• "Today\'s doses"\\n'
        '• "What is my blood pressure?"';
  }

  String _disclaimer(String body) {
    return _normalize(
      '$body\n\n⚕️ AI guidance only — not a substitute for professional medical advice.',
    );
  }

  String _normalize(String text) => text.replaceAll('\\n', '\n');
}
