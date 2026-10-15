import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';
import '../models/risk_level.dart';

/// Coloured pill showing a risk level. Colour is always paired with an icon
/// and text, so it never relies on colour alone.
class RiskBadge extends StatelessWidget {
  const RiskBadge({
    super.key,
    required this.level,
    this.short = false,
    this.uppercase = false,
    this.large = false,
  });

  final RiskLevel level;

  /// "Moderate" instead of "Moderate Risk".
  final bool short;
  final bool uppercase;
  final bool large;

  @override
  Widget build(BuildContext context) {
    var text = short ? level.shortLabel : level.label;
    if (uppercase) text = text.toUpperCase();
    return Semantics(
      label: level.label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: large ? 12 : 10, vertical: large ? 6 : 4),
        decoration: BoxDecoration(color: level.tint, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(level.icon, size: large ? 17 : 15, color: level.color),
            const SizedBox(width: 5),
            Text(
              text,
              style: AppTextStyles.labelSm.copyWith(
                color: level.textColor,
                fontSize: large ? 13 : 12,
                letterSpacing: uppercase ? 0.8 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small coloured dot for legends and filter chips.
class RiskDot extends StatelessWidget {
  const RiskDot({super.key, required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
