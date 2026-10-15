import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/app_settings.dart';
import '../../models/maternal_indicators.dart';
import '../../navigation/app_navigator.dart';
import '../../state/app_scope.dart';
import '../../widgets/app_header.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/dialogs.dart';
import '../processing/processing_screen.dart';
import 'indicator_input_card.dart';
import 'indicator_spec.dart';

/// Stitch: patient_assessment_input. Collects the six model indicators.
class AssessmentInputScreen extends StatefulWidget {
  const AssessmentInputScreen({super.key, this.patientId});

  /// Existing patient, or null to auto-assign a new demo ID.
  final String? patientId;

  @override
  State<AssessmentInputScreen> createState() => _AssessmentInputScreenState();
}

class _AssessmentInputScreenState extends State<AssessmentInputScreen> {
  /// Stitch demo values, entered only when the clinician taps
  /// "Fill demo values" – never pre-filled silently.
  static const _demoValues =
      MaternalIndicators(age: 29, systolic: 120, diastolic: 84, bloodGlucose: 5.6, bodyTempF: 98.4, heartRate: 78);

  final Map<Indicator, TextEditingController> _ctrl = {
    for (final i in Indicator.values) i: TextEditingController(),
  };
  final Map<Indicator, FocusNode> _focus = {for (final i in Indicator.values) i: FocusNode()};

  /// Field text when the screen opened; used to detect unsaved edits.
  final Map<Indicator, String> _initial = {};

  late String _patientId;
  late bool _isNewPatient;
  DateTime? _prefilledFrom;
  bool _submitted = false;
  bool _initialised = false;
  GlucoseUnit? _glucoseUnit;
  TempUnit? _tempUnit;
  AppSettings? _settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;

    final scope = AppScope.of(context);
    _settings = scope.settings..addListener(_onSettingsChanged);
    _glucoseUnit = scope.settings.glucoseUnit;
    _tempUnit = scope.settings.tempUnit;
    final existing = widget.patientId == null ? null : scope.repository.byId(widget.patientId!);
    _isNewPatient = existing == null;
    _patientId = existing?.id ?? scope.repository.nextPatientId();

