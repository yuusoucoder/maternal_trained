import 'dart:async';
import 'dart:convert';

import 'package:aiovy/models/maternal_indicators.dart';
import 'package:aiovy/models/risk_level.dart';
import 'package:aiovy/services/api_risk_classifier.dart';
import 'package:aiovy/services/risk_classifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _indicators = MaternalIndicators(
    age: 23, systolic: 140, diastolic: 90, bloodGlucose: 6.8, bodyTempF: 98.0, heartRate: 70);

// The UCI model's output for the record above (locked test row 22),
// rounded to 4 decimals. SHAP values are for the predicted class.
const _response = {
  'risk_level': 'high',
  'probabilities': {'low': 0.1249, 'moderate': 0.2940, 'high': 0.5811},
  'model_name': 'Random Forest (UCI)',
  'feature_contributions': {
    'Age': -0.0308,
    'SystolicBP': 0.4432,
    'DiastolicBP': -0.0166,
    'BS': -0.1213,
    'BodyTemp': -0.0157,
    'HeartRate': -0.0119,
  },
};

ApiRiskClassifier _classifier(MockClientHandler handler, {Duration? timeout}) => ApiRiskClassifier(
      baseUrl: Uri.parse('http://10.0.2.2:8000'),
      client: MockClient(handler),
      timeout: timeout ?? const Duration(seconds: 10),
    );

Matcher _throwsMessage(String part) =>
    throwsA(isA<RiskClassifierException>().having((e) => e.message, 'message', contains(part)));

void main() {
  group('ApiRiskClassifier', () {
    test('posts the six features and parses the response', () async {
      late http.Request sent;
      final c = _classifier((req) async {
        sent = req;
        return http.Response(jsonEncode(_response), 200, headers: {'content-type': 'application/json'});
      });

      final r = await c.classify(_indicators);

      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'http://10.0.2.2:8000/classify');
      expect(sent.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(sent.body), _indicators.toFeatureMap());

      expect(r.riskLevel, RiskLevel.high);
      expect(r.probabilities, {RiskLevel.low: 0.1249, RiskLevel.moderate: 0.2940, RiskLevel.high: 0.5811});
      expect(r.modelName, 'Random Forest (UCI)');
      expect(r.isDemo, isFalse);
      // Sorted by absolute value, largest first
      expect(r.featureContributions.map((f) => f.indicator), [
        Indicator.systolic,
        Indicator.bloodGlucose,
        Indicator.age,
        Indicator.diastolic,
        Indicator.bodyTemperature,
        Indicator.heartRate,
      ]);
      expect(r.featureContributions.first.value, 0.4432);
      expect(r.featureContributions[1].value, -0.1213);
    });

    test('server error throws a readable exception with the detail', () {
      final c = _classifier((_) async => http.Response('{"detail": "SHAP additivity check failed"}', 500));
      expect(c.classify(_indicators), _throwsMessage('HTTP 500'));
      expect(c.classify(_indicators), _throwsMessage('SHAP additivity check failed'));
    });

    test('timeout throws a readable exception', () {
      final c = _classifier(
        (_) => Completer<http.Response>().future, // never answers
        timeout: const Duration(milliseconds: 50),
      );
      expect(c.classify(_indicators), _throwsMessage('did not respond'));
    });

    test('unreachable server throws a readable exception', () {
      final c = _classifier((_) async => throw http.ClientException('Connection refused'));
      expect(c.classify(_indicators), _throwsMessage('Could not reach the risk model server'));
    });

    test('malformed response throws a readable exception', () {
      final broken = Map.of(_response)..remove('feature_contributions');
      final c = _classifier((_) async => http.Response(jsonEncode(broken), 200));
      expect(c.classify(_indicators), _throwsMessage('cannot read'));
    });
  });
}
