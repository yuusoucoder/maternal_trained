import 'package:aiovy/data/mock/mock_clinician.dart';
import 'package:aiovy/data/repositories/app_settings.dart';
import 'package:aiovy/data/repositories/patient_repository.dart';
import 'package:aiovy/models/assessment.dart';
import 'package:aiovy/models/maternal_indicators.dart';
import 'package:aiovy/models/risk_level.dart';
import 'package:aiovy/models/risk_result.dart';
import 'package:aiovy/screens/shap/shap_screen.dart';
import 'package:aiovy/services/mock_risk_classifier.dart';
import 'package:aiovy/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// app_test_cases.csv case T1 (locked test row 26), predicted Low Risk.
// SHAP values from the UCI model for the predicted class.
const _t1 = MaternalIndicators(age: 19, systolic: 120, diastolic: 75, bloodGlucose: 7.2, bodyTempF: 98.0, heartRate: 66);
const _t1Result = RiskResult(
  riskLevel: RiskLevel.low,
  probabilities: {RiskLevel.low: 0.7026, RiskLevel.moderate: 0.2688, RiskLevel.high: 0.0286},
  modelName: 'Random Forest (UCI)',
  featureContributions: [
    FeatureContribution(indicator: Indicator.bloodGlucose, value: 0.188),
    FeatureContribution(indicator: Indicator.bodyTemperature, value: 0.075),
    FeatureContribution(indicator: Indicator.age, value: 0.040),
    FeatureContribution(indicator: Indicator.systolic, value: 0.035),
    FeatureContribution(indicator: Indicator.diastolic, value: 0.022),
    FeatureContribution(indicator: Indicator.heartRate, value: 0.012),
  ],
  isDemo: false,
);

Future<void> _pumpShap(WidgetTester tester, MaternalIndicators m, RiskResult r) {
  return tester.pumpWidget(AppScope(
    repository: PatientRepository(),
    settings: AppSettings(),
    classifier: const MockRiskClassifier(),
    clinician: MockClinician.demo,
    child: MaterialApp(
      home: ShapScreen(
        assessment: Assessment(
          id: 'A-test',
          patientId: 'P-0001',
          timestamp: DateTime(2026, 10, 16),
          indicators: m,
          result: r,
          assessedBy: 'Test',
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('real SHAP values are phrased relative to the predicted level', (tester) async {
    await _pumpShap(tester, _t1, _t1Result);

    expect(find.text('Supports Low Risk'), findsNWidgets(2)); // legend + BodyTemp +0.075
    expect(find.text('Against Low Risk'), findsOneWidget);
    expect(find.text('Strongly supports Low Risk'), findsOneWidget); // BS +0.188
    expect(find.text('Raises risk'), findsNothing);
    expect(find.textContaining('toward higher risk'), findsNothing);

    await tester.scrollUntilVisible(find.text('In short'), 200);
    expect(find.text('Blood Glucose and Body Temperature contributed most to the Low Risk result.'), findsOneWidget);
  });

  testWidgets('demo results keep the original wording', (tester) async {
    const m = MaternalIndicators(age: 34, systolic: 158, diastolic: 102, bloodGlucose: 11.2, bodyTempF: 99.1, heartRate: 92);
    await _pumpShap(tester, m, const MockRiskClassifier().evaluate(m));

    expect(find.text('Raises risk'), findsOneWidget);
    expect(find.text('Lowers risk'), findsOneWidget);
    expect(find.textContaining('Supports'), findsNothing);
  });
}
