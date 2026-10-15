import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/app_settings.dart';
import '../../models/assessment.dart';
import '../../models/patient.dart';
import '../../models/risk_level.dart';
import '../../navigation/app_navigator.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_header.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/patient_widgets.dart';
import '../../widgets/risk_badge.dart';
import '../assessment/assessment_input_screen.dart';
import '../result/result_screen.dart';

/// Stitch: patient_profile_history. A focused detail screen: current status,
/// one primary action, the latest values, then history.
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key, required this.patientId});

  final String patientId;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  RiskLevel? _historyFilter;

  Future<void> _pickFilter() async {
    final picked = await showModalBottomSheet<_FilterChoice>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceLowest,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Filter assessment history', style: AppTextStyles.titleMd),
              ),
            ),
            _sheetOption(ctx, 'All results', null, Icons.list_alt),
            for (final l in RiskLevel.values) _sheetOption(ctx, l.label, l, l.icon, color: l.color),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _historyFilter = picked.level);
  }

  Widget _sheetOption(BuildContext ctx, String label, RiskLevel? level, IconData icon, {Color? color}) {
    final selected = _historyFilter == level;
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.onSurfaceVariant),
      title: Text(label, style: AppTextStyles.bodyLg),
      trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () => Navigator.pop(ctx, _FilterChoice(level)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Patient ${widget.patientId}',
        style: HeaderStyle.backCentered,
        actions: [
          RoundIconButton(
            icon: Icons.ios_share,
            tooltip: 'Export or print record',
            background: Colors.transparent,
            foreground: AppColors.primary,
            onPressed: () => AppNavigator.showSnack(
              'Export and printing are not available in the prototype.',
              icon: Icons.info_outline,
            ),
          ),
        ],
      ),
      body: AppStateBuilder(builder: (context, scope) {
        final p = scope.repository.byId(widget.patientId);
        if (p == null) {
          return const Center(child: Text('Patient not found'));
        }
        final s = scope.settings;
        final latest = p.latest;
        final history =
            p.assessments.where((a) => _historyFilter == null || a.result.riskLevel == _historyFilter).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.margin, AppSpacing.md, AppSpacing.margin, AppSpacing.xl),
          children: [
            _StatusCard(patient: p),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'New Assessment',
              leadingIcon: Icons.add_circle_outline,
              onPressed: () => AppNavigator.push(context, AssessmentInputScreen(patientId: p.id)),
            ),
            if (latest != null) ...[
              const SizedBox(height: AppSpacing.xl),
              const SectionTitle('Current Assessment'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 4),
                child: AssessmentSummary(indicators: latest.indicators, settings: s),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SectionTitle(
              'Assessment History (${p.assessments.length})',
              trailing: LinkButton(
                label: _historyFilter == null ? 'Filter' : _historyFilter!.shortLabel,
                leadingIcon: Icons.tune,
                onPressed: _pickFilter,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (history.isEmpty)
              const InfoNote(text: 'No assessments match this filter.', icon: Icons.filter_list)
            else
              _Timeline(assessments: history, settings: s),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Demo records only · no real patient data',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
            ),
          ],
        );
      }),
    );
  }
}

class _FilterChoice {
  const _FilterChoice(this.level);
  final RiskLevel? level;
}

/// Current risk status first, then who the patient is.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final latest = patient.latest;
    final level = latest?.result.riskLevel;
    final hasContext = patient.gestationalAge != null || patient.clinicalNote != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.sm,
        border: level == null ? null : Border.all(color: level.color.withAlpha(80)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: level?.icon ?? Icons.person_outline,
                size: 52,
                iconSize: 28,
                radius: 16,
                background: level?.tint ?? AppColors.primaryFixed,
                foreground: level?.color ?? AppColors.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT STATUS', style: AppTextStyles.overline.copyWith(fontSize: 11)),
                    const SizedBox(height: 2),
                    Semantics(
                      header: true,
                      child: Text(
                        level?.label ?? 'Not yet assessed',
                        style: AppTextStyles.headlineMd.copyWith(color: level?.textColor ?? AppColors.onSurface),
                      ),
                    ),
                    if (latest != null)
                      Text(
                        'Latest assessment · ${Fmt.relative(latest.timestamp)}',
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: AppColors.divider),
          Text(
            [
              '${patient.age} years',
              if (patient.gestationalAge != null) 'Gestational age ${patient.gestationalAge}',
            ].join(' · '),
            style: AppTextStyles.labelLg,
          ),
          if (patient.clinicalNote != null) ...[
            const SizedBox(height: 4),
            Text(patient.clinicalNote!, style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
          ],
          if (hasContext) ...[
            const SizedBox(height: 6),
            // Clearly separated from the six model indicators.
            Text(
              'Pregnancy context · not a model input',
              style: AppTextStyles.labelSm.copyWith(color: AppColors.outline, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.assessments, required this.settings});

  final List<Assessment> assessments;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (assessments.length > 1)
          Positioned(
            left: 9,
            top: 26,
            bottom: 40,
            width: 2,
            child: Container(color: AppColors.divider),
          ),
        Column(
          children: [
            for (final a in assessments)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 20,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: a.result.riskLevel.color,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surface, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _HistoryCard(assessment: a, settings: settings)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The whole card opens the (read-only) result for that assessment.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.assessment, required this.settings});

  final Assessment assessment;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final a = assessment;
    final m = a.indicators;
    final vitals = 'BP ${m.systolic}/${m.diastolic} · HR ${m.heartRate} · '
        'BG ${Fmt.glucose(m.bloodGlucose, settings.glucoseUnit)} ${settings.glucoseUnit.label}';
    return AppCard(
      radius: AppRadius.lg,
      onTap: () => AppNavigator.push(context, ResultScreen(assessment: a)),
      semanticLabel: '${Fmt.relative(a.timestamp)}, ${a.result.riskLevel.label}. $vitals. '
          'Open result and explanation.',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Fmt.relative(a.timestamp), style: AppTextStyles.labelLg),
                  const SizedBox(height: 2),
                  Text(
                    '${a.type} · ${a.assessedBy}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(vitals, style: AppTextStyles.labelMd),
                ],
              ),
            ),
            const SizedBox(width: 8),
            RiskBadge(level: a.result.riskLevel, short: true),
            const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
