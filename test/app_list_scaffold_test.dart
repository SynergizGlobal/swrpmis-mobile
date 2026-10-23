import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';

void main() {
  testWidgets(
    'AppListScaffold keeps footer at bottom when keyboard viewInsets applied',
    (WidgetTester tester) async {
      const Size screen = Size(400, 800);
      await tester.binding.setSurfaceSize(screen);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: screen,
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: AppListScaffold(
              appBar: AppBar(title: const Text('List')),
              body: const PagedTableColumn(
                header: SizedBox(height: 80, child: Text('Search')),
                footer: SizedBox(height: 56, child: Text('Footer')),
                body: ColoredBox(color: Colors.grey, child: Text('Table')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Scaffold scaffold = tester.widget(find.byType(Scaffold));
      expect(scaffold.resizeToAvoidBottomInset, isFalse);

      final double footerBottom = tester.getBottomLeft(find.text('Footer')).dy;
      // Footer stays near the physical screen bottom (behind keyboard inset),
      // not lifted above the 300px viewInsets band.
      expect(footerBottom, greaterThan(screen.height - 80));
      expect(footerBottom, lessThanOrEqualTo(screen.height));
    },
  );

  testWidgets(
    'Default Scaffold lifts footer when keyboard viewInsets applied',
    (WidgetTester tester) async {
      const Size screen = Size(400, 800);
      await tester.binding.setSurfaceSize(screen);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: screen,
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: Scaffold(
              appBar: AppBar(title: const Text('List')),
              body: const PagedTableColumn(
                header: SizedBox(height: 80, child: Text('Search')),
                footer: SizedBox(height: 56, child: Text('Footer')),
                body: ColoredBox(color: Colors.grey, child: Text('Table')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final double footerBottom = tester.getBottomLeft(find.text('Footer')).dy;
      // Default resize shrinks body above the keyboard.
      expect(footerBottom, lessThan(screen.height - 280));
    },
  );
}
