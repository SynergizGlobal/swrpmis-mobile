import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_filter_section.dart';

void main() {
  test('countActive ignores null and blank values', () {
    expect(
      AppFilterSection.countActive(const <String?>[
        null,
        '',
        '  ',
        'a',
        'b',
      ]),
      2,
    );
  });

  testWidgets('defaults collapsed and expands on header tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AppFilterSection(
            activeCount: 2,
            child: Text('Filter body'),
          ),
        ),
      ),
    );

    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('2 active'), findsOneWidget);
    expect(find.text('Filter body'), findsNothing);
    expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Filter body'), findsOneWidget);
    expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Filter body'), findsNothing);
  });

  testWidgets('collapse via GlobalKey keeps child state mounted', (
    WidgetTester tester,
  ) async {
    final GlobalKey<AppFilterSectionState> key =
        GlobalKey<AppFilterSectionState>();
    final TextEditingController controller = TextEditingController(
      text: 'kept',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppFilterSection(
            key: key,
            initiallyExpanded: true,
            child: TextField(controller: controller),
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(controller.text, 'kept');

    key.currentState!.collapse();
    await tester.pumpAndSettle();

    expect(key.currentState!.isExpanded, isFalse);
    expect(find.byType(TextField), findsNothing);
    expect(controller.text, 'kept');

    key.currentState!.expand();
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 'kept');
  });

  testWidgets('uses dark palette surfaces without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: AppFilterSection(
            initiallyExpanded: true,
            child: Text('Dark filters'),
          ),
        ),
      ),
    );

    expect(find.text('Dark filters'), findsOneWidget);
    final Material panel = tester.widget(
      find
          .descendant(
            of: find.byType(AppFilterSection),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(panel.color, AppPalette.dark.cardSurface);
  });
}
