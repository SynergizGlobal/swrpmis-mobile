import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:excel_plus/excel_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swr_pmis_mobile/src/features/issues/domain/issue_list.dart';

const String issueExportFileName = 'issues.xlsx';

const String _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

Excel _workbook(List<IssueRow> rows) {
  final Excel workbook = Excel.createExcel();
  final String sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = workbook[sheetName];
  sheet.appendRow(_cellRow(issueExportHeaders));
  for (final IssueRow row in rows) {
    sheet.appendRow(_cellRow(issueExportCells(row)));
  }
  return workbook;
}

Uint8List buildIssueXlsxBytes(List<IssueRow> rows) {
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

Future<void> shareIssueXlsx({
  required List<IssueRow> rows,
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
      ? buildIssueXlsxBytes(rows)
      : _bytesOrThrow(encoded);
  final Directory directory = await getTemporaryDirectory();
  final File file = File('${directory.path}/$issueExportFileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile(file.path, mimeType: _xlsxMime, name: issueExportFileName),
      ],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
