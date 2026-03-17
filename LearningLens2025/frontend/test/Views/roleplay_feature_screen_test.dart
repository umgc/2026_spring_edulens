import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learninglens_app/Api/lms/lms_interface.dart';
import 'package:learninglens_app/Views/roleplay_feature_screen.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/services/roleplay_scenario_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
    LocalStorageService.saveUserRole(UserRole.teacher);
    LocalStorageService.saveOpenAIKey('test-openai-key');
  });

  Widget buildHarness() {
    return const MaterialApp(
      home: RoleplayFeatureScreen(),
    );
  }

  testWidgets('teacher can save a roleplay scenario',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'Scenario Title'),
      'Difficult Stakeholder',
    );
    await tester.enterText(
      find.widgetWithText(
        TextField,
        'Persona Role (client, stakeholder, customer, etc.)',
      ),
      'Stakeholder',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Persona Traits'),
      'Direct and impatient',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Persona Goals'),
      'Needs a credible plan',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Scenario Context'),
      'A project has slipped and the student must respond.',
    );

    await tester.tap(find.text('Save Roleplay Scenario'));
    await tester.pump();

    final scenarios = RoleplayScenarioService.getScenarios();
    expect(scenarios, hasLength(1));
    expect(scenarios.single.personaRole, 'Stakeholder');
    expect(
      scenarios.single.scenarioContext,
      'A project has slipped and the student must respond.',
    );

    await tester.scrollUntilVisible(
      find.text('Difficult Stakeholder'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Difficult Stakeholder'), findsOneWidget);
  });

  testWidgets('teacher can delete a saved roleplay scenario',
      (WidgetTester tester) async {
    LocalStorageService.setString(
      'roleplay_scenarios_v1',
      '[{"id":"scenario-1","title":"Delete Me","personaRole":"Client","personaTraits":"Concerned","personaGoals":"Get reassurance","scenarioContext":"Status meeting","createdAt":"2026-03-01T00:00:00.000Z"}]',
    );

    await tester.pumpWidget(buildHarness());
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Delete Me'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Delete Me'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(find.text('Delete Me'), findsNothing);
    expect(RoleplayScenarioService.getScenarios(), isEmpty);
  });
}
