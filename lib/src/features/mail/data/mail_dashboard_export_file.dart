import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:excel_plus/excel_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_dashboard.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_correspondence_table.dart';

const String mailCorrespondenceExportXlsxFileName =
    'Mail_Correspondence_Register.xlsx';

const String _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

const List<String> mailCorrespondenceExportHeaders = <String>[
  'S. No.',
  'Contract Short Name',
  'Contractor Name',
  'Mail No.',
  'Reference',
  'Date',
  'Reply Reqd. (Y/N)',
  'Due Date',
  'Person to Reply',
  'Replied (Y/N)',
  'Reply Mail No.',
  'Reply Date',
  'Subject',
  'Status',
];

final CellStyle _headerStyle = CellStyle(
  backgroundColorHex: ExcelColor.fromHexString('FF204481'),
  fontColorHex: ExcelColor.white,
  bold: true,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Center,
);

List<String> mailCorrespondenceExportCells(
  MailCorrespondenceRow row,
  int serial,
) {
  return <String>[
    '$serial',
    row.contract,
    row.contractor,
    row.mailNo,
    row.reference,
    formatMailDashDate(row.date),
    row.replyRequired,
    formatMailDashDate(row.dueDate),
    row.person,
    row.replied,
    row.replyMailNo,
    formatMailDashDate(row.replyDate),
    row.subject,
    row.status,
  ];
}

Excel _workbook(List<MailCorrespondenceRow> rows) {
  final Excel workbook = Excel.createExcel();
  final String sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = workbook[sheetName];
  sheet.appendRow(_cellRow(mailCorrespondenceExportHeaders));
  for (int i = 0; i < mailCorrespondenceExportHeaders.length; i++) {
    final Data cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
    );
    cell.cellStyle = _headerStyle;
  }
  for (int i = 0; i < rows.length; i++) {
    sheet.appendRow(_cellRow(mailCorrespondenceExportCells(rows[i], i + 1)));
  }
  return workbook;
}

Uint8List buildMailCorrespondenceXlsxBytes(List<MailCorrespondenceRow> rows) {
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

Future<void> shareMailCorrespondenceXlsx({
  required List<MailCorrespondenceRow> rows,
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
      ? buildMailCorrespondenceXlsxBytes(rows)
      : _bytesOrThrow(encoded);
  final Directory directory = await getTemporaryDirectory();
  final File file = File(
    '${directory.path}/$mailCorrespondenceExportXlsxFileName',
  );
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile(
          file.path,
          mimeType: _xlsxMime,
          name: mailCorrespondenceExportXlsxFileName,
        ),
      ],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
