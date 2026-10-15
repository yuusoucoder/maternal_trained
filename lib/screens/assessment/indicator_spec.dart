import '../../data/repositories/app_settings.dart';
import '../../models/maternal_indicators.dart';

enum FieldStatus { empty, valid, invalidNumber, outOfRange, crossCheck }

/// Unit, range and keyboard rules for one indicator input, in the unit the
/// clinician currently sees (from Settings).
class IndicatorSpec {
  const IndicatorSpec({
    required this.indicator,
    required this.unit,
    required this.min,
    required this.max,
    required this.decimal,
  });

  final Indicator indicator;
  final String unit;
  final double min;
  final double max;
  final bool decimal;

  String fmt(double v) => decimal ? v.toStringAsFixed(1) : v.round().toString();

  String get rangeText => '${fmt(min)}–${fmt(max)} $unit';

  static IndicatorSpec of(Indicator i, AppSettings s) {
    switch (i) {
      case Indicator.age:
        return const IndicatorSpec(indicator: Indicator.age, unit: 'years', min: 12, max: 65, decimal: false);
      case Indicator.systolic:
        return const IndicatorSpec(indicator: Indicator.systolic, unit: 'mmHg', min: 60, max: 240, decimal: false);
      case Indicator.diastolic:
        return const IndicatorSpec(indicator: Indicator.diastolic, unit: 'mmHg', min: 40, max: 160, decimal: false);
      case Indicator.bloodGlucose:
        return s.glucoseUnit == GlucoseUnit.mmolL
            ? const IndicatorSpec(indicator: Indicator.bloodGlucose, unit: 'mmol/L', min: 2, max: 25, decimal: true)
            : const IndicatorSpec(indicator: Indicator.bloodGlucose, unit: 'mg/dL', min: 36, max: 450, decimal: false);
      case Indicator.bodyTemperature:
        return s.tempUnit == TempUnit.fahrenheit
            ? const IndicatorSpec(indicator: Indicator.bodyTemperature, unit: '°F', min: 90, max: 110, decimal: true)
            : const IndicatorSpec(indicator: Indicator.bodyTemperature, unit: '°C', min: 32, max: 43.5, decimal: true);
      case Indicator.heartRate:
        return const IndicatorSpec(indicator: Indicator.heartRate, unit: 'bpm', min: 40, max: 200, decimal: false);
    }
  }

  FieldStatus check(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return FieldStatus.empty;
    final v = double.tryParse(t);
    if (v == null) return FieldStatus.invalidNumber;
    if (!decimal && v != v.roundToDouble()) return FieldStatus.invalidNumber;
    if (v < min || v > max) return FieldStatus.outOfRange;
    return FieldStatus.valid;
  }
}
