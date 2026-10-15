import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography scale from the Stitch design system (Inter).
///
/// The font family itself is applied app-wide in [AppTheme]; these styles only
/// set size / weight / height so they inherit Inter automatically.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLg = TextStyle(
      fontSize: 34, height: 41 / 34, fontWeight: FontWeight.w700, color: AppColors.onSurface, letterSpacing: -0.5);
  static const TextStyle headlineLg = TextStyle(
      fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w700, color: AppColors.onSurface, letterSpacing: -0.3);
  static const TextStyle headlineMd = TextStyle(
      fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w600, color: AppColors.onSurface, letterSpacing: -0.2);
  static const TextStyle headlineSm = TextStyle(
      fontSize: 20, height: 25 / 20, fontWeight: FontWeight.w600, color: AppColors.onSurface, letterSpacing: -0.2);
  static const TextStyle titleMd =
      TextStyle(fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w600, color: AppColors.onSurface);
  static const TextStyle bodyLg =
      TextStyle(fontSize: 17, height: 24 / 17, fontWeight: FontWeight.w400, color: AppColors.onSurface);
  static const TextStyle bodyMd =
      TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w400, color: AppColors.onSurface);
  static const TextStyle labelLg =
      TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600, color: AppColors.onSurface);
  static const TextStyle labelMd =
      TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w500, color: AppColors.onSurface);

  /// Stitch uses 11px; 12px is used here as the legibility floor.
  static const TextStyle labelSm =
      TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w600, color: AppColors.onSurface);

  static const TextStyle overline = TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.9,
      color: AppColors.onSurfaceVariant);
}
