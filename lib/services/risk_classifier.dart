import '../models/maternal_indicators.dart';
import '../models/risk_result.dart';

/// The single seam between the UI and the machine-learning system.
///
/// [MockRiskClassifier] is the default; [ApiRiskClassifier] calls the
/// trained model served by `ml_model/uci/api`. `main.dart` picks one. No
/// screen needs to change.
abstract class RiskClassifier {
  /// Human-readable name shown on the result screen.
  String get modelName;

  /// True when results are prototype demo values, not trained-model output.
  bool get isDemo;

  /// Throws [RiskClassifierException] when no result can be produced.
  Future<RiskResult> classify(MaternalIndicators indicators);
}

/// A classification failed. [message] is written for the clinician and is
/// shown as-is on the processing screen.
class RiskClassifierException implements Exception {
  const RiskClassifierException(this.message);

  final String message;

  @override
  String toString() => 'RiskClassifierException: $message';
}
