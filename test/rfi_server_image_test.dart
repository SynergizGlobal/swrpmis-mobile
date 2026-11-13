import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_server_image.dart';

// 1x1 transparent PNG.
final Uint8List _png = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  testWidgets('site images render as thumbnails, one per server path', (
    WidgetTester tester,
  ) async {
    const List<String> paths = <String>[
      '/home/smt/git/swrpmis_qa/Rfi-Storage/uploads/siteImages/a.jpg',
      '/home/smt/git/swrpmis_qa/Rfi-Storage/uploads/siteImages/b.png',
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rfiServerFileProvider.overrideWith((ref, String path) async {
            if (path.endsWith('b.png')) {
              throw StateError('missing');
            }
            return _png;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RfiServerImageGrid(paths: paths)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(RfiServerImageThumbnail), findsNWidgets(2));
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.text('a.jpg'), findsNothing);
  });

  testWidgets('delete badge appears only when deleting is allowed', (
    WidgetTester tester,
  ) async {
    String? deleted;
    Widget grid({ValueChanged<String>? onDelete}) => ProviderScope(
      overrides: [
        rfiServerFileProvider.overrideWith((ref, String path) async => _png),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: RfiServerImageGrid(
            paths: const <String>['/srv/siteImages/a.jpg'],
            onDelete: onDelete,
          ),
        ),
      ),
    );

    await tester.pumpWidget(grid());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.bySemanticsLabel('Delete site image 1'), findsNothing);

    await tester.pumpWidget(grid(onDelete: (String path) => deleted = path));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byIcon(Icons.close));
    expect(deleted, '/srv/siteImages/a.jpg');
  });
}
