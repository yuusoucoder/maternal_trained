import 'package:flutter/foundation.dart';

import 'maternal_indicators.dart';
import 'risk_result.dart';

/// A saved (or about-to-be-saved) risk assessment for one patient.
@immutable
class Assessment {
  const Assessment({
    required this.id,
    required this.patientId,
    required this.timestamp,
    required this.indicators,
    required this.result,
    required this.assessedBy,
    this.type = 'Routine Assessment',
  });

  final String id;
  final String patientId;
  final DateTime timestamp;
  final MaternalIndicators indicators;
  final RiskResult result;
  final String assessedBy;

  /// e.g. "Initial Intake", "Follow-up", "Routine Assessment".
  final String type;
}
