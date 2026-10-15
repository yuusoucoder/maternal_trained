import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/maternal_indicators.dart';
import '../../widgets/common.dart';
import 'indicator_spec.dart';

/// One of the six indicator rows (Stitch: label + icon, value well with
/// unit). The expected range is always shown under the label and is
/// replaced by the validation message when the value needs attention.
class IndicatorInputCard extends StatelessWidget {
  const IndicatorInputCard({
    super.key,
    required this.spec,
    required this.controller,
    required this.focusNode,
    required this.status,
    required this.showErrors,
    required this.onChanged,
    required this.onSubmitted,
    required this.isLast,
    this.crossCheckMessage,
  });

  final IndicatorSpec spec;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FieldStatus status;

  /// Errors are shown once the field has text or the user tried to submit.
  final bool showErrors;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final bool isLast;
  final String? crossCheckMessage;

  bool get _isError => showErrors && status != FieldStatus.valid;

  String? get _errorText {
    if (!showErrors) return null;
    return switch (status) {
      FieldStatus.valid => null,
      FieldStatus.empty => 'Required · expected ${spec.rangeText}',
      FieldStatus.invalidNumber => spec.decimal ? 'Enter a number' : 'Enter a whole number',
      FieldStatus.outOfRange => 'Out of range · expected ${spec.rangeText}',
      FieldStatus.crossCheck => crossCheckMessage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final i = spec.indicator;
    final err = _errorText;
    final valid = status == FieldStatus.valid;

    final label = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(i.longLabel, style: AppTextStyles.labelLg)),
        const SizedBox(width: 6),
        ExcludeSemantics(
          child: Icon(
            valid
                ? Icons.check_circle
                : _isError
                    ? Icons.error_outline
                    : i.icon,
            size: 18,
            color: valid
                ? AppColors.riskLow
                : _isError
                    ? AppColors.error
                    : AppColors.primary,
          ),
        ),
      ],
    );

    final helper = err != null
        ? Semantics(
            liveRegion: true,
            child: Text(err, style: AppTextStyles.labelSm.copyWith(color: AppColors.error, fontWeight: FontWeight.w500)),
          )
        : ExcludeSemantics(
            child: Text(
              'Expected ${spec.rangeText}',
              style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
          );

    final field = Semantics(
      label: '${i.longLabel}, ${spec.unit}, expected ${spec.rangeText}',
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted(),
        keyboardType: spec.decimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        // Keeps the field clear of the sticky "Assess Risk" bar when scrolled
        // into view above the keyboard.
        scrollPadding: const EdgeInsets.all(AppSpacing.xl),
        inputFormatters: [
          FilteringTextInputFormatter.allow(spec.decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]')),
          LengthLimitingTextInputFormatter(5),
        ],
        style: AppTextStyles.headlineSm,
        decoration: InputDecoration(
          hintText: '—',
          hintStyle: AppTextStyles.headlineSm.copyWith(color: AppColors.outline),
          suffixText: spec.unit,
          suffixStyle: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
          filled: true,
          fillColor: AppColors.surfaceLow,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          enabledBorder: _border(_isError ? AppColors.error : AppColors.fieldBorder, _isError ? 1.5 : 1),
          focusedBorder: _border(_isError ? AppColors.error : AppColors.primary, 2),
        ),
      ),
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      border: _isError ? Border.all(color: AppColors.error.withAlpha(90)) : null,
      // Label + range on the left, value on the right; stacked on very
      // narrow screens so long labels and units never squeeze the input.
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 260) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [label, const SizedBox(height: 8), field, const SizedBox(height: 6), helper],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [label, const SizedBox(height: 4), helper],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 140, child: field),
          ],
        );
      }),
    );
  }

  static OutlineInputBorder _border(Color c, double w) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: w));
}
