import 'package:flutter/foundation.dart';

import 'maternal_indicators.dart';
import 'risk_level.dart';

/// One SHAP contribution for the predicted risk level, in probability
/// points: positive raises the probability of the predicted level, negative
/// lowers it. (Demo values from `MockRiskClassifier` are "toward higher
/// risk" instead.)
@immutable
class FeatureContribution {
  const FeatureContribution({required this.indicator, required this.value});

  final Indicator indicator;
  final double value;

  String get explanation {
    final v = value;
    if (v >= 0.15) return 'Strongly supports the predicted risk level';
    if (v >= 0.05) return 'Supports the predicted risk level';
    if (v > -0.05) return 'Little influence on this result';
    if (v > -0.15) return 'Points away from the predicted risk level';
    return 'Strongly points away from the predicted risk level';
  }
}

/// What a classifier returns. This is the contract the real ML/API
/// classifier must fulfil later: riskLevel, probabilities, modelName,
/// featureContributions.
@immutable
class RiskResult {
  const RiskResult({
    required this.riskLevel,
    required this.probabilities,
    required this.modelName,
    required this.featureContributions,
    this.isDemo = true,
  });

  final RiskLevel riskLevel;

  /// Class probabilities summing to 1.
  final Map<RiskLevel, double> probabilities;
  final String modelName;

  /// Sorted by absolute impact, largest first.
  final List<FeatureContribution> featureContributions;

  /// True while values come from [MockRiskClassifier].
  final bool isDemo;
}
