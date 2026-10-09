import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/rfi_log_pdf.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_log_report.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

Future<Uint8List> buildRfiLogPdf({
  required RfiLogReport report,
  Uint8List? logoBytes,
}) async {
  final RfiLogPdfFonts fonts = await _fonts();
  return RfiLogPdf.build(report: report, fonts: fonts, logoBytes: logoBytes);
}

Future<void> presentRfiLogPdf({
  required Uint8List bytes,
  required String fileName,
}) async {
  if (!RfiStoredFile.looksLikePdf(bytes)) {
    throw StateError('empty pdf');
  }
  final String safeName = _safePdfName(fileName);
  if (!kIsWeb && Platform.isIOS) {
    await Printing.sharePdf(bytes: bytes, filename: safeName);
    return;
  }
  try {
    final bool opened = await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        try {
          if (!RfiStoredFile.looksLikePdf(bytes)) {
            throw StateError('empty pdf');
          }
          return bytes;
        } on Object {
          return bytes;
        }
      },
      name: safeName,
    );
    if (!opened) {
      await Printing.sharePdf(bytes: bytes, filename: safeName);
    }
  } on Object {
    await Printing.sharePdf(bytes: bytes, filename: safeName);
  }
}

String _safePdfName(String fileName) {
  final String safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (safe.toLowerCase().endsWith('.pdf')) {
    return safe;
  }
  return '$safe.pdf';
}

Future<void> shareRfiLogFile({
  required Uint8List bytes,
  required String fileName,
  Rect? sharePositionOrigin,
}) async {
  final Directory directory = await getTemporaryDirectory();
  final String safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final File file = File('${directory.path}/$safe');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[XFile(file.path, mimeType: 'application/pdf', name: safe)],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}

Future<RfiLogPdfFonts> _fonts() async {
  try {
    return RfiLogPdfFonts(
      regular: await PdfGoogleFonts.notoSansRegular(),
      bold: await PdfGoogleFonts.notoSansBold(),
      unicode: true,
    );
  } on Object {
    return RfiLogPdfFonts.helvetica();
  }
}
