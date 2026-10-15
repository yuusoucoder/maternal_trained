import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/app_settings.dart';
import 'data/repositories/patient_repository.dart';
import 'models/clinician.dart';
import 'navigation/app_navigator.dart';
import 'screens/splash/splash_screen.dart';
import 'services/risk_classifier.dart';
import 'state/app_scope.dart';

class AiovyApp extends StatelessWidget {
  const AiovyApp({
    super.key,
    required this.repository,
    required this.settings,
    required this.classifier,
    required this.clinician,
  });

  final PatientRepository repository;
  final AppSettings settings;
  final RiskClassifier classifier;
  final Clinician clinician;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: repository,
      settings: settings,
      classifier: classifier,
      clinician: clinician,
      child: MaterialApp(
        title: 'AIOVY',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        scaffoldMessengerKey: AppNavigator.messengerKey,
        home: const SplashScreen(),
      ),
    );
  }
}
