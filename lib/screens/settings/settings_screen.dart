import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/app_settings.dart';
import '../../navigation/app_navigator.dart';
import '../../state/app_scope.dart';
import '../../widgets/aiovy_logo.dart';
import '../../widgets/app_header.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/settings_widgets.dart';

/// Stitch: settings. All controls are functional (in-memory only).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmClearCache(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_rounded, color: AppColors.riskModerate, size: 32),
        title: Text('Clear local cache?', style: AppTextStyles.headlineSm, textAlign: TextAlign.center),
        content: Text(
          'This removes draft notes and session data from this device. '
          '(Prototype: nothing is actually stored.)',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
    if (ok == true) AppNavigator.showSnack('Local cache cleared');
  }

  void _showAdvisory(BuildContext context) {
    final dataNotice = AppScope.of(context).classifier.isDemo
        ? 'All patient records and model outputs in this build are demonstration data.'
        : 'All patient records in this build are demonstration data. Risk results come from a research '
            'model trained on the public UCI Maternal Health Risk dataset and are not clinically validated.';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.gavel, color: AppColors.primary, size: 30),
        title: Text('Clinical Advisory Notice', style: AppTextStyles.headlineSm, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'AIOVY is an academic clinical decision-support prototype for maternal health risk classification. '
              'It does not replace professional clinical judgment or medical diagnosis. $dataNotice',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'Acknowledge & Close', onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Settings', style: HeaderStyle.backCentered),
      body: AppStateBuilder(builder: (context, scope) {
        final s = scope.settings;
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.margin, AppSpacing.md, AppSpacing.margin, AppSpacing.xl),
          children: [
            const SectionLabel('Units'),
            SettingsGroup(children: [
              const SettingsRow(
                icon: Icons.speed,
                title: 'Blood Pressure',
                subtitle: 'Systolic & diastolic',
                trailing: Pill(
                  text: 'mmHg',
                  background: AppColors.surfaceContainer,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              SettingsRow(
                icon: Icons.water_drop_outlined,
                title: 'Blood Glucose',
                subtitle: 'Display and entry unit',
                trailing: SegmentedToggle<GlucoseUnit>(
                  semanticLabel: 'Blood glucose unit',
                  options: GlucoseUnit.values,
                  selected: s.glucoseUnit,
                  labelOf: (u) => u.label,
                  onChanged: (u) => s.glucoseUnit = u,
                ),
              ),
              SettingsRow(
                icon: Icons.device_thermostat,
                title: 'Body Temperature',
                subtitle: 'Display and entry unit',
                trailing: SegmentedToggle<TempUnit>(
                  semanticLabel: 'Body temperature unit',
                  options: const [TempUnit.celsius, TempUnit.fahrenheit],
                  selected: s.tempUnit,
                  labelOf: (u) => u.label,
                  onChanged: (u) => s.tempUnit = u,
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('Alerts'),
            SettingsGroup(children: [
              SettingsRow(
                icon: Icons.notifications_active_outlined,
                title: 'High-Risk Alerts',
                subtitle: 'Highlight High Risk results for prompt review',
                onTap: () {
                  HapticFeedback.selectionClick();
                  s.highRiskAlerts = !s.highRiskAlerts;
                },
                trailing: AiovySwitch(
                  value: s.highRiskAlerts,
                  semanticLabel: 'High-risk alerts',
                  onChanged: (v) => s.highRiskAlerts = v,
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('Privacy & Data'),
            SettingsGroup(children: [
              const SettingsRow(
                icon: Icons.lock_outline,
                title: 'Data Storage',
                subtitle: 'Demo records only, kept in memory on this device',
              ),
              SettingsRow(
                icon: Icons.cleaning_services_outlined,
                title: 'Clear Local Cache',
                subtitle: 'Remove drafts and session data',
                showChevron: true,
                onTap: () => _confirmClearCache(context),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel('About'),
            SettingsGroup(children: [
              SettingsRow(
                icon: Icons.medical_services_outlined,
                title: 'About AIOVY',
                subtitle: AppStrings.versionShort,
                showChevron: true,
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: AppStrings.appName,
                  applicationVersion: '1.0 · Thesis Prototype',
                  applicationIcon: const AiovyLogoMark(size: 48),
                  children: [
                    Text(AppStrings.thesisTitle, style: AppTextStyles.bodyMd),
                  ],
                ),
              ),
              const SettingsRow(
                icon: Icons.school_outlined,
                title: 'Research & Design Attribution',
                subtitle: 'Undergraduate Computer Science thesis project',
              ),
              SettingsRow(
                icon: Icons.gavel,
                title: 'Clinical Disclaimer',
                subtitle: 'Limitations of this prototype',
                showChevron: true,
                onTap: () => _showAdvisory(context),
              ),
            ]),
          ],
        );
      }),
    );
  }
}
