import 'package:flutter/material.dart';

import '../../models/research.dart';

/// Research dashboard content. Metric values are intentionally `null`
/// ("Pending Evaluation") – do not put thesis results here until the
/// experiments are complete.
class MockResearch {
  MockResearch._();

  static const List<String> metricNames = ['Accuracy', 'Precision', 'Recall', 'F1-Score', 'AUC-ROC'];

  static Map<String, String?> _pending() => {for (final m in metricNames) m: null};

  static ResearchMetrics build() => ResearchMetrics(
        selectedModel: null,
        protocolId: 'THESIS-MHR-2025-V2',
        validationStrategy: 'Repeated Stratified Cross-Validation',
        models: [
          ModelInfo(
            name: 'Logistic Regression',
            subtitle: 'Baseline Generalized Linear Model (GLM)',
            tag: 'Linear Model',
            description: 'Parametric statistical benchmark. Evaluates direct linear relationships '
                'across indicators with deterministic convergence.',
            metrics: _pending(),
          ),
          ModelInfo(
            name: 'Random Forest',
            subtitle: 'Ensemble Bagging Architecture',
            tag: 'Ensemble Bagging',
            description: 'Parallel decision tree ensemble. Aggregates bootstrapped decision splits '
                'to reduce variance across physiological measurements.',
            metrics: _pending(),
          ),
          ModelInfo(
            name: 'Extreme Gradient Boosting (XGBoost)',
            subtitle: 'Sequential Gradient Tree Boosting',
            tag: 'Gradient Boosting',
            description: 'Sequential gradient boosted decision trees optimizing pseudo-residuals '
                'to model complex non-linear indicator interactions.',
            metrics: _pending(),
          ),
        ],
        pipeline: const [
          PipelineStage(
            title: 'Maternal Health Data',
            description: 'Six maternal indicators: age, systolic & diastolic BP, blood glucose, '
                'body temperature and heart rate.',
            icon: Icons.storage_outlined,
          ),
          PipelineStage(
            title: 'Preprocessing',
            description: 'Cleaning, duplicate handling, scaling and stratified train/test splitting.',
            icon: Icons.tune,
          ),
          PipelineStage(
            title: 'Model Training',
            description: 'Three candidate classifiers trained on identical folds.',
            icon: Icons.model_training,
            branches: ['Logistic Regression', 'Random Forest', 'XGBoost'],
          ),
          PipelineStage(
            title: 'Model Evaluation',
            description: 'Accuracy, Precision, Recall, F1-Score and AUC-ROC under repeated '
                'stratified cross-validation.',
            icon: Icons.analytics_outlined,
          ),
          PipelineStage(
            title: 'Selected Model',
            description: 'Chosen strictly from empirical results – no model is assumed superior.',
            icon: Icons.emoji_events_outlined,
          ),
          PipelineStage(
            title: 'SHAP Explainability',
            description: 'Per-assessment feature attributions show how each indicator moved the '
                'classification.',
            icon: Icons.insights,
          ),
          PipelineStage(
            title: 'SHAP Stability Analysis',
            description: 'Consistency of attributions across resampling and cross-validation folds.',
            icon: Icons.verified_outlined,
          ),
        ],
        references: const [
          Reference(
            authors: 'Lundberg, S. M., & Lee, S.-I. (2017)',
            title: 'A Unified Approach to Interpreting Model Predictions.',
            venue: 'Advances in Neural Information Processing Systems 30 (NeurIPS 2017).',
          ),
          Reference(
            authors: 'Ahmed, M., Kashem, M. A., Rahman, M., & Khatun, S. (2020)',
            title: 'Review and Analysis of Risk Factor of Maternal Health in Remote Area Using '
                'the Internet of Things (IoT).',
            venue: 'InECCE2019, Lecture Notes in Electrical Engineering, vol. 632. Springer. '
                '(Source of the Maternal Health Risk dataset, UCI ML Repository.)',
          ),
        ],
      );
}
