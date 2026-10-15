import '../../models/clinician.dart';

class MockClinician {
  MockClinician._();

  static const Clinician demo = Clinician(
    displayName: 'Demo Clinician',
    role: 'Obstetric Clinician',
    affiliation: 'AIOVY Thesis Prototype',
    email: 'demo.clinician@aiovy.app',
  );

  /// Any non-empty credentials are accepted; these are pre-filled.
  static const String demoEmail = 'demo.clinician@aiovy.app';
  static const String demoPassword = 'aiovy-demo';
}
