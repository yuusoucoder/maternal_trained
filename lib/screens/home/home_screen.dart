import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/risk_level.dart';
import '../../navigation/app_navigator.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_header.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/patient_widgets.dart';
import '../assessment/assessment_input_screen.dart';
import '../patient_profile/patient_profile_screen.dart';

/// Stitch: home_dashboard
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Home', style: HeaderStyle.brand),
      body: AppStateBuilder(builder: (context, scope) {
        final repo = scope.repository;
        final today = repo.assessmentsOn(DateTime.now());
        final recent = repo.allAssessments.take(3).toList();
        int count(RiskLevel l) => today.where((a) => a.result.riskLevel == l).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.margin, AppSpacing.md, AppSpacing.margin, AppSpacing.xl),
          children: [
            _Greeting(name: scope.clinician.displayName),
            const SizedBox(height: AppSpacing.lg),
            _AssessHeroCard(onTap: () => AppNavigator.push(context, const AssessmentInputScreen())),
            const SizedBox(height: AppSpacing.lg),
            _TodayOverview(
              total: today.length,
              low: count(RiskLevel.low),
              moderate: count(RiskLevel.moderate),
              high: count(RiskLevel.high),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SectionTitle(
                'Recent Assessments',
                trailing: LinkButton(
                  label: 'All Patients',
                  trailingIcon: Icons.chevron_right,
                  onPressed: () => AppNavigator.currentTab.value = ShellTab.patients,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (recent.isEmpty)
              const InfoNote(text: 'No assessments yet. Start with "Assess New Patient".', icon: Icons.info_outline)
            else
              for (final a in recent) ...[
                RecentAssessmentCard(
                  assessment: a,
                  onTap: () => AppNavigator.push(context, PatientProfileScreen(patientId: a.patientId)),
                ),
                const SizedBox(height: 12),
              ],
          ],
        );
      }),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('${Fmt.greeting()}, $name', style: AppTextStyles.headlineMd),
        ),
        const SizedBox(height: 4),
        Text('Ready for the next assessment?', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

/// Big gradient "Assess New Patient" card – the strongest element on Home.
class _AssessHeroCard extends StatefulWidget {
  const _AssessHeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_AssessHeroCard> createState() => _AssessHeroCardState();
}

class _AssessHeroCardState extends State<_AssessHeroCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(AppRadius.card);
    return Semantics(
      button: true,
      label: 'Assess New Patient. Enter 6 clinical maternal indicators for decision support and risk grading.',
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(borderRadius: br, boxShadow: AppShadows.primaryGlow),
          child: Material(
            borderRadius: br,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryContainer],
                ),
              ),
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      bottom: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [Colors.white.withAlpha(36), Colors.white.withAlpha(0)]),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: Colors.white.withAlpha(51), shape: BoxShape.circle),
                                child: const Icon(Icons.add, size: 28, color: Colors.white),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  // darker than Stitch's white/20 so the label passes contrast
                                  color: AppColors.onPrimaryFixedVariant.withAlpha(115),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text('BEDSIDE TRIAGE',
                                    style: AppTextStyles.labelSm.copyWith(color: Colors.white, letterSpacing: 0.9)),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text('Assess New Patient', style: AppTextStyles.headlineSm.copyWith(color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(
                            'Enter 6 clinical maternal indicators for instant decision support & risk grading.',
                            style: AppTextStyles.bodyMd.copyWith(color: Colors.white.withAlpha(235)),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Text('Start assessment',
                                  style:
                                      AppTextStyles.labelMd.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayOverview extends StatelessWidget {
  const _TodayOverview({required this.total, required this.low, required this.moderate, required this.high});

  final int total;
  final int low;
  final int moderate;
  final int high;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Text("TODAY'S ASSESSMENTS", style: AppTextStyles.overline)),
              Semantics(
                label: '$total assessments today',
                excludeSemantics: true,
                child: Text('$total', style: AppTextStyles.headlineMd),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(
              children: [
                Expanded(child: _CountPill(level: RiskLevel.low, count: low)),
                const SizedBox(width: 6),
                Expanded(child: _CountPill(level: RiskLevel.moderate, count: moderate)),
                const SizedBox(width: 6),
                Expanded(child: _CountPill(level: RiskLevel.high, count: high)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 6,
                child: total == 0
                    ? Container(color: AppColors.surfaceContainer)
                    : Row(
                        children: [
                          if (low > 0) Expanded(flex: low, child: Container(color: RiskLevel.low.color)),
                          if (moderate > 0) Expanded(flex: moderate, child: Container(color: RiskLevel.moderate.color)),
                          if (high > 0) Expanded(flex: high, child: Container(color: RiskLevel.high.color)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.level, required this.count});

  final RiskLevel level;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${level.shortLabel} risk: $count',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: AppShadows.sm,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: level.color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('${level.shortLabel}:', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(width: 4),
              Text('$count', style: AppTextStyles.labelLg.copyWith(color: level.textColor)),
            ],
          ),
        ),
      ),
    );
  }
}
