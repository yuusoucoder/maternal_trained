import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The three output classes of the maternal risk classifier.
enum RiskLevel { low, moderate, high }

extension RiskLevelX on RiskLevel {
  /// "Low Risk", "Moderate Risk", "High Risk"
  String get label => switch (this) {
        RiskLevel.low => 'Low Risk',
        RiskLevel.moderate => 'Moderate Risk',
        RiskLevel.high => 'High Risk',
      };

  /// "Low", "Moderate", "High"
  String get shortLabel => switch (this) {
        RiskLevel.low => 'Low',
        RiskLevel.moderate => 'Moderate',
        RiskLevel.high => 'High',
      };

  /// Strong colour for dots, bars and icons.
  Color get color => switch (this) {
        RiskLevel.low => AppColors.riskLow,
        RiskLevel.moderate => AppColors.riskModerate,
        RiskLevel.high => AppColors.riskHigh,
      };

  /// AA-compliant text colour on [tint].
  Color get textColor => switch (this) {
        RiskLevel.low => AppColors.riskLow,
        RiskLevel.moderate => AppColors.riskModerateText,
        RiskLevel.high => AppColors.riskHigh,
      };

  Color get tint => switch (this) {
        RiskLevel.low => AppColors.riskLowTint,
        RiskLevel.moderate => AppColors.riskModerateTint,
        RiskLevel.high => AppColors.riskHighTint,
      };

  IconData get icon => switch (this) {
        RiskLevel.low => Icons.check_circle_rounded,
        RiskLevel.moderate => Icons.warning_rounded,
        RiskLevel.high => Icons.report_rounded,
      };
}
