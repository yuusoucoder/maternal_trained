import 'package:flutter/widgets.dart';

import '../data/repositories/app_settings.dart';
import '../data/repositories/patient_repository.dart';
import '../models/clinician.dart';
import '../services/risk_classifier.dart';

/// Makes the app-wide services available to every screen without extra
/// packages. Widgets that call `AppScope.of(context)` rebuild when the
/// repository or settings change.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repository,
    required this.settings,
    required this.classifier,
    required this.clinician,
    required super.child,
  });

  final PatientRepository repository;
  final AppSettings settings;
  final RiskClassifier classifier;
  final Clinician clinician;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      repository != oldWidget.repository ||
      settings != oldWidget.settings ||
      classifier != oldWidget.classifier ||
      clinician != oldWidget.clinician;
}

/// Rebuilds [builder] whenever the repository or settings notify.
class AppStateBuilder extends StatelessWidget {
  const AppStateBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, AppScope scope) builder;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.repository, scope.settings]),
      builder: (context, _) => builder(context, scope),
    );
  }
}
