import 'dart:convert';

import 'package:learninglens_app/Views/essay_assistant.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/chatLog.dart';
import 'package:learninglens_app/beans/workflow_support.dart';

// class to represent an essay builder session
class EssaySession {
  Assignment essay;
  String id;
  AiMode mode;
  final List<ChatTurn> chatLog;
  String? finalText;
  String? notesText;
  List<dynamic>? draftDeltaOps; // Quill delta for essay draft
  List<dynamic>? notesDeltaOps; // Quill delta for notes

  // EDU-LENSE 2026 SPRING ADDITIONS:
  // Persist workflow markers, integrity decisions, and first-class visual assets
  // directly inside the essay session so they can be exported/reviewed later.
  String workflowStageKey;
  List<WorkflowStepLog> workflowSteps;
  List<VisualMaterialAsset> visualAssets;
  Map<String, String> integrityResponses;

  // constructor
  EssaySession({
    required this.essay,
    String? id,
    this.mode = AiMode.brainstorm,
    List<ChatTurn>? chatLog,
    String? finalText,
    String? notesText,
    this.draftDeltaOps,
    this.notesDeltaOps,
    this.workflowStageKey = 'understand',
    List<WorkflowStepLog>? workflowSteps,
    List<VisualMaterialAsset>? visualAssets,
    Map<String, String>? integrityResponses,
  })  : workflowSteps = List<WorkflowStepLog>.from(workflowSteps ?? const []),
        visualAssets = List<VisualMaterialAsset>.from(visualAssets ?? const []),
        integrityResponses = Map<String, String>.from(integrityResponses ?? const {}),
        id = id ?? essay.id.toString(),
        chatLog = List<ChatTurn>.from(chatLog ?? const []);

  // method to convert the object to json for storage
  String toJson() => jsonEncode({
        'assignmentId': essay.id,
        'name': essay.name,
        'description': essay.description,
        'dueDate': essay.dueDate?.toIso8601String(),
        'cutoffDate': essay.cutoffDate?.toIso8601String(),
        'isDraft': essay.isDraft,
        'maxAttempts': essay.maxAttempts,
        'gradingStatus': essay.gradingStatus,
        'courseId': essay.courseId,
        'mode': mode.name,
        'chatLog': chatLog.map((turn) => turn.toJson()).toList(),
        'status': EssayStatus.notStarted,
        'finalText': finalText,
        'notesText': notesText,
        'draftDeltaOps': draftDeltaOps,
        'notesDeltaOps': notesDeltaOps,
        'workflowStageKey': workflowStageKey,
        'workflowSteps': workflowSteps.map((e) => e.toJson()).toList(),
        'visualAssets': visualAssets.map((e) => e.toJson()).toList(),
        'integrityResponses': integrityResponses,
      });
  // factory constructor to rebuild session from JSON
  factory EssaySession.fromJson(Map<String, dynamic> json) {
    return EssaySession(
      essay: Assignment(
        id: json['assignmentId'],
        name: json['name'],
        description: json['description'],
        dueDate:
            json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        cutoffDate: json['cutoffDate'] != null
            ? DateTime.parse(json['cutoffDate'])
            : null,
        isDraft: json['isDraft'] ?? false,
        maxAttempts: json['maxAttempts'] ?? 0,
        gradingStatus: json['gradingStatus'] ?? 0,
        courseId: json['courseId'] ?? 0,
      ),
      mode: AiMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => AiMode.brainstorm,
      ),
      chatLog: (json['chatLog'] as List?)
              ?.map((e) => ChatTurn.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      draftDeltaOps: json['draftDeltaOps'],
      notesDeltaOps: json['notesDeltaOps'],
      workflowStageKey: json['workflowStageKey']?.toString() ?? 'understand',
      workflowSteps: (json['workflowSteps'] as List?)
              ?.map((e) => WorkflowStepLog.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      visualAssets: (json['visualAssets'] as List?)
              ?.map((e) => VisualMaterialAsset.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      integrityResponses: Map<String, String>.from(
          (json['integrityResponses'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? const {}),
    );
  }
}
