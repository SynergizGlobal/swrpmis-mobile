import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';

void main() {
  test('variant defaults use one icon and label per kind', () {
    expect(AppDialog.primaryLabelFor(AppDialogVariant.info), 'OK');
    expect(AppDialog.primaryLabelFor(AppDialogVariant.success), 'OK');
    expect(AppDialog.primaryLabelFor(AppDialogVariant.warning), 'OK');
    expect(AppDialog.primaryLabelFor(AppDialogVariant.error), 'OK');
    expect(AppDialog.primaryLabelFor(AppDialogVariant.confirm), 'Confirm');
    expect(AppDialog.secondaryLabel, 'Cancel');
    expect(AppDialog.barrierDismissibleFor(AppDialogVariant.info), isTrue);
    expect(AppDialog.barrierDismissibleFor(AppDialogVariant.success), isTrue);
    expect(AppDialog.barrierDismissibleFor(AppDialogVariant.warning), isTrue);
    expect(AppDialog.barrierDismissibleFor(AppDialogVariant.error), isTrue);
    expect(AppDialog.barrierDismissibleFor(AppDialogVariant.confirm), isFalse);
    expect(
      AppDialog.iconFor(AppDialogVariant.info),
      Icons.info_outline_rounded,
    );
    expect(
      AppDialog.iconFor(AppDialogVariant.success),
      Icons.check_circle_outline_rounded,
    );
    expect(
      AppDialog.iconFor(AppDialogVariant.warning),
      Icons.warning_amber_rounded,
    );
    expect(
      AppDialog.iconFor(AppDialogVariant.error),
      Icons.error_outline_rounded,
    );
    expect(
      AppDialog.iconFor(AppDialogVariant.confirm),
      Icons.help_outline_rounded,
    );
    expect(
      AppDialog.iconFor(AppDialogVariant.confirm, destructive: true),
      Icons.warning_amber_rounded,
    );
  });

  testWidgets('info dialog shows the title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  AppDialog.show(
                    context,
                    title: 'Create',
                    message: 'Create will be added next.',
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Create will be added next.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'OK'), findsOneWidget);
  });

  testWidgets('confirm dialog returns true or false', (
    WidgetTester tester,
  ) async {
    String result = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return Column(
                children: <Widget>[
                  Text('result:$result'),
                  TextButton(
                    onPressed: () async {
                      final bool value = await AppDialog.confirm(
                        context,
                        title: 'Sign out',
                        message: 'Leave the app?',
                      );
                      result = value.toString();
                    },
                    child: const Text('Open'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(result, 'true');

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(result, 'false');
  });
}
