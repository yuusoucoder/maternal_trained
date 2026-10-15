import 'package:flutter/foundation.dart';

import '../../models/assessment.dart';
import '../../models/patient.dart';
import '../../models/risk_level.dart';
import '../mock/mock_patients.dart';

/// In-memory patient store. Replace the body of these methods with a local
/// database or API calls later – screens only talk to this class.
class PatientRepository extends ChangeNotifier {
  PatientRepository({List<Patient>? seed}) : _patients = seed ?? MockPatients.build();

  final List<Patient> _patients;

  List<Patient> get patients {
    final list = List<Patient>.of(_patients);
    list.sort((a, b) {
      final ta = a.latest?.timestamp ?? DateTime(1970);
      final tb = b.latest?.timestamp ?? DateTime(1970);
      return tb.compareTo(ta);
    });
    return List.unmodifiable(list);
  }

  Patient? byId(String id) {
    for (final p in _patients) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Every assessment across all patients, newest first.
  List<Assessment> get allAssessments {
    final all = [for (final p in _patients) ...p.assessments];
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all;
  }

  List<Assessment> assessmentsOn(DateTime day) => allAssessments
      .where((a) =>
          a.timestamp.year == day.year && a.timestamp.month == day.month && a.timestamp.day == day.day)
      .toList();

  int countByRisk(RiskLevel level) => _patients.where((p) => p.currentRisk == level).length;

  /// Next free demo ID, e.g. "P-0015".
  String nextPatientId() {
    var max = 0;
    for (final p in _patients) {
      final n = int.tryParse(p.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (n > max) max = n;
    }
    return 'P-${(max + 1).toString().padLeft(4, '0')}';
  }

  /// Saves an assessment, creating the patient record if it is new.
  void saveAssessment(Assessment assessment) {
    var patient = byId(assessment.patientId);
    if (patient == null) {
      patient = Patient(id: assessment.patientId, age: assessment.indicators.age, gestationalAge: null);
      _patients.add(patient);
    }
    patient.age = assessment.indicators.age;
    patient.assessments.removeWhere((a) => a.id == assessment.id);
    patient.assessments.insert(0, assessment);
    patient.assessments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  bool isSaved(Assessment assessment) =>
      byId(assessment.patientId)?.assessments.any((a) => a.id == assessment.id) ?? false;
}
