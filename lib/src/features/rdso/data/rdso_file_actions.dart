import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

Future<void> presentRdsoPreview({
  required Uint8List bytes,
  required String fileName,
}) async {
  if (RfiStoredFile.looksLikePdf(bytes)) {
    await _presentPdf(bytes: bytes, fileName: fileName);
    return;
  }
  await shareRdsoFile(bytes: bytes, fileName: fileName);
}

Future<void> shareRdsoFile({
  required Uint8List bytes,
  required String fileName,
  Rect? sharePositionOrigin,
}) async {
  final Directory directory = await getTemporaryDirectory();
  final String safe = _safeName(fileName);
  final File file = File('${directory.path}/$safe');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile(
          file.path,
          name: safe,
          mimeType: _mimeFor(safe, bytes),
        ),
      ],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}

Future<void> _presentPdf({
  required Uint8List bytes,
  required String fileName,
}) async {
  final String safe = _safePdfName(fileName);
  if (!kIsWeb && Platform.isIOS) {
    await Printing.sharePdf(bytes: bytes, filename: safe);
    return;
  }
  try {
    final bool opened = await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: safe,
    );
    if (!opened) {
      await Printing.sharePdf(bytes: bytes, filename: safe);
    }
  } on Object {
    await Printing.sharePdf(bytes: bytes, filename: safe);
  }
}

String _safeName(String fileName) {
  final String safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return safe.isEmpty ? 'rdso-drawing.bin' : safe;
}

String _safePdfName(String fileName) {
  final String safe = _safeName(fileName);
  if (safe.toLowerCase().endsWith('.pdf')) {
    return safe;
  }
  return '$safe.pdf';
}

String _mimeFor(String fileName, Uint8List bytes) {
  final String lower = fileName.toLowerCase();
  if (lower.endsWith('.pdf') || RfiStoredFile.looksLikePdf(bytes)) {
    return 'application/pdf';
  }
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  return 'application/octet-stream';
}
