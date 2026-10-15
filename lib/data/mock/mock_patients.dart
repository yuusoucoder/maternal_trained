import '../../models/assessment.dart';
import '../../models/maternal_indicators.dart';
import '../../models/patient.dart';
import '../../services/mock_risk_classifier.dart';

/// Demo cohort. All IDs, ages and vitals are fictional prototype data.
///
/// Risk levels are NOT hard-coded: every record is run through the same
/// [MockRiskClassifier], so a patient shows the same risk on every screen.
class MockPatients {
  MockPatients._();

  static List<Patient> build({DateTime? now}) {
    final t = now ?? DateTime.now();
    const classifier = MockRiskClassifier();

    Assessment a(
      String patientId,
      int n,
      Duration ago,
      MaternalIndicators m, {
      String by = 'Demo Clinician',
      String type = 'Routine Assessment',
    }) {
      return Assessment(
        id: 'A-$patientId-$n',
        patientId: patientId,
        timestamp: t.subtract(ago),
        indicators: m,
        result: classifier.evaluate(m),
        assessedBy: by,
        type: type,
      );
    }

    MaternalIndicators v(int age, int sys, int dia, double bs, double temp, int hr) => MaternalIndicators(
        age: age, systolic: sys, diastolic: dia, bloodGlucose: bs, bodyTempF: temp, heartRate: hr);

    const h = Duration(hours: 1);
    const d = Duration(days: 1);

    return [
      Patient(id: 'P-0014', age: 32, gestationalAge: '34w 2d', assessments: [
        a('P-0014', 3, const Duration(minutes: 14), v(32, 142, 92, 5.6, 98.4, 82),
            by: 'Nurse K. Reynolds, RN', type: 'Routine Assessment'),
        a('P-0014', 2, d * 14 + h * 3, v(32, 122, 80, 5.2, 98.4, 76), by: 'Dr. Santos, MD', type: 'Follow-up'),
        a('P-0014', 1, d * 28 + h * 5, v(32, 118, 76, 5.0, 98.2, 74),
            by: 'Nurse A. Cole, RN', type: 'Initial Intake'),
      ]),
      Patient(id: 'P-0013', age: 27, gestationalAge: '29w 6d', assessments: [
        a('P-0013', 1, const Duration(minutes: 52), v(27, 116, 74, 5.3, 98.6, 72), type: 'Initial Intake'),
      ]),
      Patient(id: 'P-0012', age: 28, gestationalAge: '31w 5d', assessments: [
        a('P-0012', 2, h + const Duration(minutes: 30), v(28, 132, 84, 6.8, 98.6, 78)),
        a('P-0012', 1, d * 21, v(28, 120, 78, 5.9, 98.4, 74), type: 'Initial Intake'),
      ]),
      Patient(id: 'P-0011', age: 24, gestationalAge: '26w 1d', assessments: [
        a('P-0011', 1, h * 2 + const Duration(minutes: 15), v(24, 114, 72, 5.1, 98.2, 76), type: 'Initial Intake'),
      ]),
      Patient(
        id: 'P-0010',
        age: 34,
        gestationalAge: '36w 0d',
        clinicalNote: 'Flagged for obstetric review',
        assessments: [
          a('P-0010', 2, d + h * 2, v(34, 158, 102, 11.2, 99.1, 92), type: 'Follow-up'),
          a('P-0010', 1, d * 10, v(34, 138, 90, 7.4, 98.6, 84), type: 'Initial Intake'),
        ],
      ),
      Patient(id: 'P-0009', age: 29, gestationalAge: '22w 4d', assessments: [
        a('P-0009', 1, d * 2 + h, v(29, 118, 76, 5.4, 98.4, 74), type: 'Initial Intake'),
      ]),
      Patient(id: 'P-0008', age: 41, gestationalAge: '30w 3d', assessments: [
        a('P-0008', 1, d * 2 + h * 4, v(41, 146, 96, 13.5, 98.8, 88), type: 'Routine Assessment'),
      ]),
      Patient(id: 'P-0007', age: 22, gestationalAge: '18w 2d', assessments: [
        a('P-0007', 1, d * 3, v(22, 110, 70, 5.0, 98.2, 70), type: 'Initial Intake'),
      ]),
      Patient(id: 'P-0006', age: 36, gestationalAge: '27w 4d', assessments: [
        a('P-0006', 1, d * 4, v(36, 128, 86, 7.9, 98.6, 80), type: 'Routine Assessment'),
      ]),
      Patient(id: 'P-0005', age: 31, gestationalAge: '24w 0d', assessments: [
        a('P-0005', 1, d * 5, v(31, 112, 74, 5.2, 98.4, 72), type: 'Initial Intake'),
      ]),
    ];
  }
}
