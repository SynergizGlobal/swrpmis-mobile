import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:excel_plus/excel_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_list.dart';

const String utilityShiftingExportFileName = 'utility-shifting.xlsx';

const String _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

final CellStyle _headerStyle = CellStyle(
  backgroundColorHex: ExcelColor.fromHexString('FF70AD47'),
  fontColorHex: ExcelColor.white,
  bold: true,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Center,
);

Excel _workbook(List<UtilityShiftingRow> rows) {
  final Excel workbook = Excel.createExcel();
  final String sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = workbook[sheetName];
  sheet.appendRow(_cellRow(utilityShiftingExportHeaders));
  for (int i = 0; i < utilityShiftingExportHeaders.length; i++) {
    final Data? cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
    );
    cell?.cellStyle = _headerStyle;
  }
  for (final UtilityShiftingRow row in rows) {
    sheet.appendRow(_cellRow(utilityShiftingExportCells(row)));
  }
  return workbook;
}

Uint8List buildUtilityShiftingXlsxBytes(List<UtilityShiftingRow> rows) {
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

Future<void> shareUtilityShiftingXlsx({
  required List<UtilityShiftingRow> rows,
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
      ? buildUtilityShiftingXlsxBytes(rows)
      : _bytesOrThrow(encoded);
  final Directory directory = await getTemporaryDirectory();
  final File file = File('${directory.path}/$utilityShiftingExportFileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile(
          file.path,
          mimeType: _xlsxMime,
          name: utilityShiftingExportFileName,
        ),
      ],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
