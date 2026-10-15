import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/assessment.dart';
import '../../models/risk_level.dart';
import '../../navigation/app_navigator.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_header.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/patient_widgets.dart';
import '../../widgets/risk_badge.dart';
import '../assessment/assessment_input_screen.dart';
import '../patient_profile/patient_profile_screen.dart';
import '../shap/shap_screen.dart';

/// Stitch: risk_classification_result
///
/// Two modes, derived from the repository:
/// * new result (not saved yet) – sticky "Save Assessment" bar, and leaving
///   asks before the result is discarded;
/// * saved / historical result (opened from a patient's history) – read
///   only; the header back button returns to the record.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.assessment});

  final Assessment assessment;

  void _save(BuildContext context) {
    final scope = AppScope.of(context);
    scope.repository.saveAssessment(assessment);
    HapticFeedback.lightImpact();
    final nav = Navigator.of(context);
    nav.popUntil((r) => r.isFirst);
    nav.push(AppNavigator.route(PatientProfileScreen(patientId: assessment.patientId)));
    AppNavigator.showSnack('Assessment saved to ${assessment.patientId}\'s record');
  }

  Future<void> _assessAnother(BuildContext context) async {
    final discard = await confirmDiscard(
      context,
      title: 'Discard this result?',
      message: 'This result for Patient ${assessment.patientId} has not been saved. '
          'Starting a new assessment will discard it.',
      discardLabel: 'Discard & Start New',
      keepLabel: 'Keep Reviewing',
    );
    if (!discard || !context.mounted) return;
    final nav = Navigator.of(context);
    nav.popUntil((r) => r.isFirst);
    nav.push(AppNavigator.route(const AssessmentInputScreen()));
  }

  Future<void> _confirmBack(BuildContext context) async {
    final discard = await confirmDiscard(
      context,
      title: 'Discard this result?',
      message: 'This result has not been saved to Patient ${assessment.patientId}\'s record. '
          'Going back returns to the indicator inputs and discards it.',
      keepLabel: 'Keep Reviewing',
    );
    if (discard && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateBuilder(builder: (context, scope) {
      final s = scope.settings;
      final saved = scope.repository.isSaved(assessment);
      final r = assessment.result;
      final level = r.riskLevel;

      return PopScope(
        canPop: saved,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmBack(context);
        },
        child: Scaffold(
          appBar: const AppHeader(title: 'Risk Assessment', showLogo: true),
          bottomNavigationBar: saved
              ? null
              : _ResultActions(onSave: () => _save(context), onAssessAnother: () => _assessAnother(context)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.margin, AppSpacing.md, AppSpacing.margin, AppSpacing.xl),
            children: [
              // 1–2. Classification + probability distribution
              _RiskCard(assessment: assessment, saved: saved),
              const SizedBox(height: AppSpacing.md),
              // 3. Why this result?
              AppCard(
                radius: AppRadius.lg,
                shadow: AppShadows.md,
                onTap: () => AppNavigator.push(context, ShapScreen(assessment: assessment)),
                semanticLabel: 'Why this result? SHAP explanation. Inspect which maternal indicators most '
                    'influenced this classification.',
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      const IconTile(
                        icon: Icons.insights,
                        size: 42,
                        iconSize: 22,
                        background: AppColors.tertiaryFixed,
                        foreground: AppColors.onTertiaryFixed,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(TextSpan(children: [
                              TextSpan(
                                  text: 'Why this result?', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
                              TextSpan(text: '  · SHAP', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
                            ])),
                            const SizedBox(height: 2),
                            Text(
                              'See which maternal indicators influenced this classification.',
                              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(color: AppColors.surfaceLow, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward, size: 19, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              // 4. Risk-related alert
              if (level == RiskLevel.high && s.highRiskAlerts) ...[
                const SizedBox(height: AppSpacing.md),
                const InfoNote(
                  title: 'High-risk classification',
                  text: 'Prompt review by the attending obstetric team is recommended.',
                  icon: Icons.notification_important_outlined,
                  background: AppColors.riskHighTint,
                  iconColor: AppColors.riskHigh,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              // 5. Inputs
              AppCard(
                radius: AppRadius.lg,
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Assessment Summary'),
                    const SizedBox(height: 4),
                    AssessmentSummary(indicators: assessment.indicators, settings: s),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // 6. Single supporting notice
              InfoNote(
                title: 'Clinical Decision Notice',
                text: '${AppStrings.decisionNotice} Model: ${r.modelName}.',
                background: const Color(0xB3E7DDE0),
                foreground: AppColors.onSecondaryContainer,
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Sticky bottom actions for a new, unsaved result.
class _ResultActions extends StatelessWidget {
  const _ResultActions({required this.onSave, required this.onAssessAnother});

  final VoidCallback onSave;
  final VoidCallback onAssessAnother;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Color(0x0F2D1924), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.margin, 12, AppSpacing.margin, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(label: 'Save Assessment', leadingIcon: Icons.save_outlined, onPressed: onSave),
              Center(child: LinkButton(label: 'Assess Another Patient', onPressed: onAssessAnother)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The verdict: one large, risk-coloured label, followed by the
/// probability distribution. Patient, time and save state sit above it.
class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.assessment, required this.saved});

  final Assessment assessment;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final r = assessment.result;
    final level = r.riskLevel;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.md,
        border: Border.all(color: level.color.withAlpha(80)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Patient ${assessment.patientId} · ${Fmt.relative(assessment.timestamp)}',
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              Pill(
                text: saved ? 'Saved' : 'Not saved',
                dotColor: saved ? AppColors.riskLow : AppColors.primary,
                background: AppColors.surfaceLow,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              IconTile(
                icon: level.icon,
                size: 56,
                iconSize: 32,
                radius: 16,
                background: level.tint,
                foreground: level.color,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Semantics(
                  header: true,
                  label: 'Risk classification: ${level.label}',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RISK CLASSIFICATION', style: AppTextStyles.overline.copyWith(fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(level.label, style: AppTextStyles.headlineLg.copyWith(color: level.textColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_summaryFor(level), style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          const Divider(height: 32, color: AppColors.divider),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('PROBABILITY DISTRIBUTION', style: AppTextStyles.overline.copyWith(fontSize: 11)),
              if (r.isDemo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration:
                      BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
                  child: Text(AppStrings.demoOutputTag,
                      style: AppTextStyles.labelSm.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ExcludeSemantics(
            child: Container(
              height: 8,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(99)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: Row(
                  children: [
                    for (final l in RiskLevel.values) ...[
                      Expanded(
                        flex: ((r.probabilities[l] ?? 0) * 1000).round().clamp(1, 1000).toInt(),
                        child: Container(color: l == level ? l.color : l.color.withAlpha(90)),
                      ),
                      if (l != RiskLevel.high) const SizedBox(width: 2),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Secondary to the verdict: a quiet legend rather than three tiles.
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              for (final l in RiskLevel.values)
                Semantics(
                  label: '${l.shortLabel}: ${Fmt.percent(r.probabilities[l] ?? 0)}${l == level ? ', predicted' : ''}',
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RiskDot(color: l.color),
                      const SizedBox(width: 6),
                      Text(
                        '${l.shortLabel} ${Fmt.percent(r.probabilities[l] ?? 0)}',
                        style: l == level
                            ? AppTextStyles.labelMd.copyWith(color: l.textColor, fontWeight: FontWeight.w700)
                            : AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One plain-language line under the verdict.
String _summaryFor(RiskLevel level) => switch (level) {
      RiskLevel.low => 'The model associates these indicators with low maternal risk.',
      RiskLevel.moderate => 'Some indicators are associated with elevated maternal risk.',
      RiskLevel.high => 'Several indicators are associated with high maternal risk.',
    };
