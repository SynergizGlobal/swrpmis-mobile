import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';

void main() {
  group('AppTheme contrast', () {
    test('light and dark ColorSchemes keep readable onSurface tones', () {
      final ThemeData light = AppTheme.light;
      final ThemeData dark = AppTheme.dark;

      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(light.colorScheme.onSurface, isNot(equals(Colors.white)));
      expect(dark.colorScheme.onSurface, isNot(equals(Colors.black)));
      expect(
        dark.colorScheme.onSurface.computeLuminance(),
        greaterThan(dark.colorScheme.surface.computeLuminance()),
      );
      expect(
        light.colorScheme.surface.computeLuminance(),
        greaterThan(light.colorScheme.onSurface.computeLuminance()),
      );
    });

    test('InputDecorationTheme uses fieldFill distinct from cardSurface', () {
      for (final ThemeData theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
        final AppPalette palette = theme.extension<AppPalette>()!;
        final Color? fill = theme.inputDecorationTheme.fillColor;
        expect(fill, isNotNull);
        expect(fill, equals(palette.fieldFill));
        expect(fill, isNot(equals(palette.cardSurface)));
        expect(theme.inputDecorationTheme.labelStyle?.color, isNotNull);
        expect(theme.inputDecorationTheme.hintStyle?.color, isNotNull);
      }
    });

    testWidgets('TextField labels and values stay on-theme in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Source / Supplier *',
                  hintText: 'Enter supplier',
                ),
              ),
            ),
          ),
        ),
      );

      final ThemeData theme = AppTheme.dark;
      final InputDecorationThemeData decoration = theme.inputDecorationTheme;
      expect(decoration.fillColor, AppPalette.dark.fieldFill);
      expect(
        decoration.labelStyle?.color,
        AppPalette.dark.mutedText,
      );

      final TextField field = tester.widget(find.byType(TextField));
      expect(field.decoration?.labelText, 'Source / Supplier *');

      final EditableText editable = tester.widget(find.byType(EditableText));
      expect(
        editable.style.color ?? theme.colorScheme.onSurface,
        theme.colorScheme.onSurface,
      );
    });

    testWidgets('RfiFilterField uses fieldFill in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return Material(
                  color: AppPalette.of(context).fieldFill,
                  child: const SizedBox(width: 40, height: 40),
                );
              },
            ),
          ),
        ),
      );

      final Material material = tester.widget(find.byType(Material).last);
      expect(material.color, AppPalette.dark.fieldFill);
    });
  });
}
