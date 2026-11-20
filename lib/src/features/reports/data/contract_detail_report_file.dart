import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const String _pdfMime = 'application/pdf';
const String _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

Future<void> shareContractDetailReportFile({
  required Uint8List bytes,
  required String fileName,
  Rect? sharePositionOrigin,
}) async {
  final String safeName = fileName.trim().isEmpty
      ? 'Contract_Detail_Report.pdf'
      : fileName.trim();
  final String lower = safeName.toLowerCase();
  final String mime = lower.endsWith('.xlsx') || lower.endsWith('.xls')
      ? _xlsxMime
      : _pdfMime;
  final Directory directory = await getTemporaryDirectory();
  final File file = File('${directory.path}/$safeName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[XFile(file.path, mimeType: mime, name: safeName)],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
