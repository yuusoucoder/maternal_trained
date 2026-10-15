import 'package:aiovy/data/repositories/patient_repository.dart';
import 'package:aiovy/models/assessment.dart';
import 'package:aiovy/models/maternal_indicators.dart';
import 'package:aiovy/models/risk_level.dart';
import 'package:aiovy/services/mock_risk_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockRiskClassifier', () {
    const c = MockRiskClassifier(latency: Duration.zero);

    test('probabilities sum to 1 and match the predicted class', () {
      final r = c.evaluate(const MaternalIndicators(
          age: 32, systolic: 142, diastolic: 92, bloodGlucose: 5.6, bodyTempF: 98.4, heartRate: 82));
      final sum = r.probabilities.values.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(1, 1e-9));
      final top = r.probabilities.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      expect(top, r.riskLevel);
      expect(r.featureContributions, hasLength(6));
    });

    test('clearly abnormal vitals are High, normal vitals are Low', () {
      expect(
        c.evaluate(const MaternalIndicators(
                age: 34, systolic: 158, diastolic: 102, bloodGlucose: 11.2, bodyTempF: 99.1, heartRate: 92))
            .riskLevel,
        RiskLevel.high,
      );
      expect(
        c.evaluate(const MaternalIndicators(
                age: 24, systolic: 114, diastolic: 72, bloodGlucose: 5.1, bodyTempF: 98.2, heartRate: 76))
            .riskLevel,
        RiskLevel.low,
      );
    });
  });

  test('repository creates a new patient when saving to an unknown ID', () {
    final repo = PatientRepository();
    final id = repo.nextPatientId();
    expect(repo.byId(id), isNull);
    final r = const MockRiskClassifier().evaluate(const MaternalIndicators(
        age: 29, systolic: 120, diastolic: 80, bloodGlucose: 5.5, bodyTempF: 98.6, heartRate: 76));
    repo.saveAssessment(Assessment(
      id: 'A-test',
      patientId: id,
      timestamp: DateTime.now(),
      indicators: const MaternalIndicators(
          age: 29, systolic: 120, diastolic: 80, bloodGlucose: 5.5, bodyTempF: 98.6, heartRate: 76),
      result: r,
      assessedBy: 'Test',
    ));
    expect(repo.byId(id), isNotNull);
  });
}
