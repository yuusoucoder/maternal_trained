import 'package:flutter/material.dart';

/// The six model input features. Order matches the Stitch assessment form
/// and the Maternal Health Risk dataset columns.
enum Indicator { age, systolic, diastolic, bloodGlucose, bodyTemperature, heartRate }

extension IndicatorX on Indicator {
  /// Label used on the assessment form.
  String get label => switch (this) {
        Indicator.age => 'Maternal Age',
        Indicator.systolic => 'Systolic BP',
        Indicator.diastolic => 'Diastolic BP',
        Indicator.bloodGlucose => 'Blood Glucose',
        Indicator.bodyTemperature => 'Body Temp',
        Indicator.heartRate => 'Maternal HR',
      };

  /// Longer label used on the SHAP screen.
  String get longLabel => switch (this) {
        Indicator.age => 'Maternal Age',
        Indicator.systolic => 'Systolic Blood Pressure',
        Indicator.diastolic => 'Diastolic Blood Pressure',
        Indicator.bloodGlucose => 'Blood Glucose',
        Indicator.bodyTemperature => 'Body Temperature',
        Indicator.heartRate => 'Maternal Heart Rate',
      };

  IconData get icon => switch (this) {
        Indicator.age => Icons.person_outline_rounded,
        Indicator.systolic => Icons.speed,
        Indicator.diastolic => Icons.speed,
        Indicator.bloodGlucose => Icons.water_drop_outlined,
        Indicator.bodyTemperature => Icons.device_thermostat,
        Indicator.heartRate => Icons.favorite_border_rounded,
      };

  /// Name of the feature in the dataset / future API payload.
  String get featureKey => switch (this) {
        Indicator.age => 'Age',
        Indicator.systolic => 'SystolicBP',
        Indicator.diastolic => 'DiastolicBP',
        Indicator.bloodGlucose => 'BS',
        Indicator.bodyTemperature => 'BodyTemp',
        Indicator.heartRate => 'HeartRate',
      };
}

/// One set of the six maternal indicators, stored in canonical units:
/// years, mmHg, mmol/L, °F, bpm (the units of the training dataset).
@immutable
class MaternalIndicators {
  const MaternalIndicators({
    required this.age,
    required this.systolic,
    required this.diastolic,
    required this.bloodGlucose,
    required this.bodyTempF,
    required this.heartRate,
  });

  final int age;
  final int systolic;
  final int diastolic;

  /// mmol/L
  final double bloodGlucose;

  /// °F
  final double bodyTempF;
  final int heartRate;

  double valueOf(Indicator i) => switch (i) {
        Indicator.age => age.toDouble(),
        Indicator.systolic => systolic.toDouble(),
        Indicator.diastolic => diastolic.toDouble(),
        Indicator.bloodGlucose => bloodGlucose,
        Indicator.bodyTemperature => bodyTempF,
        Indicator.heartRate => heartRate.toDouble(),
      };

  /// Payload shape for the future ML API.
  Map<String, num> toFeatureMap() => {
        for (final i in Indicator.values) i.featureKey: valueOf(i),
      };
}
