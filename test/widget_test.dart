import 'package:aiovy/app.dart';
import 'package:aiovy/data/mock/mock_clinician.dart';
import 'package:aiovy/data/repositories/app_settings.dart';
import 'package:aiovy/data/repositories/patient_repository.dart';
import 'package:aiovy/services/mock_risk_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AIOVY opens on the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(AiovyApp(
      repository: PatientRepository(),
      settings: AppSettings(),
      classifier: const MockRiskClassifier(),
      clinician: MockClinician.demo,
    ));

    expect(find.text('Get Started'), findsOneWidget);
  });
}
