import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_delete_dialog.dart';

void main() {
  testWidgets('Confirm Delete needs a reason and sends it trimmed', (
    WidgetTester tester,
  ) async {
    String? sentReason;
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              result = await showRfiDeleteDialog(
                context,
                rfiCode: 'RFI_W_TEST_0001',
                onDelete: (String reason) async {
                  sentReason = reason;
                  return 'RFI marked as deleted successfully!';
                },
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    FilledButton confirm() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm Delete'),
    );
    expect(confirm().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(confirm().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  dev testing ');
    await tester.pump();
    expect(find.text('14/500'), findsOneWidget);
    expect(confirm().onPressed, isNotNull);

    await tester.tap(find.text('Confirm Delete'));
    await tester.pumpAndSettle();
    expect(sentReason, 'dev testing');
    expect(result, 'RFI marked as deleted successfully!');
  });

  testWidgets('a failed delete keeps the dialog open with an error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showRfiDeleteDialog(
              context,
              rfiCode: '',
              onDelete: (_) async => throw StateError('boom'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'reason');
    await tester.pump();
    await tester.tap(find.text('Confirm Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete RFI'), findsOneWidget);
    expect(
      find.text('Unable to delete this RFI. Please try again.'),
      findsOneWidget,
    );
  });
}
