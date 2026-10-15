import 'package:flutter/foundation.dart';

enum GlucoseUnit { mmolL, mgdL }

enum TempUnit { celsius, fahrenheit }

extension GlucoseUnitX on GlucoseUnit {
  String get label => this == GlucoseUnit.mmolL ? 'mmol/L' : 'mg/dL';
}

extension TempUnitX on TempUnit {
  String get label => this == TempUnit.fahrenheit ? '°F' : '°C';
}

/// Prototype preferences (kept in memory only).
class AppSettings extends ChangeNotifier {
  GlucoseUnit _glucoseUnit = GlucoseUnit.mmolL;
  TempUnit _tempUnit = TempUnit.fahrenheit;
  bool _highRiskAlerts = true;
  bool _rememberWorkstation = true;

  GlucoseUnit get glucoseUnit => _glucoseUnit;
  TempUnit get tempUnit => _tempUnit;
  bool get highRiskAlerts => _highRiskAlerts;
  bool get rememberWorkstation => _rememberWorkstation;

  set glucoseUnit(GlucoseUnit v) => _set(() => _glucoseUnit = v);
  set tempUnit(TempUnit v) => _set(() => _tempUnit = v);
  set highRiskAlerts(bool v) => _set(() => _highRiskAlerts = v);
  set rememberWorkstation(bool v) => _set(() => _rememberWorkstation = v);

  void _set(VoidCallback change) {
    change();
    notifyListeners();
  }
}
