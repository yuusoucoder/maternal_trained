import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock/mock_research.dart';
import '../../models/research.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';

/// Stitch: how_aiovy_works_research_dashboard. Visualises the thesis
/// methodology. All metrics read "Pending Evaluation" until real results
/// are entered in `MockResearch`.
class ResearchScreen extends StatelessWidget {
  const ResearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = MockResearch.build();
    return Scaffold(
      appBar: const AppHeader(title: 'How AIOVY Works', style: HeaderStyle.backCentered),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.margin, AppSpacing.md, AppSpacing.margin, AppSpacing.xl),
        children: [
          const InfoNote(
            text: 'Research Architecture · Model evaluation pending thesis experiments.',
            icon: Icons.science_outlined,
            circleIcon: false,
            background: Color(0xFFEBDFE3),
            foreground: AppColors.onSurface,
          ),
          const SizedBox(height: AppSpacing.md),
          _HeroCard(),
          const SizedBox(height: AppSpacing.lg),
          SectionTitle(
            'End-to-End Risk Classification Pipeline',
            icon: Icons.account_tree_outlined,
            trailing: Text('${data.pipeline.length} stages',
                style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
          ),
          const SizedBox(height: 4),
          Text('Sequential lifecycle bridging physiological intake to transparent clinical decision support.',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.md),
          _Pipeline(stages: data.pipeline),
          const SizedBox(height: AppSpacing.lg),
          const SectionTitle('Model Comparison', icon: Icons.compare_arrows),
          const SizedBox(height: AppSpacing.sm),
          const InfoNote(
            title: 'Methodological Note',
            text: 'The deployed model is determined strictly through Repeated Stratified Cross-Validation '
                'benchmarks. No model is pre-assumed to be superior prior to empirical validation.',
            icon: Icons.rule,
            circleIcon: false,
            background: Color(0xFFF1ECEE),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final m in data.models) ...[
            _ModelCard(model: m),
            const SizedBox(height: AppSpacing.md),
          ],
          _SelectedModelCard(selected: data.selectedModel),
          const SizedBox(height: AppSpacing.lg),
          const SectionTitle('Explainability', icon: Icons.insights),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SHAP Feature Attribution', style: AppTextStyles.titleMd),
                const SizedBox(height: 4),
                Text(
                  'Explains how each maternal indicator contributed to the model\'s risk classification.',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Global Feature Importance', style: AppTextStyles.labelMd)),
                          const Pill(text: 'Placeholder', background: AppColors.surfaceHigh),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'Pending Experimental Evaluation',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const InfoNote(
                  title: 'SHAP Explanation Stability',
                  text: 'Stability will be evaluated across resampling / cross-validation folds.',
                  icon: Icons.verified_outlined,
                  circleIcon: false,
                  background: AppColors.surfaceContainer,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionTitle('References & Protocol', icon: Icons.menu_book_outlined),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < data.references.length; i++) ...[
                  Text(data.references[i].authors, style: AppTextStyles.labelLg),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${data.references[i].title} '),
                      TextSpan(
                          text: data.references[i].venue, style: const TextStyle(fontStyle: FontStyle.italic)),
                    ]),
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.45),
                  ),
                  const Divider(height: 28, color: AppColors.divider),
                ],
                _KeyValue(label: 'Protocol ID', value: data.protocolId, mono: true),
                const SizedBox(height: 10),
                _KeyValue(label: 'Validation Strategy', value: data.validationStrategy),
                const SizedBox(height: 10),
                const _KeyValue(label: 'Thesis', value: AppStrings.thesisTitle),
              ],
            ),
          ),
          // No bottom "Back" button: the header back / swipe-back returns to
          // wherever Research was opened from (Profile or a result).
          const SizedBox(height: AppSpacing.sm),
          const VersionFooter(),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text('CLINICAL THESIS & ALGORITHM SPEC',
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.primary, letterSpacing: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text('Maternal Health Risk Classification Architecture', style: AppTextStyles.headlineMd),
          ),
          const SizedBox(height: 10),
          Text(
            'Comparative evaluation of Logistic Regression, Random Forest and XGBoost for maternal risk '
            'classification, paired with Explainable AI (SHAP) feature attribution for transparent clinical '
            'decision support.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill(text: '6 Clinical Indicators', dotColor: AppColors.primary),
              Pill(text: '3 Risk Categories', dotColor: AppColors.secondary),
              Pill(text: 'Explainable AI (SHAP)', dotColor: AppColors.tertiaryContainer),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vertical stepper: one node per stage, connected by a line. The model
/// training stage fans out into three parallel model chips.
class _Pipeline extends StatelessWidget {
  const _Pipeline({required this.stages});

  final List<PipelineStage> stages;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 21,
          top: 30,
          bottom: 30,
          width: 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryFixedDim, AppColors.primary.withAlpha(140)],
              ),
            ),
          ),
        ),
        Column(
          children: [
            for (var i = 0; i < stages.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == stages.length - 1 ? 0 : 10),
                child: Semantics(
                  label: 'Stage ${i + 1} of ${stages.length}: ${stages[i].title}. ${stages[i].description}'
                      '${stages[i].branches.isEmpty ? '' : ' Models: ${stages[i].branches.join(', ')}.'}',
                  excludeSemantics: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLowest,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryFixedDim, width: 2),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Icon(stages[i].icon, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppCard(
                          radius: AppRadius.md,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('${i + 1}',
                                      style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(stages[i].title, style: AppTextStyles.labelLg)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(stages[i].description,
                                  style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
                              if (stages[i].branches.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final b in stages[i].branches)
                                      Pill(
                                        text: b,
                                        background: AppColors.primaryFixed,
                                        foreground: AppColors.onPrimaryFixedVariant,
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.model});

  final ModelInfo model;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(model.name, style: AppTextStyles.titleMd),
                    const SizedBox(height: 2),
                    Text(model.subtitle, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Pill(text: model.tag, background: AppColors.secondaryContainer, foreground: AppColors.onSurface),
            ],
          ),
          const SizedBox(height: 8),
          Text(model.description, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          ResponsiveGrid(
            columns: 3,
            minItemWidth: 84,
            spacing: 6,
            children: [
              for (final e in model.metrics.entries) _MetricTile(name: e.key, value: e.value),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.name, required this.value});

  final String name;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final pending = value == null;
    return Semantics(
      label: '$name: ${value ?? AppStrings.pendingEvaluation}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Column(
          children: [
            Text(name, style: AppTextStyles.labelSm, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              value ?? 'Pending\nEvaluation',
              textAlign: TextAlign.center,
              style: pending
                  ? AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)
                  : AppTextStyles.titleMd.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedModelCard extends StatelessWidget {
  const _SelectedModelCard({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primaryFixedDim, width: 1.5),
        color: AppColors.brandTint,
      ),
      child: Row(
        children: [
          const IconTile(icon: Icons.emoji_events_outlined, size: 44, circle: true, background: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SELECTED MODEL', style: AppTextStyles.overline.copyWith(fontSize: 11)),
                const SizedBox(height: 2),
                Text(selected ?? AppStrings.pendingEvaluation,
                    style: AppTextStyles.titleMd.copyWith(color: selected == null ? AppColors.onSurfaceVariant : AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(
            value,
            style: mono
                ? AppTextStyles.labelMd.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w600)
                : AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
