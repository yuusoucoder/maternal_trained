import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';

/// The AIOVY brand mark, drawn from the Stitch SVG
/// (`aiovy_abstract_maternal_health_brand_mark`, 160×160 viewBox) so it stays
/// crisp at any size without an SVG package.
class AiovyLogoMark extends StatelessWidget {
  const AiovyLogoMark({super.key, this.size = 32, this.showTile = true, this.semanticLabel = 'AIOVY logo'});

  final double size;

  /// Draws the soft pink rounded tile behind the mark.
  final bool showTile;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _BrandMarkPainter(showTile: showTile)),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter({required this.showTile});

  final bool showTile;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 160.0;
    canvas.save();
    canvas.scale(s, s);

    if (showTile) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 160, 160), const Radius.circular(36)),
        Paint()..color = AppColors.brandTint,
      );
    }

    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer protective shield (15 % ink)
    final shield = Path()
      ..moveTo(80, 34)
      ..cubicTo(60, 34, 44, 50, 44, 72)
      ..cubicTo(44, 94, 62, 116, 80, 126)
      ..cubicTo(98, 116, 116, 94, 116, 72)
      ..cubicTo(116, 50, 100, 34, 80, 34)
      ..close();
    canvas.drawPath(shield, stroke(AppColors.brandInk.withAlpha(38), 4.5));

    // Soft bloom fill
    final bloom = Path()
      ..moveTo(56, 86)
      ..cubicTo(56, 64, 68, 46, 80, 46)
      ..cubicTo(92, 46, 104, 64, 104, 86)
      ..cubicTo(104, 102, 92, 115, 80, 122)
      ..cubicTo(68, 115, 56, 102, 56, 86)
      ..close();
    canvas.drawPath(bloom, Paint()..color = AppColors.brandPink.withAlpha(31));

    // Primary maternal arc
    final arc = Path()
      ..moveTo(80, 46)
      ..cubicTo(67, 46, 54, 62, 54, 84)
      ..cubicTo(54, 104, 70, 118, 80, 124)
      ..cubicTo(90, 118, 106, 104, 106, 84)
      ..cubicTo(106, 62, 93, 46, 80, 46)
      ..close();
    canvas.drawPath(arc, stroke(AppColors.brandPink, 5));

    // Inner beacon
    final beacon = Path()
      ..moveTo(72, 78)
      ..cubicTo(72, 70, 75.5, 64, 80, 64)
      ..cubicTo(84.5, 64, 88, 70, 88, 78)
      ..cubicTo(88, 88, 80, 96, 80, 96)
      ..cubicTo(80, 96, 72, 88, 72, 78)
      ..close();
    canvas.drawPath(beacon, Paint()..color = AppColors.brandPink);

    // Crossbar
    final bar = Path()
      ..moveTo(64, 90)
      ..cubicTo(72, 88, 88, 88, 96, 90);
    canvas.drawPath(bar, stroke(AppColors.brandInk, 4.5));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) => oldDelegate.showTile != showTile;
}

/// Horizontal wordmark: mark + "AIOVY" + "MATERNAL CARE INTELLIGENCE".
class AiovyWordmark extends StatelessWidget {
  const AiovyWordmark({super.key, this.height = 32, this.showSubLabel = true});

  final double height;
  final bool showSubLabel;

  @override
  Widget build(BuildContext context) {
    final scale = height / 32;
    return Semantics(
      label: 'AIOVY, Maternal Care Intelligence',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AiovyLogoMark(size: height),
          SizedBox(width: 8 * scale),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 17 * scale,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.brandInk,
                ),
              ),
              if (showSubLabel)
                Text(
                  AppStrings.wordmarkSub,
                  style: TextStyle(
                    fontSize: 6.5 * scale,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.9,
                    color: const Color(0xFF6B5660),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
