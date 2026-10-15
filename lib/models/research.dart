import 'package:flutter/material.dart';

/// One candidate model on the research dashboard.
@immutable
class ModelInfo {
  const ModelInfo({
    required this.name,
    required this.subtitle,
    required this.tag,
    required this.description,
    required this.metrics,
  });

  final String name;
  final String subtitle;
  final String tag;
  final String description;

  /// Metric name → value. `null` means "Pending Evaluation".
  final Map<String, String?> metrics;
}

/// One stage of the end-to-end research pipeline.
@immutable
class PipelineStage {
  const PipelineStage({
    required this.title,
    required this.description,
    required this.icon,
    this.branches = const [],
  });

  final String title;
  final String description;
  final IconData icon;

  /// Parallel items shown side by side (used for the three models).
  final List<String> branches;
}

@immutable
class Reference {
  const Reference({required this.authors, required this.title, required this.venue});

  final String authors;
  final String title;
  final String venue;
}

/// Everything shown on "How AIOVY Works".
@immutable
class ResearchMetrics {
  const ResearchMetrics({
    required this.models,
    required this.pipeline,
    required this.references,
    required this.protocolId,
    required this.validationStrategy,
    this.selectedModel,
  });

  final List<ModelInfo> models;
  final List<PipelineStage> pipeline;
  final List<Reference> references;
  final String protocolId;
  final String validationStrategy;

  /// `null` until the thesis evaluation picks a model.
  final String? selectedModel;
}
