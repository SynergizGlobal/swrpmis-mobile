import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

/// Mirrors Quality Test Register header: filter grid + Create (intrinsic) +
/// full-width Search — never Expanded(search) + button in one Row.
void main() {
  testWidgets(
    'QTR-style header lays out under PagedTableColumn without flex assert',
    (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previous);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Quality Test Register')),
            body: PagedTableColumn(
              header: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        RfiFilterGrid(
                          children: <Widget>[
                            RfiFilterField(
                              label: 'Contract',
                              value: null,
                              options: const <RfiFilterOption>[],
                              selectedId: null,
                              onClear: null,
                              onPick: _noopPick,
                            ),
                            RfiFilterField(
                              label: 'Material',
                              value: null,
                              options: const <RfiFilterOption>[],
                              selectedId: null,
                              onClear: null,
                              onPick: _noopPick,
                            ),
                            RfiFilterField(
                              label: 'Status',
                              emptyLabel: 'All',
                              value: null,
                              options: const <RfiFilterOption>[],
                              selectedId: null,
                              onClear: null,
                              onPick: _noopPick,
                            ),
                            RfiFilterClearButton(
                              label: 'Reset',
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('Create'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: Icon(Icons.search_rounded),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              body: const Center(child: Text('table-or-empty')),
              footer: const SizedBox(height: 48, child: Text('Footer')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('table-or-empty'), findsOneWidget);
      // No nested vertical scroll band above the table body.
      expect(
        find.descendant(
          of: find.byType(PagedTableColumn),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is SingleChildScrollView &&
                w.scrollDirection == Axis.vertical,
          ),
        ),
        findsNothing,
      );
      expect(
        errors.where((FlutterErrorDetails details) {
          final String text = details.exceptionAsString();
          return text.contains('RenderFlex') ||
              text.contains('was not laid out') ||
              text.contains('size MISSING') ||
              text.contains('NEEDS-LAYOUT') ||
              text.contains('BoxConstraints');
        }),
        isEmpty,
      );
    },
  );

  testWidgets(
    'Search+Create Expanded Row under unbounded width fails (regression guard)',
    (WidgetTester tester) async {
      // Documents the bad pattern: Expanded(TextField) + button in a Row with
      // unbounded width. Kept as a negative check that the good header above
      // does not use this structure.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UnconstrainedBox(
              constrainedAxis: Axis.vertical,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: <Widget>[
                    Expanded(child: TextField()),
                    SizedBox(width: 8),
                    Text('Create'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNotNull);
    },
  );
}

void _noopPick(RfiFilterOption option) {}
