import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// Button hierarchy:
/// * [PrimaryButton] – filled plum, one per screen (Sign In, Assess Risk,
///   Save Assessment);
/// * [SecondaryButton] – outlined, for a supporting action;
/// * [LinkButton] – text only, for tertiary actions.

/// Main plum call-to-action (52 px tall, 16 px radius). Shrinks slightly
/// while pressed for tactile feedback.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.loading = false,
    this.height = 52,
    this.background = AppColors.primary,
    this.foreground = AppColors.onPrimary,
    this.radius = AppRadius.lg,
    this.side,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool loading;
  final double height;
  final Color background;
  final Color foreground;
  final double radius;
  final BorderSide? side;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final enabled = w.onPressed != null && !w.loading;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(w.radius),
      side: w.side ?? BorderSide.none,
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: w.label,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled || w.loading ? 1 : 0.45,
          child: Container(
            height: w.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(w.radius),
              boxShadow: enabled && w.background == AppColors.primary ? AppShadows.primaryGlow : null,
            ),
            child: Material(
              color: w.background,
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enabled ? w.onPressed : null,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                child: Center(
                  child: w.loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: w.foreground),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (w.leadingIcon != null) ...[
                                Icon(w.leadingIcon, size: 20, color: w.foreground),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  w.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelLg.copyWith(color: w.foreground, fontSize: 16),
                                ),
                              ),
                              if (w.trailingIcon != null) ...[
                                const SizedBox(width: 8),
                                Icon(w.trailingIcon, size: 20, color: w.foreground),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary button: white surface, soft border, plum label.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.foreground = AppColors.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final Color foreground;

  @override
  Widget build(BuildContext context) => PrimaryButton(
        label: label,
        onPressed: onPressed,
        leadingIcon: leadingIcon,
        background: AppColors.surfaceLowest,
        foreground: foreground,
        side: const BorderSide(color: AppColors.fieldBorder),
      );
}

/// Text-only button with a 48 px minimum tap target.
class LinkButton extends StatelessWidget {
  const LinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.leadingIcon,
    this.style,
    this.color = AppColors.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final IconData? leadingIcon;
  final TextStyle? style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(AppSpacing.minTap, AppSpacing.minTap),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[Icon(leadingIcon, size: 18), const SizedBox(width: 4)],
          Text(label, style: (style ?? AppTextStyles.labelMd).copyWith(color: color, fontWeight: FontWeight.w600)),
          if (trailingIcon != null) ...[const SizedBox(width: 2), Icon(trailingIcon, size: 18)],
        ],
      ),
    );
  }
}

/// Round icon button with a tooltip (gives screen readers a name).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background = AppColors.surfaceContainer,
    this.foreground = AppColors.onSurfaceVariant,
    this.size = 40,
    this.radius,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final double size;

  /// null = circle.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: SizedBox(
          width: AppSpacing.minTap,
          height: AppSpacing.minTap,
          child: Center(
            child: Material(
              color: background,
              shape: radius == null
                  ? const CircleBorder()
                  : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius!)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Icon(icon, size: 20, color: foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
