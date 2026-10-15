import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/app_settings.dart';
import '../../navigation/app_navigator.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_header.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/settings_widgets.dart';
import '../login/login_screen.dart';
import '../research/research_screen.dart';
import '../settings/settings_screen.dart';

/// Stitch: doctor_profile
class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out of workstation?', style: AppTextStyles.headlineSm),
        content: Text('You will return to the clinical sign-in screen.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      AppNavigator.currentTab.value = ShellTab.home;
      AppNavigator.resetTo(context, const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No avatar here: it would only link to this same tab.
      appBar: const AppHeader(title: 'Profile', style: HeaderStyle.wordmark, showAvatar: false),
      body: AppStateBuilder(builder: (context, scope) {
        final repo = scope.repository;
        final c = scope.clinician;
        final assessments = repo.allAssessments;
        final patients = repo.patients;
        final complete = patients.where((p) => p.latest != null).length;
        final completePct = patients.isEmpty ? 0 : (complete / patients.length * 100).round();

        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.margin, AppSpacing.md, AppSpacing.margin, AppSpacing.xl),
          children: [
            // Identity card
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primaryFixedDim, AppColors.primary],
                          ),
                        ),
                        child: Text(c.initials, style: AppTextStyles.headlineMd.copyWith(color: Colors.white)),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Semantics(
                          label: 'On shift',
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.riskLow,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text(c.displayName, style: AppTextStyles.headlineMd)),
                        const SizedBox(height: 4),
                        Pill(
                          text: c.role,
                          background: AppColors.primaryFixed,
                          foreground: AppColors.onPrimaryFixedVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(c.affiliation, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _StatCard(value: '${assessments.length}', label: 'Total\nAssessments')),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _StatCard(value: '${patients.length}', label: 'Active\nPatients')),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _StatCard(value: '$completePct%', label: 'Complete\nRecords')),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('Research'),
            SettingsGroup(children: [
              SettingsRow(
                icon: Icons.model_training,
                title: 'How AIOVY Works',
                subtitle: 'Pipeline, model comparison & SHAP',
                showChevron: true,
                onTap: () => AppNavigator.push(context, const ResearchScreen()),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('Preferences'),
            SettingsGroup(children: [
              SettingsRow(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Units (${scope.settings.glucoseUnit.label}, ${scope.settings.tempUnit.label}), '
                    'alerts & privacy',
                showChevron: true,
                onTap: () => AppNavigator.push(context, const SettingsScreen()),
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),
            SecondaryButton(
              label: 'Sign Out',
              leadingIcon: Icons.logout,
              onPressed: () => _signOut(context),
            ),
            const VersionFooter(),
          ],
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value ${label.replaceAll('\n', ' ')}',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: AppTextStyles.headlineSm),
            ),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
