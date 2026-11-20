import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const String _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

Future<void> shareActivitiesExportFile({
  required Uint8List bytes,
  required String fileName,
  Rect? sharePositionOrigin,
}) async {
  final String safeName = fileName.trim().isEmpty
      ? 'activities_export.xlsx'
      : fileName.trim();
  final Directory directory = await getTemporaryDirectory();
  final File file = File('${directory.path}/$safeName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile(file.path, mimeType: _xlsxMime, name: safeName),
      ],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
