import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/app_settings.dart';
import '../models/assessment.dart';
import '../models/maternal_indicators.dart';
import '../models/patient.dart';
import '../models/risk_level.dart';
import 'common.dart';
import 'risk_badge.dart';

/// Rounded-square number tile with a risk status dot (Patients list).
class PatientNumberTile extends StatelessWidget {
  const PatientNumberTile({super.key, required this.patient, this.size = 46});

  final Patient patient;
  final double size;

  @override
  Widget build(BuildContext context) {
    final risk = patient.currentRisk;
    return ExcludeSemantics(
      child: SizedBox(
        width: size + 4,
        height: size + 4,
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: risk?.tint ?? AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(patient.shortNumber,
                  style: AppTextStyles.titleMd.copyWith(color: risk?.textColor ?? AppColors.onSurface)),
            ),
            if (risk != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: risk.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Recent-assessment card used on Home (Stitch home_dashboard).
class RecentAssessmentCard extends StatelessWidget {
  const RecentAssessmentCard({super.key, required this.assessment, required this.onTap});

  final Assessment assessment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = assessment;
    final level = a.result.riskLevel;
    final m = a.indicators;
    return AppCard(
      onTap: onTap,
      semanticLabel: 'Patient ${a.patientId}, ${m.age} years, ${level.label}, '
          'assessed ${Fmt.relative(a.timestamp)}. Blood pressure ${m.systolic} over ${m.diastolic}.',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColors.secondaryFixed,
                  child: Text('P', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text('Patient ${a.patientId}', style: AppTextStyles.titleMd),
                          Pill(text: '${m.age} yrs', padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(Fmt.relative(a.timestamp),
                              style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                RiskBadge(level: level),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: 'BP ${m.systolic}/${m.diastolic}',
                        style: TextStyle(color: level == RiskLevel.high ? AppColors.riskHigh : null),
                      ),
                      const TextSpan(text: '  •  '),
                      TextSpan(text: 'HR ${m.heartRate} bpm'),
                    ]),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Patient card used on the Patients list (Stitch patients_list).
/// Hierarchy: ID + age, risk badge, then the two key vitals.
class PatientListCard extends StatelessWidget {
  const PatientListCard({super.key, required this.patient, required this.onTap});

  final Patient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latest = patient.latest;
    final level = patient.currentRisk;
    final m = latest?.indicators;

    return AppCard(
      onTap: onTap,
      radius: AppRadius.lg,
      semanticLabel: 'Patient ${patient.id}, ${patient.age} years, '
          '${level?.label ?? 'not yet assessed'}'
          '${m != null ? ', blood pressure ${m.systolic} over ${m.diastolic}, heart rate ${m.heartRate}' : ''}',
      child: ExcludeSemantics(
        child: LayoutBuilder(builder: (context, c) {
          return Column(
            children: [
              Row(
                children: [
                  PatientNumberTile(patient: patient),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The full ID is never truncated.
                        Text(patient.id, style: AppTextStyles.titleMd),
                        const SizedBox(height: 2),
                        Text('${patient.age} years',
                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (level != null) RiskBadge(level: level, short: c.maxWidth < 300),
                  const Icon(Icons.chevron_right, size: 22, color: AppColors.outline),
                ],
              ),
              if (latest != null && m != null) ...[
                const Divider(height: 24, color: AppColors.divider),
                Row(
                  children: [
                    Text('BP ${m.systolic}/${m.diastolic}', style: AppTextStyles.labelLg),
                    Container(
                      width: 1,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: AppColors.outlineVariant,
                    ),
                    Text('HR ${m.heartRate}', style: AppTextStyles.labelLg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Fmt.relative(latest.timestamp, withTime: false),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

/// The assessment inputs as a short label/value list (Age, Blood Pressure,
/// Blood Glucose, Body Temperature, Maternal Heart Rate) in the clinician's
/// units. Used on the Result and Patient Profile screens.
class AssessmentSummary extends StatelessWidget {
  const AssessmentSummary({super.key, required this.indicators, required this.settings});

  final MaternalIndicators indicators;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final m = indicators;
    final rows = [
      ('Age', '${m.age}', 'yrs'),
      ('Blood Pressure', '${m.systolic}/${m.diastolic}', 'mmHg'),
      ('Blood Glucose', Fmt.glucose(m.bloodGlucose, settings.glucoseUnit), settings.glucoseUnit.label),
      ('Body Temperature', Fmt.temp(m.bodyTempF, settings.tempUnit), settings.tempUnit.label),
      ('Maternal Heart Rate', '${m.heartRate}', 'bpm'),
    ];
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.divider),
          Semantics(
            label: '${rows[i].$1}: ${rows[i].$2} ${rows[i].$3}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(rows[i].$1, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                  ),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: rows[i].$2, style: AppTextStyles.labelLg),
                    TextSpan(
                      text: ' ${rows[i].$3}',
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ])),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
