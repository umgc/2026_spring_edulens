import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learninglens_app/Views/nav_card.dart';

void main() {
  Widget buildHarness({
    required List<VoidCallback?> handlers,
    required ValueChanged<String> onActivated,
  }) {
    final titles = ['Courses', 'Essays', 'Analytics'];
    final icons = [
      Icons.school_outlined,
      Icons.grade_outlined,
      Icons.analytics_outlined,
    ];

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(titles.length, (index) {
                return SizedBox(
                  width: 350,
                  height: 140,
                  child: NavigationCard(
                    title: titles[index],
                    description: '${titles[index]} description',
                    icon: icons[index],
                    onPressed: handlers[index] == null
                        ? null
                        : () {
                            handlers[index]!();
                            onActivated(titles[index]);
                          },
                    focusOrder: index.toDouble(),
                    autofocus: index == 0,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Navigation cards can be activated in keyboard tab order',
      (WidgetTester tester) async {
    String? activatedTitle;

    await tester.pumpWidget(
      buildHarness(
        handlers: [() {}, () {}, () {}],
        onActivated: (title) => activatedTitle = title,
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activatedTitle, 'Courses');

    activatedTitle = null;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activatedTitle, 'Essays');

    activatedTitle = null;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activatedTitle, 'Analytics');
  });

  testWidgets('Keyboard traversal skips disabled navigation cards',
      (WidgetTester tester) async {
    String? activatedTitle;

    await tester.pumpWidget(
      buildHarness(
        handlers: [() {}, null, () {}],
        onActivated: (title) => activatedTitle = title,
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(activatedTitle, 'Analytics');
  });
}
