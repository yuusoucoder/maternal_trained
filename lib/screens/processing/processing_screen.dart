import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/app_settings.dart';
import '../../models/assessment.dart';
import '../../models/maternal_indicators.dart';
import '../../models/risk_result.dart';
import '../../navigation/app_navigator.dart';
import '../../services/risk_classifier.dart';
import '../../state/app_scope.dart';
import '../../widgets/aiovy_logo.dart';
import '../../widgets/app_header.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../result/result_screen.dart';

/// Stitch: assessment_processing. Simulated loading, then auto-navigates
/// to the result. The classifier call runs in parallel with the animation.
class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({
    super.key,
    required this.patientId,
    required this.indicators,
    required this.isNewPatient,
  });

  final String patientId;
  final MaternalIndicators indicators;
  final bool isNewPatient;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  /// 0 = validating, 1 = classifying, 2 = SHAP, 3 = done
  int _step = 0;
  final List<Timer> _timers = [];
  bool _started = false;

  /// Readable reason the classification failed; null while running.
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _run();
  }

  Future<void> _run() async {
    final scope = AppScope.of(context);
    _timers.add(Timer(const Duration(milliseconds: 700), () => _setStep(1)));
    _timers.add(Timer(const Duration(milliseconds: 1700), () => _setStep(2)));

    final RiskResult result;
    try {
      final resultFuture = scope.classifier.classify(widget.indicators);
      await Future.wait([resultFuture, Future<void>.delayed(const Duration(milliseconds: 2600))]);
      result = await resultFuture;
    } on RiskClassifierException catch (e) {
      _fail(e.message);
      return;
    } catch (e) {
      debugPrint('Classification failed: $e');
      _fail('Something went wrong while classifying this assessment. Please try again.');
      return;
    }
    if (!mounted) return;
    _setStep(3);

    final now = DateTime.now();
    final assessment = Assessment(
      id: 'A-${widget.patientId}-${now.millisecondsSinceEpoch}',
      patientId: widget.patientId,
      timestamp: now,
      indicators: widget.indicators,
      result: result,
      assessedBy: scope.clinician.displayName,
      type: widget.isNewPatient ? 'Initial Intake' : 'Routine Assessment',
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    AppNavigator.replace(context, ResultScreen(assessment: assessment), rise: true);
  }

  void _setStep(int s) {
    if (mounted) setState(() => _step = s);
  }

  /// Stops the animation and marks the classification step as failed.
  void _fail(String message) {
    _cancelTimers();
    if (!mounted) return;
    _pulse.stop();
    setState(() {
      _step = 1;
      _error = message;
    });
  }

  void _retry() {
    setState(() {
      _step = 0;
      _error = null;
    });
    _pulse.repeat();
    _run();
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  @override
  void dispose() {
    _cancelTimers();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.indicators;
    final scope = AppScope.of(context);
    final s = scope.settings;
    final temp = '${Fmt.temp(m.bodyTempF, s.tempUnit)}${s.tempUnit.label}';
    final error = _error;

    return Scaffold(
      appBar: const AppHeader(title: 'Assessment Processing', style: HeaderStyle.backCentered),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(0, -0.55),
                child: Container(
                  width: 560,
                  height: 560,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppColors.primaryFixed.withAlpha(150), AppColors.primaryFixed.withAlpha(0)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.margin, AppSpacing.md, AppSpacing.margin, AppSpacing.lg),
              children: [
                Center(
                  child: Pill(
                    text: 'Patient ${widget.patientId} · ${m.age} yrs',
                    dotColor: AppColors.primary,
                    background: AppColors.surfaceLow,
                    style: AppTextStyles.labelMd,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(child: _PulseRings(animation: _pulse)),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error != null
                        ? 'Assessment could not be completed'
                        : _step >= 3
                            ? 'Classification complete'
                            : 'Evaluating Maternal Indicators…',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineSm,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  error != null
                      ? 'No result was saved. The values you entered are kept.'
                      : 'Applying the risk classification model to 6 physiological indicators.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  radius: AppRadius.md,
                  child: Column(
                    children: [
                      _StepRow(
                        number: 1,
                        title: 'Maternal indicators validated',
                        subtitle: 'BP ${m.systolic}/${m.diastolic} · HR ${m.heartRate} · $temp · '
                            'BG ${Fmt.glucose(m.bloodGlucose, s.glucoseUnit)}',
                        state: _stateFor(0),
                      ),
                      const Divider(height: 24, color: AppColors.divider),
                      _StepRow(
                        number: 2,
                        title: 'Classifying risk level',
                        subtitle: 'Low · Moderate · High probability distribution',
                        state: _stateFor(1),
                      ),
                      const Divider(height: 24, color: AppColors.divider),
                      _StepRow(
                        number: 3,
                        title: 'Generating SHAP contributions',
                        subtitle: 'Explainable risk insights',
                        state: _stateFor(2),
                      ),
                    ],
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  InfoNote(
                    title: 'Classification failed',
                    text: error,
                    icon: Icons.error_outline,
                    iconColor: AppColors.error,
                    background: AppColors.riskHighTint,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(label: 'Try Again', leadingIcon: Icons.refresh, onPressed: _retry),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Edit Indicators',
                    leadingIcon: Icons.edit_outlined,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                InfoNote(
                  text: scope.classifier.isDemo
                      ? 'AIOVY v1.0 · Thesis Prototype · Demo classifier – not a trained model.'
                      : 'AIOVY v1.0 · Thesis Prototype · ${scope.classifier.modelName}',
                  circleIcon: false,
                  background: AppColors.surfaceLow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StepState _stateFor(int index) {
    if (_step > index) return _StepState.done;
    if (_step == index) return _error != null ? _StepState.failed : _StepState.active;
    return _StepState.pending;
  }
}

enum _StepState { pending, active, done, failed }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.title, required this.subtitle, required this.state});

  final int number;
  final String title;
  final String subtitle;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final Widget leading = switch (state) {
      _StepState.done => const IconTile(
          icon: Icons.check,
          size: 30,
          iconSize: 18,
          circle: true,
          background: AppColors.riskLowTint,
          foreground: AppColors.riskLow,
        ),
      _StepState.active => Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
          padding: const EdgeInsets.all(7),
          child: const CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
        ),
      _StepState.pending => Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(color: AppColors.surfaceContainer, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Container(
              width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.outline, shape: BoxShape.circle)),
        ),
      _StepState.failed => const IconTile(
          icon: Icons.close,
          size: 30,
          iconSize: 18,
          circle: true,
          background: AppColors.riskHighTint,
          foreground: AppColors.error,
        ),
    };
    final stateText = switch (state) {
      _StepState.done => 'complete',
      _StepState.active => 'in progress',
      _StepState.pending => 'waiting',
      _StepState.failed => 'failed',
    };
    return Semantics(
      label: 'Step $number, $title, $stateText',
      excludeSemantics: true,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: AppTextStyles.labelLg.copyWith(
                    color: state == _StepState.active ? AppColors.primary : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          if (state == _StepState.done)
            const Pill(
              text: 'Done',
              background: AppColors.riskLowTint,
              foreground: AppColors.riskLow,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            )
          else if (state == _StepState.pending)
            const Icon(Icons.hourglass_empty, size: 18, color: AppColors.outline),
        ],
      ),
    );
  }
}

class _PulseRings extends StatelessWidget {
  const _PulseRings({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 240,
        height: 240,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                for (var k = 0; k < 2; k++)
                  Builder(builder: (_) {
                    final p = (t + k * 0.5) % 1.0;
                    return Opacity(
                      opacity: (1 - p) * 0.55,
                      child: Container(
                        width: 150 + 90 * p,
                        height: 150 + 90 * p,
                        decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                      ),
                    );
                  }),
                Container(
                  width: 156,
                  height: 156,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceLowest,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.md,
                  ),
                ),
                Container(
                  width: 112,
                  height: 112,
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceLowest,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x1A2D1924), blurRadius: 24, offset: Offset(0, 10))],
                  ),
                  child: const AiovyLogoMark(size: 84),
                ),
                Transform.rotate(
                  angle: t * 2 * math.pi,
                  child: SizedBox(
                    width: 196,
                    height: 196,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceLowest,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.sm,
                        ),
                        child: const Icon(Icons.spa_outlined, size: 15, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
