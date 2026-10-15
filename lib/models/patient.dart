import 'assessment.dart';
import 'risk_level.dart';

/// A (demo) maternal patient. Only de-identified IDs are used.
class Patient {
  Patient({
    required this.id,
    required this.age,
    this.gestationalAge,
    this.clinicalNote,
    List<Assessment>? assessments,
  }) : assessments = assessments ?? [];

  /// e.g. "P-0014"
  final String id;
  int age;

  /// Pregnancy context – NOT a model input. e.g. "34w 2d".
  final String? gestationalAge;

  /// Free-text context – NOT a model input.
  final String? clinicalNote;

  /// Newest first.
  final List<Assessment> assessments;

  Assessment? get latest => assessments.isEmpty ? null : assessments.first;
  RiskLevel? get currentRisk => latest?.result.riskLevel;

  /// "14" from "P-0014" – used in avatar tiles.
  String get shortNumber {
    final digits = id.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 2) return digits;
    return digits.substring(digits.length - 2);
  }

  /// "P14" style initials.
  String get initials => 'P${int.tryParse(shortNumber) ?? shortNumber}';
}
