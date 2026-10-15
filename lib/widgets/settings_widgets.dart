import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import 'common.dart';

/// White grouped list (Settings / Profile), rows separated by hairlines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, thickness: 1, indent: 72, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

/// Icon tile · title/subtitle · trailing widget (chevron, switch, pill...).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.iconBackground = const Color(0xFFF0E8EB),
    this.titleStyle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color iconBackground;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          child: Row(
            children: [
              IconTile(
                icon: icon,
                size: 40,
                iconSize: 20,
                background: iconBackground,
                foreground: AppColors.primary,
                radius: 12,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: titleStyle ?? AppTextStyles.titleMd.copyWith(fontSize: 16)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (showChevron) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Two/three-option pill toggle (e.g. mmol/L | mg/dL).
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.semanticLabel,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in options)
              Semantics(
                button: true,
                selected: o == selected,
                label: labelOf(o),
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (o != selected) HapticFeedback.selectionClick();
                    onChanged(o);
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: o == selected ? AppColors.surfaceLowest : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: o == selected ? AppShadows.sm : null,
                      ),
                      child: Text(
                        labelOf(o),
                        style: AppTextStyles.labelMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: o == selected ? AppColors.primary : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Plum switch styled like the Stitch toggle.
class AiovySwitch extends StatelessWidget {
  const AiovySwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Switch(
        value: value,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          onChanged(v);
        },
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.surfaceHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.outline,
        ),
      ),
    );
  }
}
