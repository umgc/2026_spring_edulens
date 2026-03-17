// EDU-LENSE 2026 SPRING ADDITIONS
// -----------------------------------------------------------------------------
// These lightweight models add support for the newly expanded requirements:
// - Task-based workflow tracking with stage markers and transition prompts
// - Assessment-aware integrity nudges / AI literacy scaffolding
// - Visual-material / image integration metadata
// - Teacher-controlled qualitative feedback configuration scaffolding
// - Actionable analytics insight cards
//
// The goal is to provide additive data structures that can be wired into the
// existing UI without removing or breaking prior behavior.
// -----------------------------------------------------------------------------

class WorkflowStageInfo {
  final String key;
  final String label;
  final String prompt;

  const WorkflowStageInfo({
    required this.key,
    required this.label,
    required this.prompt,
  });
}

class WorkflowStepLog {
  final String id;
  final String stageKey;
  final String actorLabel; // e.g. student-authored / ai-suggestion / student-decision
  final String actionLabel;
  final String detail;
  final DateTime timestamp;

  const WorkflowStepLog({
    required this.id,
    required this.stageKey,
    required this.actorLabel,
    required this.actionLabel,
    required this.detail,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'stageKey': stageKey,
        'actorLabel': actorLabel,
        'actionLabel': actionLabel,
        'detail': detail,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WorkflowStepLog.fromJson(Map<String, dynamic> json) => WorkflowStepLog(
        id: json['id']?.toString() ?? '',
        stageKey: json['stageKey']?.toString() ?? 'understand',
        actorLabel: json['actorLabel']?.toString() ?? 'student-authored',
        actionLabel: json['actionLabel']?.toString() ?? 'Recorded step',
        detail: json['detail']?.toString() ?? '',
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class IntegrityNudge {
  final String title;
  final String prompt;
  final String aiUseLevel;

  const IntegrityNudge({
    required this.title,
    required this.prompt,
    required this.aiUseLevel,
  });
}

class VisualMaterialAsset {
  final String id;
  final String title;
  final String assetType; // diagram / scenario-card / annotated-example / avatar / image
  final String sourceLabel; // teacher-uploaded / ai-generated / local-placeholder
  final String note;

  const VisualMaterialAsset({
    required this.id,
    required this.title,
    required this.assetType,
    required this.sourceLabel,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'assetType': assetType,
        'sourceLabel': sourceLabel,
        'note': note,
      };

  factory VisualMaterialAsset.fromJson(Map<String, dynamic> json) =>
      VisualMaterialAsset(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Untitled asset',
        assetType: json['assetType']?.toString() ?? 'image',
        sourceLabel: json['sourceLabel']?.toString() ?? 'teacher-uploaded',
        note: json['note']?.toString() ?? '',
      );
}

class EvaluationFeedbackConfig {
  final String tone;
  final String voice;
  final String detailLevel;
  final bool rubricAligned;
  final bool criteriaReferenced;

  const EvaluationFeedbackConfig({
    this.tone = 'Supportive',
    this.voice = 'Teacher Coach',
    this.detailLevel = 'Balanced',
    this.rubricAligned = true,
    this.criteriaReferenced = true,
  });
}

class ActionableInsight {
  final String title;
  final String description;
  final String audience; // class / student / teacher

  const ActionableInsight({
    required this.title,
    required this.description,
    required this.audience,
  });
}

const List<WorkflowStageInfo> kEduLenseWorkflowStages = [
  WorkflowStageInfo(
    key: 'understand',
    label: 'Understand Prompt',
    prompt:
        'Clarify the task, audience, constraints, and what success looks like before drafting.',
  ),
  WorkflowStageInfo(
    key: 'plan',
    label: 'Plan',
    prompt:
        'Organize ideas, identify evidence, and decide how much AI support is appropriate.',
  ),
  WorkflowStageInfo(
    key: 'draft',
    label: 'Draft',
    prompt:
        'Write student-authored content and use AI as bounded support rather than final-answer generation.',
  ),
  WorkflowStageInfo(
    key: 'revise',
    label: 'Revise',
    prompt:
        'Critique AI suggestions, explain changes, and strengthen clarity, structure, and integrity.',
  ),
  WorkflowStageInfo(
    key: 'reflect',
    label: 'Reflect',
    prompt:
        'Explain what AI helped with, what you changed yourself, and why you accepted or rejected suggestions.',
  ),
  WorkflowStageInfo(
    key: 'submit',
    label: 'Submit',
    prompt:
        'Review the final work, confirm authorship, and export a teacher-friendly summary plus the full process log.',
  ),
];
