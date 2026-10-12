import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:excel_plus/excel_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/work_rfi_export.dart';

const String workRfiExportFileName = 'work_rfi.xlsx';

const String _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

Excel _workbook(List<RfiListItem> items) {
  final Excel workbook = Excel.createExcel();
  final String sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = workbook[sheetName];
  sheet.appendRow(_cellRow(workRfiExportHeaders));
  for (final RfiListItem item in items) {
    sheet.appendRow(_cellRow(workRfiExportCells(item)));
  }
  return workbook;
}

Uint8List buildWorkRfiXlsxBytes(List<RfiListItem> items) {
  return _bytesOrThrow(_workbook(items).encode());
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

Future<void> shareWorkRfiXlsx({
  required List<RfiListItem> items,
  Rect? sharePositionOrigin,
}) async {
  final Excel workbook = _workbook(items);
  List<int>? encoded;
  try {
    encoded = await workbook.encodeAsync();
  } on Object {
    encoded = null;
  }
  final Uint8List bytes = encoded == null || encoded.isEmpty
      ? buildWorkRfiXlsxBytes(items)
      : _bytesOrThrow(encoded);
  final Directory directory = await getTemporaryDirectory();
  final File file = File('${directory.path}/$workRfiExportFileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile(file.path, mimeType: _xlsxMime, name: workRfiExportFileName),
      ],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
