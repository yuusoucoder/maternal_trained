import 'package:flutter/material.dart';

/// Spacing, radius and shadow tokens from the Stitch design system.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Horizontal page margin (Stitch `px-margin` = 1.25rem).
  static const double margin = 20;
  static const double gutter = 16;

  /// Minimum tap target used across the app (Android guideline).
  static const double minTap = 48;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double card = 18;
  static const double xl = 20;
  static const double pill = 999;
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0D2D1924), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x082D1924), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x122D1924), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> header = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1)),
  ];

  static List<BoxShadow> primaryGlow = [
    BoxShadow(color: const Color(0xFFA32F5E).withAlpha(56), blurRadius: 24, offset: const Offset(0, 10)),
  ];
}
