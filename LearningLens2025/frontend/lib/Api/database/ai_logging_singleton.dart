import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/beans/ai_log.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class AILoggingSingleton {
  static final AILoggingSingleton _singleton = AILoggingSingleton._internal();
  static const String _defaultLabel = "general";

  factory AILoggingSingleton() {
    return _singleton;
  }
  AILoggingSingleton._internal();

  Future<void> createDb() async {
    final url =
        Uri.parse("${LocalStorageService.getAILoggingUrl()}/?command=createDb");
    await http.post(url);
  }

  Future<void> clearOldDatabaseEntries() async {
    final url =
        Uri.parse("${LocalStorageService.getAILoggingUrl()}/?command=clearDb");
    await http.post(url);
  }

  Future<List<AiLog>> getLogs(
      Course course,
      Assignment? assignment,
      Participant? student,
      int lmsType,
      DateTime startDate,
      DateTime endDate) async {
    final list = <AiLog>[];
    final courseId = course.id;
    final assignmentIdParam = assignment?.id ?? -1;
    final studentIdParam = student?.id ?? -1;
    final url = Uri.parse(
        "${LocalStorageService.getAILoggingUrl()}/?command=getLogs&courseId=$courseId&assignmentId=$assignmentIdParam&studentId=$studentIdParam&lmsType=$lmsType&startDate=${getDateString(startDate)}&endDate=${getDateString(endDate)}");

    final response = await http.get(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Failed to fetch logs: HTTP ${response.statusCode}");
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception("Invalid logs payload format.");
    }

    final assignmentMap = <int, Assignment>{
      for (final essay in (course.essays ?? const <Assignment>[]))
        essay.id: essay
    };
    final participants = await LmsFactory.getLmsService()
        .getCourseParticipants(courseId.toString());
    final participantMap = <int, Participant>{
      for (final p in participants) p.id: p
    };

    for (final row in decoded) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);

      final assignmentId = int.tryParse(map["assignment_id"].toString());
      final studentId = int.tryParse(map["student_id"].toString());
      final modelIndex = int.tryParse(map["ai_model"].toString());
      final createdAt = DateTime.tryParse(map["time"]?.toString() ?? "");
      if (assignmentId == null ||
          studentId == null ||
          modelIndex == null ||
          createdAt == null) {
        continue;
      }

      final assignmentObj = assignmentMap[assignmentId];
      final studentObj = participantMap[studentId];
      if (assignmentObj == null || studentObj == null) {
        continue;
      }

      if (modelIndex < 0 || modelIndex >= LlmType.values.length) {
        continue;
      }

      list.add(AiLog(
          course,
          assignmentObj,
          studentObj,
          map["prompt"]?.toString() ?? "",
          map["response"]?.toString() ?? "",
          LlmType.values[modelIndex],
          map["reflection"]?.toString() ?? "",
          map["log_id"]?.toString() ?? "",
          map["label"]?.toString() ?? _defaultLabel,
          LocalStorageService.getSelectedClassroom(),
          createdAt));
    }

    return list;
  }

  String getDateString(DateTime date) {
    return date.toUtc().toString();
  }

  Future<String> addLog(AiLog log) async {
    final url =
        Uri.parse("${LocalStorageService.getAILoggingUrl()}/?command=addLog");
    final header = {'content-type': 'application/json'};
    final body = jsonEncode(log.toJson());

    final response = await http.post(url, headers: header, body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Failed to add log: HTTP ${response.statusCode}");
    }
    return response.body;
  }
}
