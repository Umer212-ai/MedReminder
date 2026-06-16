import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thirdly/firebase_options.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/providers/caregiver_dashboard_provider.dart';
import 'package:thirdly/providers/health_provider.dart';
import 'package:thirdly/services/auth_service.dart';
import 'package:thirdly/services/emergency_service.dart';
import 'package:thirdly/services/medicine_service.dart';
import 'package:thirdly/services/notification_helper_service.dart';
import 'package:thirdly/services/notification_service.dart';
import 'package:thirdly/services/prescription_service.dart';
import 'package:thirdly/utils/app_theme.dart';
import 'package:thirdly/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    debugPrint('Firebase init failed: $e\n$stack');
  }

  runApp(const MedReminderApp());
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class MedReminderApp extends StatelessWidget {
  const MedReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NotificationHelperService>(create: (_) => NotificationHelperService()),
        Provider<AuthService>(create: (ctx) => AuthService(
          notificationHelper: ctx.read<NotificationHelperService>(),
        )),
        Provider<MedicineService>(create: (_) => MedicineService()),
        Provider<PrescriptionService>(create: (_) => PrescriptionService()),
        Provider<EmergencyService>(create: (ctx) => EmergencyService(
          notificationHelper: ctx.read<NotificationHelperService>(),
        )),
        Provider<NotificationService>(create: (_) => NotificationService()),
        ChangeNotifierProvider<AppAuthProvider>(
          create: (ctx) => AppAuthProvider(
            authService: ctx.read<AuthService>(),
            notificationService: ctx.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProvider<MedicineProvider>(
          create: (ctx) => MedicineProvider(
            scheduler: ctx.read<NotificationService>().scheduler,
          ),
        ),
        ChangeNotifierProvider<HealthDataProvider>(
          create: (_) => HealthDataProvider(),
        ),
        ChangeNotifierProvider<CaregiverDashboardProvider>(
          create: (_) => CaregiverDashboardProvider(),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, ThemeMode currentMode, __) {
          return MaterialApp(
            title: 'MedReminder',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
