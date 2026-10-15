import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../navigation/app_navigator.dart';
import 'aiovy_logo.dart';

enum HeaderStyle {
  /// Logo · "AIOVY | Home" · avatar (Home tab)
  brand,

  /// Wordmark · centred title · avatar (Patients / Profile tabs)
  wordmark,

  /// Back · [logo] title · avatar (pushed screens)
  back,

  /// Back · centred title · avatar (pushed screens)
  backCentered,
}

/// Top bar matching the Stitch translucent header (64 px, soft shadow).
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.style = HeaderStyle.back,
    this.showLogo = true,
    this.onBack,
    this.showAvatar,
    this.actions = const [],
  });

  final String title;
  final HeaderStyle style;
  final bool showLogo;
  final VoidCallback? onBack;

  /// Defaults to tab roots only. Pushed screens (back styles) hide it, because
  /// the avatar jumps to the Profile tab and would discard the screen stack
  /// (e.g. an in-progress assessment or an unsaved result).
  final bool? showAvatar;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.only(top: topPad),
      decoration: BoxDecoration(color: AppColors.surface.withAlpha(242), boxShadow: AppShadows.header),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _content(context),
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) => IconButton(
        tooltip: 'Back',
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_ios_new, size: 22, color: AppColors.primary),
      );

  Widget _avatar(BuildContext context) {
    if (showAvatar ?? (style == HeaderStyle.brand || style == HeaderStyle.wordmark)) return const HeaderAvatar();
    // Without an avatar, a 48 px spacer (or one 48 px action) balances the
    // back button so a centred title stays centred.
    return actions.isEmpty ? const SizedBox(width: 48) : const SizedBox.shrink();
  }

  Widget _title(TextAlign align) => Semantics(
        header: true,
        child: Text(
          title,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleMd.copyWith(letterSpacing: -0.2),
        ),
      );

  Widget _content(BuildContext context) {
    switch (style) {
      case HeaderStyle.brand:
        return Row(
          children: [
            const SizedBox(width: 8),
            const AiovyLogoMark(size: 32),
            const SizedBox(width: 8),
            Text('AIOVY', style: AppTextStyles.titleMd.copyWith(letterSpacing: -0.2)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('|', style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
              ),
            ),
            ...actions,
            _avatar(context),
          ],
        );
      case HeaderStyle.wordmark:
        return Row(
          children: [
            const SizedBox(width: 8),
            const SizedBox(
              width: 96,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(fit: BoxFit.scaleDown, child: AiovyWordmark(height: 28)),
              ),
            ),
            Expanded(child: _title(TextAlign.center)),
            SizedBox(
              width: 96,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [...actions, _avatar(context)]),
            ),
          ],
        );
      case HeaderStyle.back:
        return Row(
          children: [
            _backButton(context),
            if (showLogo) ...[
              const AiovyLogoMark(size: 28),
              const SizedBox(width: 8),
            ],
            Expanded(child: _title(TextAlign.start)),
            ...actions,
            _avatar(context),
          ],
        );
      case HeaderStyle.backCentered:
        return Row(
          children: [
            _backButton(context),
            Expanded(child: _title(TextAlign.center)),
            ...actions,
            _avatar(context),
          ],
        );
    }
  }
}

/// Plum circle with a person icon; opens the clinician profile.
class HeaderAvatar extends StatelessWidget {
  const HeaderAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Clinician profile',
      child: Semantics(
        button: true,
        label: 'Clinician profile',
        excludeSemantics: true,
        child: InkResponse(
          onTap: () => AppNavigator.openTab(context, ShellTab.profile),
          radius: 24,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 20, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
