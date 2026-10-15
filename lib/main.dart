import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/mock/mock_clinician.dart';
import 'data/repositories/app_settings.dart';
import 'data/repositories/patient_repository.dart';
import 'services/api_risk_classifier.dart';
import 'services/mock_risk_classifier.dart';
import 'services/risk_classifier.dart';

/// Classifier selection, set at build time:
///
///   flutter run                                   → MockRiskClassifier (demo)
///   flutter run --dart-define=USE_API=true        → trained model API
///               --dart-define=API_URL=http://...  → API address
///
/// API_URL defaults to http://10.0.2.2:8000 (the Android emulator's alias for
/// the PC). Chrome: http://localhost:8000. Phone on the same Wi-Fi: the PC's
/// local IP, e.g. http://192.168.1.20:8000. See ml_model/uci/api/README.md.
const bool _useApi = bool.fromEnvironment('USE_API');
const String _apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFF9F9F8),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final RiskClassifier classifier =
      _useApi ? ApiRiskClassifier(baseUrl: Uri.parse(_apiUrl)) : const MockRiskClassifier();

  runApp(AiovyApp(
    repository: PatientRepository(),
    settings: AppSettings(),
    classifier: classifier,
    clinician: MockClinician.demo,
  ));
}
