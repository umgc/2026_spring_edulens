import 'dart:convert';

import 'package:learninglens_app/beans/roleplay_scenario.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class RoleplayScenarioService {
  static const String _key = 'roleplay_scenarios_v1';

  static List<RoleplayScenario> getScenarios() {
    final raw = LocalStorageService.getString(_key);
    if (raw == null || raw.trim().isEmpty) {
      return <RoleplayScenario>[];
    }

    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) {
        return <RoleplayScenario>[];
      }
      return parsed
          .whereType<Map>()
          .map((e) => RoleplayScenario.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return <RoleplayScenario>[];
    }
  }

  static void saveScenarios(List<RoleplayScenario> scenarios) {
    final encoded = jsonEncode(scenarios.map((e) => e.toJson()).toList());
    LocalStorageService.setString(_key, encoded);
  }

  static void upsertScenario(RoleplayScenario scenario) {
    final scenarios = getScenarios();
    final index = scenarios.indexWhere((s) => s.id == scenario.id);
    if (index >= 0) {
      scenarios[index] = scenario;
    } else {
      scenarios.add(scenario);
    }
    saveScenarios(scenarios);
  }

  static void deleteScenario(String scenarioId) {
    final scenarios = getScenarios()..removeWhere((s) => s.id == scenarioId);
    saveScenarios(scenarios);
  }
}