    // Existing patients start from their last recorded values (labelled as
    // such on screen). New patients always start empty.
    final latest = existing?.latest;
    if (latest != null) {
      _fill(latest.indicators);
      _prefilledFrom = latest.timestamp;
    }
    for (final i in Indicator.values) {
      _initial[i] = _ctrl[i]!.text;
    }
  }

  void _fill(MaternalIndicators m) {
    final s = AppScope.of(context).settings;
    _ctrl[Indicator.age]!.text = '${m.age}';
    _ctrl[Indicator.systolic]!.text = '${m.systolic}';
    _ctrl[Indicator.diastolic]!.text = '${m.diastolic}';
    _ctrl[Indicator.bloodGlucose]!.text = Fmt.glucose(m.bloodGlucose, s.glucoseUnit);
    _ctrl[Indicator.bodyTemperature]!.text = Fmt.temp(m.bodyTempF, s.tempUnit);
    _ctrl[Indicator.heartRate]!.text = '${m.heartRate}';
  }

  bool get _hasEdits => Indicator.values.any((i) => _ctrl[i]!.text != (_initial[i] ?? ''));

  bool get _hasAnyValue => _ctrl.values.any((c) => c.text.trim().isNotEmpty);

  void _onSettingsChanged() {
    final s = _settings;
    if (s != null && mounted) _syncUnits(s);
  }

  @override
  void dispose() {
    _settings?.removeListener(_onSettingsChanged);
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  FieldStatus _status(Indicator i, AppSettings s) {
    final base = IndicatorSpec.of(i, s).check(_ctrl[i]!.text);
    if (base != FieldStatus.valid) return base;
    if (i == Indicator.diastolic) {
      final sys = double.tryParse(_ctrl[Indicator.systolic]!.text.trim());
      final dia = double.tryParse(_ctrl[Indicator.diastolic]!.text.trim());
      if (sys != null && dia != null && dia >= sys) return FieldStatus.crossCheck;
    }
    return FieldStatus.valid;
  }

  void _clearAll() {
    for (final c in _ctrl.values) {
      c.clear();
    }
    setState(() => _submitted = false);
    _focus[Indicator.age]!.requestFocus();
  }

  void _fillDemo() {
    FocusScope.of(context).unfocus();
    setState(() => _fill(_demoValues));
  }

  Future<void> _confirmLeave() async {
    final discard = await confirmDiscard(
      context,
      title: 'Discard entered values?',
      message: 'The indicator values you entered for Patient $_patientId have not been assessed and will be lost.',
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  void _submit(AppSettings s) {
    FocusScope.of(context).unfocus();
    final invalid = Indicator.values.where((i) => _status(i, s) != FieldStatus.valid).toList();
    if (invalid.isNotEmpty) {
      // Feedback stays in the sticky bar and on the fields themselves (a
      // floating snackbar would cover the "Assess Risk" button).
      HapticFeedback.lightImpact();
      setState(() => _submitted = true);
      _focus[invalid.first]!.requestFocus();
      return;
    }

    double v(Indicator i) => double.parse(_ctrl[i]!.text.trim());
    final indicators = MaternalIndicators(
      age: v(Indicator.age).round(),
      systolic: v(Indicator.systolic).round(),
      diastolic: v(Indicator.diastolic).round(),
      bloodGlucose: Fmt.fromDisplayGlucose(v(Indicator.bloodGlucose), s.glucoseUnit),
      bodyTempF: Fmt.fromDisplayTemp(v(Indicator.bodyTemperature), s.tempUnit),
      heartRate: v(Indicator.heartRate).round(),
    );

    AppNavigator.pushFade(
      context,
      ProcessingScreen(patientId: _patientId, indicators: indicators, isNewPatient: _isNewPatient),
    );
  }

  /// Converts already-typed values if the unit setting changed meanwhile.
  void _syncUnits(AppSettings s) {
    void convert(Indicator i, String Function(double) to) {
      final c = _ctrl[i]!;
      final v = double.tryParse(c.text.trim());
      if (v == null) return;
      final untouched = c.text == _initial[i];
      c.text = to(v);
      if (untouched) _initial[i] = c.text; // a unit switch is not an edit
    }

    if (_glucoseUnit != null && _glucoseUnit != s.glucoseUnit) {
      final from = _glucoseUnit!;
      convert(Indicator.bloodGlucose, (v) => Fmt.glucose(Fmt.fromDisplayGlucose(v, from), s.glucoseUnit));
    }
    if (_tempUnit != null && _tempUnit != s.tempUnit) {
      final from = _tempUnit!;
      convert(Indicator.bodyTemperature, (v) => Fmt.temp(Fmt.fromDisplayTemp(v, from), s.tempUnit));
    }
    _glucoseUnit = s.glucoseUnit;
    _tempUnit = s.tempUnit;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasEdits,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: const AppHeader(title: 'Clinical Assessment'),
        body: AppStateBuilder(builder: (context, scope) {
          final s = scope.settings;
          final statuses = {for (final i in Indicator.values) i: _status(i, s)};
          final validCount = statuses.values.where((x) => x == FieldStatus.valid).length;

          final cards = <Widget>[
            for (var n = 0; n < Indicator.values.length; n++)
              IndicatorInputCard(
                spec: IndicatorSpec.of(Indicator.values[n], s),
                controller: _ctrl[Indicator.values[n]]!,
                focusNode: _focus[Indicator.values[n]]!,
                status: statuses[Indicator.values[n]]!,
                showErrors: _submitted || _ctrl[Indicator.values[n]]!.text.isNotEmpty,
                crossCheckMessage: 'Must be lower than systolic',
                isLast: n == Indicator.values.length - 1,
                onChanged: (_) => setState(() {}),
                onSubmitted: () {
                  if (n < Indicator.values.length - 1) {
                    _focus[Indicator.values[n + 1]]!.requestFocus();
                  } else {
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
          ];

          final Widget? sectionAction = _hasAnyValue
              ? LinkButton(label: 'Clear all', onPressed: _clearAll, style: AppTextStyles.labelSm)
              : _isNewPatient
                  ? LinkButton(label: 'Fill demo values', onPressed: _fillDemo, style: AppTextStyles.labelSm)
                  : null;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.margin, AppSpacing.md, AppSpacing.margin, AppSpacing.lg),
                  children: [
                    Semantics(header: true, child: Text('Maternal Risk Assessment', style: AppTextStyles.headlineSm)),
                    const SizedBox(height: 2),
                    Text('All six indicators are required.',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.md),
                    _PatientStrip(patientId: _patientId, isNew: _isNewPatient, prefilledFrom: _prefilledFrom),
                    const SizedBox(height: AppSpacing.lg),
                    SectionTitle('Six Core Indicators', icon: Icons.monitor_heart_outlined, trailing: sectionAction),
                    const SizedBox(height: AppSpacing.sm),
                    for (final card in cards) ...[card, const SizedBox(height: 12)],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Inputs will be evaluated by the clinical decision-support model. '
                      'Decision remains with credentialed care team.',
                      textAlign: TextAlign.center,
                      style:
                          AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              _AssessBar(
                validCount: validCount,
                total: Indicator.values.length,
                showErrors: _submitted,
                onAssess: () => _submit(s),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// One compact line of patient context (replaces the former registry note
/// and two-tile context card).
class _PatientStrip extends StatelessWidget {
  const _PatientStrip({required this.patientId, required this.isNew, required this.prefilledFrom});

  final String patientId;
  final bool isNew;
  final DateTime? prefilledFrom;

  @override
  Widget build(BuildContext context) {
    final String detail;
    if (isNew) {
      detail = 'New record · ID auto-assigned';
    } else if (prefilledFrom != null) {
      detail = 'Pre-filled from last assessment (${Fmt.relative(prefilledFrom!, withTime: false)}). '
          'Review each value before assessing.';
    } else {
      detail = 'Existing record';
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          const IconTile(
            icon: Icons.badge_outlined,
            size: 36,
            iconSize: 18,
            circle: true,
            background: AppColors.secondaryContainer,
            foreground: AppColors.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient $patientId', style: AppTextStyles.titleMd),
                const SizedBox(height: 2),
                Text(detail, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pill(text: isNew ? 'New Record' : 'Active Record', background: AppColors.surfaceHigh),
        ],
      ),
    );
  }
}

/// Sticky bottom bar: validation progress + the primary "Assess Risk" action.
class _AssessBar extends StatelessWidget {
  const _AssessBar({
    required this.validCount,
    required this.total,
    required this.showErrors,
    required this.onAssess,
  });

  final int validCount;
  final int total;

  /// True after a submit attempt: incomplete state is shown as an error.
  final bool showErrors;
  final VoidCallback onAssess;

  @override
  Widget build(BuildContext context) {
    final ready = validCount == total;
    final error = showErrors && !ready;
    final statusColor = ready ? AppColors.riskLow : (error ? AppColors.error : AppColors.primary);
    final statusText = ready ? 'Ready' : (error ? 'Check highlighted fields' : 'Incomplete');
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Color(0x0F2D1924), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.margin, 12, AppSpacing.margin, 12),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  label: ready
                      ? 'All $total indicators valid. Ready to assess.'
                      : '$validCount of $total indicators valid. $statusText.',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      Icon(
                        ready
                            ? Icons.verified_user_outlined
                            : (error ? Icons.error_outline : Icons.pending_outlined),
                        size: 20,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$validCount of $total valid', style: AppTextStyles.labelLg),
                            Text(statusText,
                                style: AppTextStyles.labelSm
                                    .copyWith(color: error || ready ? statusColor : AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(label: 'Assess Risk', trailingIcon: Icons.arrow_forward, onPressed: onAssess),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
