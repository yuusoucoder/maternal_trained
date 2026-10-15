import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/patient.dart';
import '../../models/risk_level.dart';
import '../../navigation/app_navigator.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_header.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/patient_widgets.dart';
import '../../widgets/risk_badge.dart';
import '../patient_profile/patient_profile_screen.dart';

/// Stitch: patients_list
class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _search = TextEditingController();
  RiskLevel? _filter; // null = All

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Patient> _apply(List<Patient> all) {
    final q = _search.text.trim().toLowerCase().replaceAll(' ', '');
    return all.where((p) {
      if (_filter != null && p.currentRisk != _filter) return false;
      if (q.isEmpty) return true;
      final id = p.id.toLowerCase();
      return id.contains(q) || id.replaceAll('-', '').contains(q) || p.shortNumber.contains(q);
    }).toList();
  }

  void _reset() {
    _search.clear();
    setState(() => _filter = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Patients', style: HeaderStyle.wordmark),
      body: AppStateBuilder(builder: (context, scope) {
        final repo = scope.repository;
        final all = repo.patients;
        final visible = _apply(all);

        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.margin, AppSpacing.md, AppSpacing.margin, 0),
              sliver: SliverList.list(children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  style: AppTextStyles.bodyMd.copyWith(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search by Patient ID (e.g. P-0012)',
                    hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
                    prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.cancel, color: AppColors.outline, size: 20),
                            onPressed: () => setState(_search.clear),
                          ),
                    filled: true,
                    fillColor: AppColors.surfaceLowest,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.fieldBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ]),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 64,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin, vertical: 10),
                  children: [
                    _FilterChip(
                      label: 'All',
                      count: all.length,
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final l in [RiskLevel.high, RiskLevel.moderate, RiskLevel.low])
                      _FilterChip(
                        label: l.label,
                        count: repo.countByRisk(l),
                        dot: l.color,
                        selected: _filter == l,
                        onTap: () => setState(() => _filter = _filter == l ? null : l),
                      ),
                  ],
                ),
              ),
            ),
            if (visible.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _EmptyState(onReset: _reset))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => PatientListCard(
                    patient: visible[i],
                    onTap: () => AppNavigator.push(context, PatientProfileScreen(patientId: visible[i].id)),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        );
      }),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.dot,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label filter, $count patients',
        excludeSemantics: true,
        child: Material(
          color: selected ? AppColors.primary : AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(99),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: selected ? null : Border.all(color: AppColors.fieldBorder),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dot != null) ...[
                    RiskDot(color: selected ? Colors.white : dot!),
                    const SizedBox(width: 6),
                  ],
                  Text(label, style: AppTextStyles.labelMd.copyWith(color: fg, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Text('($count)', style: AppTextStyles.labelSm.copyWith(color: fg, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const IconTile(icon: Icons.manage_search, size: 64, iconSize: 32, circle: true),
          const SizedBox(height: AppSpacing.md),
          Text('No Patients Found', style: AppTextStyles.titleMd),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your risk filter or verify the Patient ID search term.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          LinkButton(label: 'Reset Filters', leadingIcon: Icons.refresh, onPressed: onReset),
        ],
      ),
    );
  }
}
