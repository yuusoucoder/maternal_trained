import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Asks before leaving a screen that would discard the clinician's work
/// (typed indicator values, an unsaved result). Returns true to discard.
Future<bool> confirmDiscard(
  BuildContext context, {
  required String title,
  required String message,
  String discardLabel = 'Discard',
  String keepLabel = 'Keep Editing',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: AppTextStyles.headlineSm),
      content: Text(message, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(keepLabel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(discardLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}
