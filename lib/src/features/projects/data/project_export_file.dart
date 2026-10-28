import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:excel_plus/excel_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:swr_pmis_mobile/src/features/projects/domain/project_list.dart';

const String projectExportXlsxFileName = 'Projects.xlsx';
const String projectExportPdfFileName = 'Projects.pdf';

const String _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
const String _pdfMime = 'application/pdf';

final CellStyle _headerStyle = CellStyle(
  backgroundColorHex: ExcelColor.fromHexString('FF204481'),
  fontColorHex: ExcelColor.white,
  bold: true,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Center,
);

Excel _workbook(List<ProjectRow> rows) {
  final Excel workbook = Excel.createExcel();
  final String sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = workbook[sheetName];
  sheet.appendRow(_cellRow(projectExportHeaders));
  for (int i = 0; i < projectExportHeaders.length; i++) {
    final Data cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
    );
    cell.cellStyle = _headerStyle;
  }
  for (final ProjectRow row in rows) {
    sheet.appendRow(_cellRow(projectExportCells(row)));
  }
  return workbook;
}

Uint8List buildProjectXlsxBytes(List<ProjectRow> rows) {
  return _bytesOrThrow(_workbook(rows).encode());
}

Uint8List _bytesOrThrow(List<int>? encoded) {
  if (encoded == null || encoded.isEmpty) {
    throw StateError('empty xlsx');
  }
  return Uint8List.fromList(encoded);
}

List<CellValue?> _cellRow(List<String> values) {
  return values
      .map<CellValue?>((String value) => TextCellValue(value))
      .toList(growable: false);
}

Future<void> shareProjectXlsx({
  required List<ProjectRow> rows,
  Rect? sharePositionOrigin,
}) async {
  if (rows.isEmpty) {
    return;
  }
  final Excel workbook = _workbook(rows);
  List<int>? encoded;
  try {
    encoded = await workbook.encodeAsync();
  } on Object {
    encoded = null;
  }
  final Uint8List bytes = encoded == null || encoded.isEmpty
      ? buildProjectXlsxBytes(rows)
      : _bytesOrThrow(encoded);
  final Directory directory = await getTemporaryDirectory();
  final File file = File('${directory.path}/$projectExportXlsxFileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile(
          file.path,
          mimeType: _xlsxMime,
          name: projectExportXlsxFileName,
        ),
      ],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}

Future<Uint8List> buildProjectPdfBytes(List<ProjectRow> rows) async {
  final pw.Document document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return <pw.Widget>[
          pw.Text(
            'Projects',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: projectExportHeaders,
            data: <List<String>>[
              for (final ProjectRow row in rows) projectExportCells(row),
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 8,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF204481),
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(
              color: PdfColors.blueGrey200,
              width: 0.4,
            ),
          ),
        ];
      },
    ),
  );
  return document.save();
}

Future<void> shareProjectPdf({
  required List<ProjectRow> rows,
  Rect? sharePositionOrigin,
}) async {
  if (rows.isEmpty) {
    return;
  }
  final Uint8List bytes = await buildProjectPdfBytes(rows);
  final Directory directory = await getTemporaryDirectory();
  final File file = File('${directory.path}/$projectExportPdfFileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile(file.path, mimeType: _pdfMime, name: projectExportPdfFileName),
      ],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
