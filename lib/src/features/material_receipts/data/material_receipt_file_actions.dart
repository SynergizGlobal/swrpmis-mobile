import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

Future<void> presentMaterialReceiptPdf({
  required Uint8List bytes,
  required String fileName,
  Rect? sharePositionOrigin,
}) async {
  if (!RfiStoredFile.looksLikePdf(bytes)) {
    throw StateError('Generated file is not a PDF.');
  }
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
      await shareMaterialReceiptPdf(
        bytes: bytes,
        fileName: safe,
        sharePositionOrigin: sharePositionOrigin,
      );
    }
  } on Object {
    await shareMaterialReceiptPdf(
      bytes: bytes,
      fileName: safe,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}

Future<void> shareMaterialReceiptPdf({
  required Uint8List bytes,
  required String fileName,
  Rect? sharePositionOrigin,
}) async {
  final Directory directory = await getTemporaryDirectory();
  final String safe = _safePdfName(fileName);
  final File file = File('${directory.path}/$safe');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile(file.path, name: safe, mimeType: 'application/pdf'),
      ],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}

String _safePdfName(String fileName) {
  final String safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (safe.isEmpty) {
    return 'Material_Receipt.pdf';
  }
  if (safe.toLowerCase().endsWith('.pdf')) {
    return safe;
  }
  return '$safe.pdf';
}
