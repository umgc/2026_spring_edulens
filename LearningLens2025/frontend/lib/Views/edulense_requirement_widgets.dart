import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// EduLense requirement support widgets added for the Spring 2026 requirement
/// expansion. These widgets are intentionally self-contained so they can be
/// dropped into existing views without forcing disruptive refactors.
///
/// Added capabilities:
///  - Workflow stage visibility for task-based workflow integration.
///  - Provenance labels for AI suggestion vs student decision vs authored work.
///  - Embedded AI literacy / integrity nudges with micro-reflection prompts.
///  - Teacher-facing evaluation configuration summaries.
///  - Actionable analytics insight cards for class-level and student-level use.
/// ---------------------------------------------------------------------------

class EduLenseWorkflowStage {
  const EduLenseWorkflowStage({
    required this.title,
    required this.description,
    required this.isComplete,
    this.isCurrent = false,
  });

  final String title;
  final String description;
  final bool isComplete;
  final bool isCurrent;
}

class EduLenseWorkflowTrackerCard extends StatelessWidget {
  const EduLenseWorkflowTrackerCard({
    super.key,
    required this.stages,
    required this.aiUseLevel,
    required this.onAiUseLevelChanged,
    required this.microReflectionPrompt,
    required this.microReflectionAnswer,
    required this.onMicroReflectionChanged,
  });

  final List<EduLenseWorkflowStage> stages;
  final String aiUseLevel;
  final ValueChanged<String?> onAiUseLevelChanged;
  final String microReflectionPrompt;
  final String microReflectionAnswer;
  final ValueChanged<String> onMicroReflectionChanged;

  static const List<String> _aiUseLevels = <String>[
    'Hinting only',
    'Guided revision',
    'Co-drafting',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alt_route, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Workflow + AI Literacy Scaffold',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Added for the Spring 2026 workflow requirements so students can see where they are in the task and why AI is being used.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ...stages.map(
              (stage) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      stage.isComplete
                          ? Icons.check_circle
                          : stage.isCurrent
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                      size: 18,
                      color: stage.isComplete
                          ? Colors.green
                          : stage.isCurrent
                              ? theme.colorScheme.primary
                              : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            stage.description,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            DropdownButtonFormField<String>(
              value: aiUseLevel,
              decoration: const InputDecoration(
                labelText: 'AI use level',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _aiUseLevels
                  .map(
                    (level) => DropdownMenuItem<String>(
                      value: level,
                      child: Text(level),
                    ),
                  )
                  .toList(),
              onChanged: onAiUseLevelChanged,
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: ValueKey<String>(microReflectionPrompt),
              initialValue: microReflectionAnswer,
              minLines: 2,
              maxLines: 4,
              onChanged: onMicroReflectionChanged,
              decoration: InputDecoration(
                labelText: microReflectionPrompt,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EduLenseProvenanceLegendCard extends StatelessWidget {
  const EduLenseProvenanceLegendCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Contribution Labels',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(Icons.smart_toy_outlined, size: 16),
                  label: Text('AI suggestion'),
                ),
                Chip(
                  avatar: Icon(Icons.rule_outlined, size: 16),
                  label: Text('Student decision'),
                ),
                Chip(
                  avatar: Icon(Icons.edit_outlined, size: 16),
                  label: Text('Student-authored content'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Added to better separate generated help from student choices and student writing during workflow review.',
            ),
          ],
        ),
      ),
    );
  }
}

class EduLenseEvaluationConfigurationCard extends StatelessWidget {
  const EduLenseEvaluationConfigurationCard({
    super.key,
    required this.tone,
    required this.voice,
    required this.detailLevel,
    required this.feedbackMode,
    required this.supportsRubricAlignment,
  });

  final String tone;
  final String voice;
  final String detailLevel;
  final String feedbackMode;
  final bool supportsRubricAlignment;

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, String>>[
      MapEntry('Tone', tone),
      MapEntry('Voice', voice),
      MapEntry('Detail', detailLevel),
      MapEntry('Feedback style', feedbackMode),
      MapEntry(
        'Alignment mode',
        supportsRubricAlignment ? 'Rubric-aligned' : 'Criteria-referenced',
      ),
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teacher-Controlled Qualitative Feedback',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Added to surface the expanded evaluation requirement: teachers can tune tone, voice, and detail without changing the underlying score logic.',
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        item.key,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(child: Text(item.value)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EduLenseActionableInsightsCard extends StatelessWidget {
  const EduLenseActionableInsightsCard({
    super.key,
    required this.totalStudents,
    required this.averageGrade,
    required this.assignmentType,
    required this.classInsights,
    required this.studentInsights,
  });

  final int totalStudents;
  final double? averageGrade;
  final String assignmentType;
  final List<String> classInsights;
  final List<String> studentInsights;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actionable Analytics Snapshot',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Students: $totalStudents')),
                Chip(label: Text('Type: $assignmentType')),
                Chip(
                  label: Text(
                    averageGrade == null
                        ? 'Average grade: n/a'
                        : 'Average grade: ${averageGrade!.toStringAsFixed(1)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InsightSection(
              title: 'Class-level insights',
              entries: classInsights,
            ),
            const SizedBox(height: 12),
            _InsightSection(
              title: 'Student-level insights',
              entries: studentInsights,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({required this.title, required this.entries});

  final String title;
  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        if (entries.isEmpty)
          const Text('No insight generated yet for the current selection.')
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(entry)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
