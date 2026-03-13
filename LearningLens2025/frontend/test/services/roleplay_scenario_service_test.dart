import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learninglens_app/beans/roleplay_scenario.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/services/roleplay_scenario_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RoleplayScenarioService', () {
    setUpAll(() async {
      await dotenv.load(fileName: '.env');
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
    });

    test('returns empty list when storage is empty or invalid', () {
      expect(RoleplayScenarioService.getScenarios(), isEmpty);

      LocalStorageService.setString('roleplay_scenarios_v1', 'not-json');
      expect(RoleplayScenarioService.getScenarios(), isEmpty);

      LocalStorageService.setString('roleplay_scenarios_v1', '{"bad":true}');
      expect(RoleplayScenarioService.getScenarios(), isEmpty);
    });

    test('saves and returns scenarios sorted by newest first', () {
      final older = RoleplayScenario(
        id: 'older',
        title: 'Older Scenario',
        personaRole: 'Client',
        personaTraits: 'Reserved',
        personaGoals: 'Get clarity',
        scenarioContext: 'Initial meeting',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final newer = RoleplayScenario(
        id: 'newer',
        title: 'Newer Scenario',
        personaRole: 'Stakeholder',
        personaTraits: 'Direct',
        personaGoals: 'Reduce risk',
        scenarioContext: 'Project review',
        createdAt: DateTime.utc(2026, 2, 1),
      );

      RoleplayScenarioService.saveScenarios([older, newer]);

      final scenarios = RoleplayScenarioService.getScenarios();
      expect(scenarios.map((s) => s.id).toList(), ['newer', 'older']);
    });

    test('upsert updates an existing scenario instead of duplicating it', () {
      final original = RoleplayScenario(
        id: 'scenario-1',
        title: 'Original',
        personaRole: 'Manager',
        personaTraits: 'Calm',
        personaGoals: 'Finish review',
        scenarioContext: 'Weekly sync',
        createdAt: DateTime.utc(2026, 2, 15),
      );
      final updated = RoleplayScenario(
        id: 'scenario-1',
        title: 'Updated',
        personaRole: 'Manager',
        personaTraits: 'Calm, precise',
        personaGoals: 'Finish review',
        scenarioContext: 'Weekly sync',
        createdAt: DateTime.utc(2026, 2, 16),
      );

      RoleplayScenarioService.upsertScenario(original);
      RoleplayScenarioService.upsertScenario(updated);

      final scenarios = RoleplayScenarioService.getScenarios();
      expect(scenarios, hasLength(1));
      expect(scenarios.single.title, 'Updated');
      expect(scenarios.single.personaTraits, 'Calm, precise');
    });

    test('delete removes only the matching scenario', () {
      final first = RoleplayScenario(
        id: 'scenario-1',
        title: 'First',
        personaRole: 'Client',
        personaTraits: 'Curious',
        personaGoals: 'Learn options',
        scenarioContext: 'Consultation',
        createdAt: DateTime.utc(2026, 2, 1),
      );
      final second = RoleplayScenario(
        id: 'scenario-2',
        title: 'Second',
        personaRole: 'Customer',
        personaTraits: 'Skeptical',
        personaGoals: 'Validate quality',
        scenarioContext: 'Follow-up call',
        createdAt: DateTime.utc(2026, 2, 2),
      );

      RoleplayScenarioService.saveScenarios([first, second]);
      RoleplayScenarioService.deleteScenario('scenario-1');

      final scenarios = RoleplayScenarioService.getScenarios();
      expect(scenarios, hasLength(1));
      expect(scenarios.single.id, 'scenario-2');
    });
  });
}
