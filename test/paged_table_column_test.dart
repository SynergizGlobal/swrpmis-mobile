import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';

void main() {
  Future<void> pumpWithoutOverflow(
    WidgetTester tester,
    Widget home,
    List<FlutterErrorDetails> errors,
  ) async {
    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      errors.where((FlutterErrorDetails details) {
        final String text = details.exceptionAsString();
        return text.contains('RenderFlex overflowed') ||
            text.contains('was not laid out') ||
            text.contains('RenderShrinkWrappingViewport') ||
            text.contains('NEEDS-LAYOUT') ||
            text.contains('NEEDS-PAINT') ||
            text.contains('size MISSING') ||
            text.contains('hasSize');
      }),
      isEmpty,
    );
  }

  Finder verticalHeaderScroll() {
    return find.descendant(
      of: find.byType(PagedTableColumn),
      matching: find.byWidgetPredicate(
        (Widget w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.vertical,
      ),
    );
  }

  testWidgets('PagedTableColumn fits bounded scaffold without overflow', (
    WidgetTester tester,
  ) async {
    const int rowCount = 30;
    const double rowHeight = 48;
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = errors.add;

    addTearDown(() {
      FlutterError.onError = previous;
    });

    await pumpWithoutOverflow(
      tester,
      Scaffold(
        body: PagedTableColumn(
          header: const SizedBox(height: 120, child: Text('Header')),
          footer: const SizedBox(height: 56, child: Text('Footer')),
          body: TableScrollFrame(
            width: 400,
            header: const SizedBox(
              height: 52,
              child: ColoredBox(
                color: Colors.blue,
                child: Text('Table header'),
              ),
            ),
            itemCount: rowCount,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                height: rowHeight,
                child: Text('Row $index'),
              );
            },
          ),
        ),
      ),
      errors,
    );
  });

  testWidgets('PagedTableColumn fits TabBarView tab without overflow', (
    WidgetTester tester,
  ) async {
    final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
    final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
    FlutterError.onError = errors.add;

    addTearDown(() {
      FlutterError.onError = previous;
    });

    await pumpWithoutOverflow(
      tester,
      DefaultTabController(
        length: 1,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(tabs: <Widget>[Tab(text: 'Tab')]),
          ),
          body: TabBarView(
            children: <Widget>[
              PagedTableColumn(
                header: const SizedBox(height: 80, child: Text('Header')),
                footer: const SizedBox(height: 48, child: Text('Footer')),
                body: TableScrollFrame(
                  width: 300,
                  header: const SizedBox(height: 52, child: Text('Cols')),
                  itemCount: 25,
                  itemBuilder: (BuildContext context, int index) {
                    return SizedBox(
                      height: 48,
                      child: Text('Row $index'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      errors,
    );
  });

  testWidgets(
    'PagedTableColumn fits compact filter header and wide table without overflow',
    (WidgetTester tester) async {
      const int rowCount = 25;
      const double rowHeight = 45;
      const double tableHeaderHeight = 52;
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = errors.add;

      addTearDown(() {
        FlutterError.onError = previous;
      });

      await pumpWithoutOverflow(
        tester,
        Scaffold(
          appBar: AppBar(title: const Text('Revision Monitor')),
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
                    children: List<Widget>.generate(
                      3,
                      (int i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          height: 44,
                          child: Text('Filter row $i'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            footer: const SizedBox(height: 56, child: Text('Pagination')),
            body: TableScrollFrame(
              width: 900,
              header: SizedBox(
                height: tableHeaderHeight,
                child: const ColoredBox(
                  color: Colors.blue,
                  child: Text('Table header'),
                ),
              ),
              itemCount: rowCount,
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(
                  height: rowHeight,
                  child: Text('Drawing row $index'),
                );
              },
            ),
          ),
        ),
        errors,
      );

      expect(verticalHeaderScroll(), findsNothing);
    },
  );

  testWidgets(
    'PagedTableColumn does not wrap header in a vertical scroll band',
    (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = errors.add;

      addTearDown(() {
        FlutterError.onError = previous;
      });

      await pumpWithoutOverflow(
        tester,
        Scaffold(
          body: PagedTableColumn(
            header: Column(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(
                4,
                (int i) => SizedBox(height: 48, child: Text('Filter $i')),
              ),
            ),
            footer: const SizedBox(height: 56, child: Text('Footer')),
            body: TableScrollFrame(
              width: 1200,
              header: const SizedBox(height: 52, child: Text('Header row')),
              itemCount: 30,
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(height: 44, child: Text('Row $index'));
              },
            ),
          ),
        ),
        errors,
      );

      expect(verticalHeaderScroll(), findsNothing);
      expect(find.text('Filter 0'), findsOneWidget);
      expect(find.text('Footer'), findsOneWidget);
    },
  );

  testWidgets(
    'PagedTableColumn hosts Column(mainAxisSize: min) without size MISSING',
    (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = errors.add;

      addTearDown(() {
        FlutterError.onError = previous;
      });

      await pumpWithoutOverflow(
        tester,
        Scaffold(
          body: PagedTableColumn(
            header: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List<Widget>.generate(
                4,
                (int i) => SizedBox(
                  height: 48,
                  child: Text('Min-style filter $i'),
                ),
              ),
            ),
            footer: const SizedBox(height: 56, child: Text('Footer')),
            body: TableScrollFrame(
              width: 800,
              header: const SizedBox(height: 52, child: Text('Cols')),
              itemCount: 20,
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(height: 44, child: Text('Row $index'));
              },
            ),
          ),
        ),
        errors,
      );

      expect(verticalHeaderScroll(), findsNothing);
    },
  );
}
