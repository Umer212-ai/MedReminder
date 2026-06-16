import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirdly/providers/app_providers.dart';
import 'package:thirdly/providers/caregiver_dashboard_provider.dart';
import 'package:thirdly/models/user_model.dart';
import 'package:thirdly/providers/health_provider.dart';
import 'package:thirdly/screens/role_home_screen.dart';
import 'package:thirdly/screens/login_screen.dart';
import 'package:thirdly/screens/onboarding_screen.dart';
import 'package:thirdly/utils/app_colors.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checkingOnboarding = true;
  bool _onboardingComplete = false;
  String? _boundUid;

  @override
  void initState() {
    super.initState();
    _loadOnboardingFlag();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AppAuthProvider>().init();
      if (mounted) {
        final user = context.read<AppAuthProvider>().user;
        if (user != null) _bindUserData(user);
      }
    });
  }

  void _bindUserData(UserModel user) {
    if (_boundUid == user.uid) return;
    _boundUid = user.uid;

    final health = context.read<HealthDataProvider>();
    final meds = context.read<MedicineProvider>();
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

  Future<void> _loadOnboardingFlag() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      _checkingOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingOnboarding) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (snapshot.hasData) {
          final user = context.watch<AppAuthProvider>().user;
          if (user != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _bindUserData(user);
            });
          }
          return const RoleHomeScreen();
        }

        if (!_onboardingComplete) {
          return const OnboardingScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

Future<void> markOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_complete', true);
}
