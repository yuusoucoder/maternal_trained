import 'package:aiovy/data/mock/mock_clinician.dart';
import 'package:aiovy/data/repositories/app_settings.dart';
import 'package:aiovy/data/repositories/patient_repository.dart';
import 'package:aiovy/models/maternal_indicators.dart';
import 'package:aiovy/models/risk_result.dart';
import 'package:aiovy/screens/processing/processing_screen.dart';
import 'package:aiovy/services/risk_classifier.dart';
import 'package:aiovy/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Always fails, like an unreachable API.
class _FailingClassifier implements RiskClassifier {
  int calls = 0;

  @override
  String get modelName => 'Random Forest (UCI)';

  @override
  bool get isDemo => false;

  @override
  Future<RiskResult> classify(MaternalIndicators indicators) async {
    calls++;
    throw const RiskClassifierException('Could not reach the risk model server at http://10.0.2.2:8000.');
  }
}

void main() {
  testWidgets('processing screen shows a readable error and retries', (tester) async {
    final classifier = _FailingClassifier();
    await tester.pumpWidget(AppScope(
      repository: PatientRepository(),
      settings: AppSettings(),
      classifier: classifier,
      clinician: MockClinician.demo,
      child: const MaterialApp(
        home: ProcessingScreen(
          patientId: 'P-0001',
          indicators: MaternalIndicators(
              age: 23, systolic: 140, diastolic: 90, bloodGlucose: 6.8, bodyTempF: 98.0, heartRate: 70),
          isNewPatient: false,
        ),
      ),
    ));

    // The result is awaited together with the 2.6 s animation
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Assessment could not be completed'), findsOneWidget);
    expect(classifier.calls, 1);

    // The error note and buttons sit below the fold of the test surface
    final tryAgain = find.text('Try Again');
    await tester.scrollUntilVisible(tryAgain, 200);
    expect(find.text('Could not reach the risk model server at http://10.0.2.2:8000.'), findsOneWidget);
    expect(find.text('Edit Indicators'), findsOneWidget);
    expect(find.textContaining('Demo classifier'), findsNothing);

    await tester.tap(tryAgain);
    await tester.pump(const Duration(seconds: 3));

    expect(classifier.calls, 2);
    await tester.scrollUntilVisible(tryAgain, 200);
    expect(find.text('Classification failed'), findsOneWidget);
  });
}
