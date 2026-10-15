import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../navigation/app_navigator.dart';

/// Home / Patients / Profile bar from the Stitch design: icon over label,
/// active tab in plum with a soft pink pill.
class AiovyBottomNav extends StatelessWidget {
  const AiovyBottomNav({super.key, required this.current, required this.onSelect});

  final ShellTab current;
  final ValueChanged<ShellTab> onSelect;

  static const _items = [
    (ShellTab.home, Icons.space_dashboard_outlined, Icons.space_dashboard, 'Home'),
    (ShellTab.patients, Icons.group_outlined, Icons.group, 'Patients'),
    (ShellTab.profile, Icons.account_circle_outlined, Icons.account_circle, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(245),
        boxShadow: const [BoxShadow(color: Color(0x0A2D1924), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            for (final (tab, icon, activeIcon, label) in _items)
              Expanded(
                child: _NavItem(
                  icon: tab == current ? activeIcon : icon,
                  label: label,
                  selected: tab == current,
                  onTap: () {
                    if (tab != current) HapticFeedback.selectionClick();
                    onSelect(tab);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label tab',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.rectangle,
        containedInkWell: true,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryFixed.withAlpha(110) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  // Tab labels stay legible but don't grow past 1.2x, so the
                  // bar keeps its height with large accessibility text.
                  textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2),
                  style: AppTextStyles.labelSm.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
