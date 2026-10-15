import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/maternal_indicators.dart';
import '../models/risk_level.dart';
import '../models/risk_result.dart';
import 'risk_classifier.dart';

/// Calls the trained model served by `ml_model/uci/api` (FastAPI).
///
/// POST /classify
/// request:  {"Age": 32, "SystolicBP": 142, "DiastolicBP": 92,
///            "BS": 5.6, "BodyTemp": 98.4, "HeartRate": 82}
/// response: {"risk_level": "moderate",
///            "probabilities": {"low": 0.12, "moderate": 0.71, "high": 0.17},
///            "model_name": "Random Forest (UCI)",
///            "feature_contributions": {"SystolicBP": 0.38, "BS": 0.02, ...}}
///
/// The request uses canonical units (mmol/L, °F) whatever the display
/// units in Settings. `feature_contributions` are SHAP values for the
/// predicted class, in probability units.
class ApiRiskClassifier implements RiskClassifier {
  ApiRiskClassifier({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final Uri baseUrl;
  final Duration timeout;
  final http.Client _client;

  @override
  String get modelName => 'Random Forest (UCI)';

  @override
  bool get isDemo => false;

  @override
  Future<RiskResult> classify(MaternalIndicators indicators) async {
    final http.Response res;
    try {
      res = await _client
          .post(
            baseUrl.resolve('/classify'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(indicators.toFeatureMap()),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw RiskClassifierException(
          'The risk model server did not respond within ${timeout.inSeconds} seconds. '
          'Check that the AIOVY API is running at $baseUrl.');
    } on http.ClientException {
      throw RiskClassifierException(
          'Could not reach the risk model server at $baseUrl. '
          'Check that the AIOVY API is running and that this device is on the same network.');
    }

    if (res.statusCode != 200) {
      throw RiskClassifierException(
          'The risk model server returned an error (HTTP ${res.statusCode}).${_detail(res.body)}');
    }

    try {
      return _parse(jsonDecode(res.body));
    } on FormatException {
      throw const RiskClassifierException('The risk model server sent a response this app cannot read.');
    }
  }

  static RiskResult _parse(Object? json) {
    final body = _as<Map<String, dynamic>>(json, 'response');
    final probs = _as<Map<String, dynamic>>(body['probabilities'], 'probabilities');
    final shap = _as<Map<String, dynamic>>(body['feature_contributions'], 'feature_contributions');

    final contributions = [
      for (final i in Indicator.values)
        FeatureContribution(indicator: i, value: _as<num>(shap[i.featureKey], i.featureKey).toDouble()),
    ]..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    final level = _as<String>(body['risk_level'], 'risk_level');
    return RiskResult(
      riskLevel: RiskLevel.values.firstWhere(
        (l) => l.name == level,
        orElse: () => throw FormatException('Unknown risk_level "$level"'),
      ),
      probabilities: {for (final l in RiskLevel.values) l: _as<num>(probs[l.name], l.name).toDouble()},
      modelName: _as<String>(body['model_name'], 'model_name'),
      featureContributions: contributions,
      isDemo: false,
    );
  }

  static T _as<T>(Object? value, String field) =>
      value is T ? value : throw FormatException('Missing or invalid "$field"');

  /// FastAPI puts the reason in "detail"; show it when it is a plain string.
  static String _detail(String body) {
    try {
      final detail = (jsonDecode(body) as Map<String, dynamic>)['detail'];
      return detail is String ? ' $detail.' : '';
    } on Object {
      return '';
    }
  }
}
