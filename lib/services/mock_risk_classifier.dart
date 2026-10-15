import 'dart:math' as math;

import '../models/maternal_indicators.dart';
import '../models/risk_level.dart';
import '../models/risk_result.dart';
import 'risk_classifier.dart';

/// PROTOTYPE ONLY – a hand-written heuristic so the UI reacts to input.
///
/// It is NOT Logistic Regression, Random Forest or XGBoost, and the
/// "contributions" are NOT real SHAP values. Every screen that shows this
/// output labels it as demo data.
class MockRiskClassifier implements RiskClassifier {
  const MockRiskClassifier({this.latency = const Duration(milliseconds: 600)});

  /// Simulated network / inference time.
  final Duration latency;

  @override
  String get modelName => 'Selected Model · Pending Evaluation';

  @override
  bool get isDemo => true;

  @override
  Future<RiskResult> classify(MaternalIndicators indicators) async {
    await Future<void>.delayed(latency);
    return evaluate(indicators);
  }

  /// Synchronous version, also used to build consistent mock records.
  RiskResult evaluate(MaternalIndicators m) {
    double c(double v) => v.clamp(-0.6, 0.6).toDouble();

    final contributions = <FeatureContribution>[
      FeatureContribution(indicator: Indicator.systolic, value: c((m.systolic - 120) / 20 * 0.35)),
      FeatureContribution(indicator: Indicator.bloodGlucose, value: c((m.bloodGlucose - 5.5) / 2.5 * 0.30)),
      FeatureContribution(indicator: Indicator.diastolic, value: c((m.diastolic - 80) / 12 * 0.25)),
      FeatureContribution(indicator: Indicator.heartRate, value: c((m.heartRate - 76) / 10 * 0.12)),
      FeatureContribution(indicator: Indicator.age, value: c((m.age - 30) / 10 * 0.15)),
      FeatureContribution(indicator: Indicator.bodyTemperature, value: c((m.bodyTempF - 98.6) / 1.2 * 0.12)),
    ]..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    final score = contributions.fold<double>(0, (s, f) => s + f.value);

    // Three soft "bumps" centred on typical scores for each class.
    double bump(double centre) => math.exp(-math.pow(score - centre, 2) / 0.18);
    final raw = {
      RiskLevel.low: bump(0.0) + (score < 0 ? 0.6 : 0.0),
      RiskLevel.moderate: bump(0.6),
      RiskLevel.high: bump(1.3) + (score > 1.3 ? 0.6 : 0.0),
    };
    // Floor so no class shows 0 %.
    final floored = raw.map((k, v) => MapEntry(k, v + 0.04));
    final total = floored.values.fold<double>(0, (a, b) => a + b);
    final probs = floored.map((k, v) => MapEntry(k, v / total));

    final level = probs.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return RiskResult(
      riskLevel: level,
      probabilities: probs,
      modelName: modelName,
      featureContributions: contributions,
      isDemo: true,
    );
  }
}
