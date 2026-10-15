import '../../data/repositories/app_settings.dart';
import '../../models/maternal_indicators.dart';

/// Small, dependency-free formatting helpers.
class Fmt {
  Fmt._();

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String two(int n) => n.toString().padLeft(2, '0');

  /// "10:48 AM"
  static String time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${two(h)}:${two(t.minute)} ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "Oct 2, 2026"
  static String date(DateTime t) => '${_months[t.month - 1]} ${t.day}, ${t.year}';

  /// "Today, 10:48 AM" / "Yesterday, 04:15 PM" / "Oct 1, 2026 · 09:30 AM"
  static String relative(DateTime t, {DateTime? now, bool withTime = true}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    final String label;
    if (diff == 0) {
      label = 'Today';
    } else if (diff == 1) {
      label = 'Yesterday';
    } else {
      label = date(t);
    }
    if (!withTime) return label;
    return diff <= 1 ? '$label, ${time(t)}' : '$label · ${time(t)}';
  }

  // ── Units (values are stored in mmol/L and °F) ─────────────────────────
  static double toDisplayGlucose(double mmol, GlucoseUnit u) => u == GlucoseUnit.mmolL ? mmol : mmol * 18.0;
  static double fromDisplayGlucose(double v, GlucoseUnit u) => u == GlucoseUnit.mmolL ? v : v / 18.0;

  static double toDisplayTemp(double f, TempUnit u) => u == TempUnit.fahrenheit ? f : (f - 32) * 5 / 9;
  static double fromDisplayTemp(double v, TempUnit u) => u == TempUnit.fahrenheit ? v : v * 9 / 5 + 32;

  static String glucose(double mmol, GlucoseUnit u) {
    final v = toDisplayGlucose(mmol, u);
    return u == GlucoseUnit.mmolL ? v.toStringAsFixed(1) : v.round().toString();
  }

  static String temp(double f, TempUnit u) => toDisplayTemp(f, u).toStringAsFixed(1);

  /// "71%"
  static String percent(double p) => '${(p * 100).round()}%';

  /// "+0.38" / "−0.12"
  static String signed(double v) => v >= 0 ? '+${v.toStringAsFixed(2)}' : '−${v.abs().toStringAsFixed(2)}';

  /// "142 mmHg", "5.6 mmol/L", "98.4°F", "32 yrs" in the user's units.
  static String indicator(Indicator i, MaternalIndicators m, AppSettings s) => switch (i) {
        Indicator.age => '${m.age} yrs',
        Indicator.systolic => '${m.systolic} mmHg',
        Indicator.diastolic => '${m.diastolic} mmHg',
        Indicator.bloodGlucose => '${glucose(m.bloodGlucose, s.glucoseUnit)} ${s.glucoseUnit.label}',
        Indicator.bodyTemperature => '${temp(m.bodyTempF, s.tempUnit)}${s.tempUnit.label}',
        Indicator.heartRate => '${m.heartRate} bpm',
      };

  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
