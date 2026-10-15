import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// White rounded card with the soft Stitch shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color = AppColors.surfaceLowest,
    this.radius = AppRadius.card,
    this.shadow = AppShadows.sm,
    this.border,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final List<BoxShadow>? shadow;
  final BoxBorder? border;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(onTap: onTap, borderRadius: br, child: content);
    }
    Widget card = Container(
      decoration: BoxDecoration(color: color, borderRadius: br, boxShadow: shadow, border: border),
      child: Material(type: MaterialType.transparency, borderRadius: br, clipBehavior: Clip.antiAlias, child: content),
    );
    if (semanticLabel != null) {
      card = Semantics(button: onTap != null, label: semanticLabel, child: card);
    }
    return card;
  }
}

/// Rounded pill used for statuses and small metadata.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.text,
    this.background = AppColors.surfaceContainer,
    this.foreground = AppColors.onSurfaceVariant,
    this.icon,
    this.dotColor,
    this.style,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.uppercase = false,
  });

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final Color? dotColor;
  final TextStyle? style;
  final EdgeInsetsGeometry padding;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final ts = (style ?? AppTextStyles.labelSm).copyWith(
      color: foreground,
      letterSpacing: uppercase ? 0.8 : null,
    );
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              uppercase ? text.toUpperCase() : text,
              style: ts,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Square/circle tile holding an icon.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 40,
    this.iconSize = 20,
    this.background = AppColors.primaryFixed,
    this.foreground = AppColors.primary,
    this.circle = false,
    this.radius = 12,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color background;
  final Color foreground;
  final bool circle;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: foreground),
      ),
    );
  }
}

/// Uppercase grey section label ("CLINICAL SETTINGS").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing, this.padding});

  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(4, 0, 4, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(text.toUpperCase(), style: AppTextStyles.overline)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Bold section title with optional trailing action.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon, this.trailing});

  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Semantics(header: true, child: Text(text, style: AppTextStyles.titleMd)),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Soft tinted note with an icon (disclaimers, prototype notices).
class InfoNote extends StatelessWidget {
  const InfoNote({
    super.key,
    required this.text,
    this.icon = Icons.verified_user_outlined,
    this.title,
    this.background = const Color(0xFFF1ECEE),
    this.foreground = AppColors.onSurfaceVariant,
    this.iconColor = AppColors.primary,
    this.circleIcon = true,
  });

  final String text;
  final String? title;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color iconColor;
  final bool circleIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (circleIcon)
            IconTile(
              icon: icon,
              size: 32,
              iconSize: 18,
              circle: true,
              background: iconColor.withAlpha(26),
              foreground: iconColor,
            )
          else
            Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 18, color: iconColor)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: AppTextStyles.labelLg.copyWith(color: AppColors.onSurface)),
                  const SizedBox(height: 2),
                ],
                Text(text, style: AppTextStyles.labelMd.copyWith(color: foreground, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "AIOVY v1.0 · Thesis Prototype" footer.
class VersionFooter extends StatelessWidget {
  const VersionFooter({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Text(AppStrings.versionShort,
              textAlign: TextAlign.center, style: AppTextStyles.labelSm.copyWith(color: AppColors.outline)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}

/// Small grey tile with a label over a big value + unit (biomarker tiles).
class ValueTile extends StatelessWidget {
  const ValueTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.background = AppColors.surfaceLow,
    this.valueStyle,
  });

  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color background;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value ${unit ?? ''}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: value, style: valueStyle ?? AppTextStyles.headlineSm),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lays children out in a responsive grid (2 columns, 1 on very narrow
/// phones) without fixed heights, so text scaling never clips.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.spacing = AppSpacing.sm,
    this.minItemWidth = 140,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      var cols = columns;
      while (cols > 1 && (c.maxWidth - spacing * (cols - 1)) / cols < minItemWidth) {
        cols--;
      }
      final w = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final child in children) SizedBox(width: w, child: child)],
      );
    });
  }
}
