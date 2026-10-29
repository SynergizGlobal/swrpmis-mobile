import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_filter_section.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

/// Mirrors contracts_list_view header Add button: hug width so theme
/// [Size.fromHeight] (infinite min width) is safe inside a [Row].
Widget _contractsHeaderAddButton() {
  return FilledButton.icon(
    style: FilledButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(0, AppTheme.fieldHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    onPressed: () {},
    icon: const Icon(Icons.add_rounded, size: 18),
    label: const Text('Add'),
  );
}

bool _isLayoutConstraintError(FlutterErrorDetails e) {
  final String text = e.exceptionAsString();
  return text.contains('_debugDoingThisLayout') ||
      text.contains('was not laid out') ||
      text.contains('Cannot hit test') ||
      text.contains('RenderFlex overflowed') ||
      text.contains('BoxConstraints forces an infinite width') ||
      text.contains('BoxConstraints forces an infinite height');
}

void main() {
  testWidgets(
    'contracts header Row Add button lays out under bounded width',
    (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() {
        FlutterError.onError = previous;
      });

      await tester.binding.setSurfaceSize(const Size(411.4, 892));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // AppTheme.filledButtonTheme uses Size.fromHeight → infinite min width.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Contracts / Tenders',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _contractsHeaderAddButton(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        errors.where(_isLayoutConstraintError),
        isEmpty,
        reason: errors
            .where(_isLayoutConstraintError)
            .map((FlutterErrorDetails e) => e.exceptionAsString())
            .join('\n---\n'),
      );
      expect(find.text('Contracts / Tenders'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    },
  );

  testWidgets(
    'contracts-like nested scaffold does not re-enter layout',
    (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() {
        FlutterError.onError = previous;
      });

      await tester.binding.setSurfaceSize(const Size(411.4, 892));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            appBar: AppBar(title: const Text('Shell')),
            bottomNavigationBar: const SizedBox(height: 56, child: Text('Nav')),
            body: AppListScaffold(
              appBar: AppBar(title: const Text('Contract')),
              body: PagedTableColumn(
                header: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const RfiContentLoader(loading: false),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text(
                              'Contracts / Tenders',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          _contractsHeaderAddButton(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: AppFilterSection(
                        activeCount: 0,
                        child: RfiFilterGrid(
                          children: <Widget>[
                            for (final String label in <String>[
                              'Project',
                              'HOD',
                              'Dy HOD',
                              'Contractor',
                              'Contract Status',
                              'Status of Work',
                            ])
                              RfiFilterField(
                                label: label,
                                emptyLabel: 'Select $label',
                                value: null,
                                options: const <RfiFilterOption>[],
                                selectedId: null,
                                onClear: null,
                                onPick: (_) {},
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                body: TableScrollFrame(
                  width: 1100,
                  header: const SizedBox(height: 52, child: Text('Cols')),
                  itemCount: 10,
                  itemBuilder: (BuildContext context, int index) {
                    return SizedBox(height: 44, child: Text('Row $index'));
                  },
                ),
                footer: TablePaginationFooter(
                  label: 'Showing 1 to 10 of 10 entries',
                  total: 10,
                  page: 1,
                  pageCount: 1,
                  pageSize: 10,
                  onPageChanged: (_) {},
                  onPageSizeChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final List<FlutterErrorDetails> bad = errors
          .where(_isLayoutConstraintError)
          .toList();
      expect(tester.takeException(), isNull);
      expect(
        bad,
        isEmpty,
        reason: bad
            .map((FlutterErrorDetails e) => e.exceptionAsString())
            .join('\n---\n'),
      );
      expect(find.text('Contracts / Tenders'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      // Expanding filters mounts RfiFilterGrid LayoutBuilder after the first
      // Scaffold pass — must still stay clean.
      await tester.tap(find.text('Filters'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      expect(find.text('Project'), findsWidgets);
    },
  );
}
