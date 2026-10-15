import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Label row above a field with an optional trailing hint/action.
class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 14)),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Rounded filled text field with a visible border and focus ring
/// (Stitch input style + WCAG 1.4.11 / 2.4.7).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hint,
    this.icon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final String? semanticLabel;

  static OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyMd.copyWith(fontSize: 16, letterSpacing: obscureText ? 2 : 0),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
        filled: true,
        fillColor: AppColors.surfaceLow,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIcon: icon == null ? null : Icon(icon, size: 20, color: AppColors.outline),
        suffixIcon: suffix,
        enabledBorder: border(AppColors.fieldBorder),
        focusedBorder: border(AppColors.primary, 2),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error, 2),
        errorStyle: AppTextStyles.labelSm.copyWith(color: AppColors.error, fontWeight: FontWeight.w500),
      ),
    );
  }
}
