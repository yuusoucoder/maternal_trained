import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/assessment.dart';
import '../../models/maternal_indicators.dart';
import '../../models/risk_level.dart';
import '../../models/risk_result.dart';
import '../../navigation/app_navigator.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_header.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../research/research_screen.dart';

/// Stitch: explainable_ai_shap. Plain-language view of the SHAP
/// contributions: one bar per indicator, longest = most influence. The
/// method details sit in a collapsible "About this explanation" card.
class ShapScreen extends StatelessWidget {
  const ShapScreen({super.key, required this.assessment});

  final Assessment assessment;

  @override
  Widget build(BuildContext context) {
    final r = assessment.result;
    final level = r.riskLevel;
    return Scaffold(
      appBar: const AppHeader(title: 'Explanation', style: HeaderStyle.backCentered),
      body: AppStateBuilder(builder: (context, scope) {
        final s = scope.settings;
        final maxAbs = r.featureContributions.fold<double>(0.2, (m, f) => f.value.abs() > m ? f.value.abs() : m);

        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.margin, AppSpacing.md, AppSpacing.margin, AppSpacing.xl),
          children: [
            Semantics(header: true, child: Text('Why this result?', style: AppTextStyles.headlineMd)),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'These maternal indicators contributed to the '),
                TextSpan(
                  text: level.label,
                  style: TextStyle(color: level.textColor, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' classification for Patient ${assessment.patientId}.'),
              ]),
              style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 20,
                    runSpacing: 6,
                    children: [
                      _Legend(
                          color: AppColors.shapPositive,
                          label: r.isDemo ? 'Raises risk' : 'Supports ${level.label}'),
                      _Legend(
                          color: AppColors.shapNegative,
                          label: r.isDemo ? 'Lowers risk' : 'Against ${level.label}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < r.featureContributions.length; i++) ...[
                    if (i > 0) const SizedBox(height: 22),
                    _ContributionRow(
                      contribution: r.featureContributions[i],
                      valueText: Fmt.indicator(r.featureContributions[i].indicator, assessment.indicators, s),
                      description: _describe(r.featureContributions[i].value, r),
                      maxAbs: maxAbs,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoNote(title: 'In short', text: _summary(r), icon: Icons.insights),
            const SizedBox(height: AppSpacing.md),
            _AboutCard(result: r),
          ],
        );
      }),
    );
  }

  String _summary(RiskResult r) {
    final up = r.featureContributions.where((f) => f.value >= 0.05).take(2).map((f) => f.indicator.longLabel);
    final down = r.featureContributions.where((f) => f.value <= -0.05).map((f) => f.indicator.longLabel);
    if (!r.isDemo) {
      final level = r.riskLevel.label;
      final first = up.isEmpty
          ? 'No single indicator strongly drove the $level result.'
          : '${up.join(' and ')} contributed most to the $level result.';
      final second = down.isEmpty ? '' : ' ${down.first} pointed away from it.';
      return '$first$second';
    }
    final first = up.isEmpty
        ? 'No indicator strongly raised the risk for this assessment.'
        : '${up.join(' and ')} had the strongest influence toward higher risk.';
    final second = down.isEmpty ? '' : ' ${down.first} pulled toward lower risk.';
    return '$first$second';
  }
}

/// Plain-language strength of one contribution (presentation only).
///
/// Trained-model SHAP values explain the predicted class, in probability
/// points, so they are phrased relative to that level. Demo values are
/// "toward higher risk" by construction.
String _describe(double v, RiskResult r) {
  if (!r.isDemo) {
    final level = r.riskLevel.label;
    if (v >= 0.15) return 'Strongly supports $level';
    if (v >= 0.05) return 'Supports $level';
    if (v > -0.05) return 'Little influence on this result';
    if (v > -0.15) return 'Points away from $level';
    return 'Strongly points away from $level';
  }
  if (v >= 0.3) return 'Strong influence toward higher risk';
  if (v >= 0.15) return 'Moderate influence toward higher risk';
  if (v >= 0.05) return 'Slight influence toward higher risk';
  if (v > -0.05) return 'Little influence on this result';
  if (v > -0.15) return 'Slight influence toward lower risk';
  return 'Influence toward lower risk';
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({
    required this.contribution,
    required this.valueText,
    required this.description,
    required this.maxAbs,
  });

  final FeatureContribution contribution;
  final String valueText;
  final String description;
  final double maxAbs;

  @override
  Widget build(BuildContext context) {
    final v = contribution.value;
    final positive = v >= 0;
    final frac = (v.abs() / maxAbs).clamp(0.03, 1.0).toDouble();
    final color = positive ? AppColors.shapPositive : AppColors.shapNegative;

    return Semantics(
      label: '${contribution.indicator.longLabel}, $valueText. $description. SHAP value ${Fmt.signed(v)}.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(contribution.indicator.longLabel, style: AppTextStyles.labelLg)),
              const SizedBox(width: 8),
              Text(valueText, style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 10,
                  decoration:
                      BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(99)),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: frac,
                    child: Container(
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 44,
                child: Text(
                  Fmt.signed(v),
                  textAlign: TextAlign.end,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppTextStyles.labelSm.copyWith(
              color: positive && v >= 0.05 ? AppColors.primary : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsed by default: method, model and demo-data notice.
class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.result});

  final RiskResult result;

  /// Method text for trained-model SHAP values (predicted class, probability points).
  static String _realShapText(RiskResult r) {
    final level = r.riskLevel.label;
    final top = r.featureContributions.first.value.abs();
    return 'AIOVY uses SHAP (SHapley Additive exPlanations) to show how much each indicator raised or lowered '
        "the model's probability of the predicted level ($level), compared with its average prediction. "
        'Values are in probability points: +${top.toStringAsFixed(2)} means the indicator raised the '
        'probability of $level by about ${(top * 100).round()} percentage points.';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.onSurfaceVariant,
          leading: const IconTile(icon: Icons.info_outline, size: 36, iconSize: 18, radius: 10),
          title: Text('About this explanation', style: AppTextStyles.labelLg),
          subtitle: Text('SHAP method, model and data',
              style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
          children: [
            Text(
              result.isDemo
                  ? 'AIOVY uses SHAP (SHapley Additive exPlanations) to show how much each indicator moved this '
                      'prediction toward higher or lower risk compared with a typical patient. Longer bars mean a '
                      'stronger influence.'
                  : _realShapText(result),
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.model_training, size: 17, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text('Model: ${result.modelName}', style: AppTextStyles.labelMd)),
              ],
            ),
            if (result.isDemo) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.science_outlined, size: 17, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo values from the prototype classifier, pending thesis evaluation. '
                      'Not trained-model SHAP output.',
                      style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            LinkButton(
              label: 'How AIOVY Works',
              trailingIcon: Icons.chevron_right,
              onPressed: () => AppNavigator.push(context, const ResearchScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
