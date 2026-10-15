import 'package:flutter/material.dart';

/// Colour tokens taken directly from the Stitch "Serene Clinical Maternity"
/// design system (tailwind config inside each Stitch screen).
///
/// Keep every colour in this file so the palette can be tuned in one place.
class AppColors {
  AppColors._();

  // ── Surfaces ────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFF9F9F8); // page background
  static const Color surfaceLowest = Color(0xFFFFFFFF); // cards
  static const Color surfaceLow = Color(0xFFF3F4F3); // input wells, inner tiles
  static const Color surfaceContainer = Color(0xFFEEEEED);
  static const Color surfaceHigh = Color(0xFFE8E8E7);
  static const Color surfaceHighest = Color(0xFFE2E2E2);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF564147);

  /// Stitch's `outline` (#897177) measured 4.25–4.48:1 on surfaces, just under
  /// WCAG AA. This is the same hue darkened slightly so meta text passes.
  static const Color outline = Color(0xFF7A6369);
  static const Color outlineVariant = Color(0xFFDCBFC6);

  /// Visible field/card border (≥3:1 is used only where a boundary matters).
  static const Color fieldBorder = Color(0xFFD8CBD0);
  static const Color fieldBorderFocus = primary;
  static const Color divider = Color(0xFFEFE9EC);

  // ── Brand ───────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFA32F5E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFC34877);
  static const Color primaryFixed = Color(0xFFFFD9E2);
  static const Color primaryFixedDim = Color(0xFFFFB1C7);
  static const Color onPrimaryFixed = Color(0xFF3E001D);
  static const Color onPrimaryFixedVariant = Color(0xFF871749);
  static const Color brandPink = Color(0xFFC84C7B); // logo stroke
  static const Color brandInk = Color(0xFF2D1924); // logo ink / dark plum
  static const Color brandTint = Color(0xFFFDF2F5); // logo tile

  static const Color secondary = Color(0xFF645C5F);
  static const Color secondaryContainer = Color(0xFFE7DDE0);
  static const Color onSecondaryContainer = Color(0xFF5E5659);
  static const Color secondaryFixed = Color(0xFFEAE0E3);

  static const Color tertiary = Color(0xFF6F5561);
  static const Color tertiaryContainer = Color(0xFF896D7A);
  static const Color tertiaryFixed = Color(0xFFFCD9E9);
  static const Color onTertiaryFixed = Color(0xFF291520);

  static const Color error = Color(0xFFBA1A1A);

  // ── Risk (semantic only – do not use decoratively) ──────────────────────
  static const Color riskLow = Color(0xFF1D7754);
  static const Color riskLowTint = Color(0xFFEDF7F2);
  static const Color riskModerate = Color(0xFFB4690E);

  /// Text version of moderate: #B4690E is 3.99:1 on its tint, this is 5.0:1.
  static const Color riskModerateText = Color(0xFF94560B);
  static const Color riskModerateTint = Color(0xFFFDF8EB);
  static const Color riskHigh = Color(0xFFC2364B);
  static const Color riskHighTint = Color(0xFFFDF0F2);

  // ── SHAP chart ──────────────────────────────────────────────────────────
  static const Color shapPositive = primary;
  static const Color shapNegative = Color(0xFF8C7A84); // lighter than primary
}
