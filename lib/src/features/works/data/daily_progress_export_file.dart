import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:excel_plus/excel_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/daily_progress_row.dart';

const String _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
const String _pdfMime = 'application/pdf';

final DateFormat _titleDate = DateFormat('dd-MM-yyyy');
final DateFormat _fileDate = DateFormat('yyyy-MM-dd');

final CellStyle _titleStyle = CellStyle(
  bold: true,
  fontSize: 14,
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Center,
);

final CellStyle _headerStyle = CellStyle(
  backgroundColorHex: ExcelColor.fromHexString('FF204481'),
  fontColorHex: ExcelColor.white,
  bold: true,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Center,
);

final CellStyle _activityRowStyle = CellStyle(
  backgroundColorHex: ExcelColor.fromHexString('FFE8EEF7'),
  bold: true,
  verticalAlign: VerticalAlign.Center,
);

String dailyProgressExportFileName({
  required DateTime reportDate,
  required String extension,
}) {
  return 'Daily_Progress_${_fileDate.format(reportDate)}.$extension';
}

String _reportTitle(DateTime reportDate) =>
    'Daily Progress Report - ${_titleDate.format(reportDate)}';

List<String> get _activityHeaders => const <String>[
      'Activity',
      'Sections',
      'Unit',
      'Structures',
      'Scope (Cum)',
      'Completed Qty (Cum)',
      'Balance (Cum)',
      'Asking Rate',
      'Progress on Date',
      'TDC',
    ];

List<String> get _structureHeaders => const <String>[
      'Section',
      'Structure',
      'Unit',
      'Scope',
      'Planned Till Date',
      'Actual Till Date',
      'Asking Rate / Day',
      'Actual For Day',
      'M&P',
      'Manpower',
      'TDC',
    ];

String _qty(double value) => DailyProgressRow.formatQty(value);

String _sectionsLabel(DailyProgressActivityGroup group) {
  final List<String> names = group.sections
      .map((DailyProgressSectionGroup s) => s.section.trim())
      .where((String s) => s.isNotEmpty)
      .toList(growable: false);
  if (names.isEmpty) {
    return '';
  }
  if (names.length == 1) {
    return names.first;
  }
  return names.join(', ');
}

String _emptyDash(String label) => label == '—' ? '' : label;

List<CellValue?> _cellRow(List<String> values) {
  return values
      .map<CellValue?>((String value) => TextCellValue(value))
      .toList(growable: false);
}

void _styleHeaderRow(Sheet sheet, int rowIndex, int columnCount) {
  for (int i = 0; i < columnCount; i++) {
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex))
            .cellStyle =
        _headerStyle;
  }
}

Excel _workbook({
  required List<DailyProgressActivityGroup> groups,
  required DateTime reportDate,
}) {
  final Excel workbook = Excel.createExcel();
  final String sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = workbook[sheetName];

  sheet.appendRow(_cellRow(<String>[_reportTitle(reportDate)]));
  sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .cellStyle =
      _titleStyle;
  sheet.appendRow(_cellRow(const <String>[]));

  for (int g = 0; g < groups.length; g++) {
    final DailyProgressActivityGroup group = groups[g];
    final DailyProgressTotals totals = group.totals;

    final int activityHeaderRow = sheet.maxRows;
    sheet.appendRow(_cellRow(_activityHeaders));
    _styleHeaderRow(sheet, activityHeaderRow, _activityHeaders.length);

    final int activityDataRow = sheet.maxRows;
    sheet.appendRow(
      _cellRow(<String>[
        group.activity,
        _sectionsLabel(group),
        totals.unit,
        '${totals.structureCount}',
        _qty(totals.scope),
        _qty(totals.completedQty),
        _qty(totals.balance),
        _qty(totals.askingRate),
        _qty(totals.progressOnDate),
        totals.tdc == null ? '' : totals.tdcLabel,
      ]),
    );
    for (int i = 0; i < _activityHeaders.length; i++) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: i,
                  rowIndex: activityDataRow,
                ),
              )
              .cellStyle =
          _activityRowStyle;
    }

    sheet.appendRow(_cellRow(const <String>[]));

    final int structureHeaderRow = sheet.maxRows;
    sheet.appendRow(_cellRow(_structureHeaders));
    _styleHeaderRow(sheet, structureHeaderRow, _structureHeaders.length);

    for (final DailyProgressSectionGroup section in group.sections) {
      for (final DailyProgressRow row in section.structures) {
        sheet.appendRow(
          _cellRow(<String>[
            row.section,
            row.structure,
            row.unit,
            _qty(row.scope),
            _qty(row.plannedTillDate),
            _qty(row.actualTillDate),
            _qty(row.askingRatePerDay),
            _qty(row.actualForDay),
            _emptyDash(row.mpLabel),
            _emptyDash(row.manpowerLabel),
            row.tdc == null ? '' : row.tdcLabel,
          ]),
        );
      }
    }

    if (g < groups.length - 1) {
      sheet.appendRow(_cellRow(const <String>[]));
      sheet.appendRow(_cellRow(const <String>[]));
    }
  }

  return workbook;
}

Uint8List _bytesOrThrow(List<int>? encoded) {
  if (encoded == null || encoded.isEmpty) {
    throw StateError('empty xlsx');
  }
  return Uint8List.fromList(encoded);
}

Uint8List buildDailyProgressXlsxBytes({
  required List<DailyProgressActivityGroup> groups,
  required DateTime reportDate,
}) {
  return _bytesOrThrow(
    _workbook(groups: groups, reportDate: reportDate).encode(),
  );
}

Future<void> shareDailyProgressXlsx({
  required List<DailyProgressActivityGroup> groups,
  required DateTime reportDate,
  Rect? sharePositionOrigin,
}) async {
  if (groups.isEmpty) {
    return;
  }
  final Excel workbook = _workbook(groups: groups, reportDate: reportDate);
  List<int>? encoded;
  try {
    encoded = await workbook.encodeAsync();
  } on Object {
    encoded = null;
  }
  final Uint8List bytes = encoded == null || encoded.isEmpty
      ? buildDailyProgressXlsxBytes(groups: groups, reportDate: reportDate)
      : _bytesOrThrow(encoded);
  final String fileName = dailyProgressExportFileName(
    reportDate: reportDate,
    extension: 'xlsx',
  );
  final Directory directory = await getTemporaryDirectory();
  final File file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile(file.path, mimeType: _xlsxMime, name: fileName),
      ],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}

class _PdfFonts {
  const _PdfFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}

Future<_PdfFonts> _loadPdfFonts() async {
  try {
    return _PdfFonts(
      regular: await PdfGoogleFonts.notoSansRegular(),
      bold: await PdfGoogleFonts.notoSansBold(),
    );
  } on Object {
    return _PdfFonts(regular: pw.Font.helvetica(), bold: pw.Font.helveticaBold());
  }
}

pw.Widget _pdfHeaderCell(
  String text,
  _PdfFonts fonts, {
  pw.Alignment align = pw.Alignment.centerLeft,
}) {
  return pw.Container(
    alignment: align,
    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: fonts.bold,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 7,
      ),
    ),
  );
}

pw.Widget _pdfCell(
  String text,
  _PdfFonts fonts, {
  pw.Alignment align = pw.Alignment.centerLeft,
  bool bold = false,
}) {
  return pw.Container(
    alignment: align,
    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: bold ? fonts.bold : fonts.regular,
        fontSize: 6.5,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

pw.TableBorder get _tableBorder => pw.TableBorder.all(
  color: PdfColors.blueGrey200,
  width: 0.4,
);

pw.Widget _activitySummaryTable(
  DailyProgressActivityGroup group,
  _PdfFonts fonts,
) {
  final DailyProgressTotals totals = group.totals;
  return pw.Table(
    border: _tableBorder,
    columnWidths: const <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2.4),
      1: pw.FlexColumnWidth(2.6),
      2: pw.FlexColumnWidth(0.7),
      3: pw.FlexColumnWidth(0.7),
      4: pw.FlexColumnWidth(1.2),
      5: pw.FlexColumnWidth(1.3),
      6: pw.FlexColumnWidth(1.2),
      7: pw.FlexColumnWidth(1.1),
      8: pw.FlexColumnWidth(1.2),
      9: pw.FlexColumnWidth(1.0),
    },
    children: <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF204481)),
        children: <pw.Widget>[
          for (final String h in _activityHeaders) _pdfHeaderCell(h, fonts),
        ],
      ),
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8EEF7)),
        children: <pw.Widget>[
          _pdfCell(group.activity, fonts, bold: true),
          _pdfCell(_sectionsLabel(group), fonts),
          _pdfCell(totals.unit, fonts),
          _pdfCell('${totals.structureCount}', fonts),
          _pdfCell(
            _qty(totals.scope),
            fonts,
            align: pw.Alignment.centerRight,
          ),
          _pdfCell(
            _qty(totals.completedQty),
            fonts,
            align: pw.Alignment.centerRight,
          ),
          _pdfCell(
            _qty(totals.balance),
            fonts,
            align: pw.Alignment.centerRight,
          ),
          _pdfCell(
            _qty(totals.askingRate),
            fonts,
            align: pw.Alignment.centerRight,
          ),
          _pdfCell(
            _qty(totals.progressOnDate),
            fonts,
            align: pw.Alignment.centerRight,
          ),
          _pdfCell(totals.tdc == null ? '' : totals.tdcLabel, fonts),
        ],
      ),
    ],
  );
}

pw.Widget _structureDetailTable(
  DailyProgressActivityGroup group,
  _PdfFonts fonts,
) {
  return pw.Table(
    border: _tableBorder,
    columnWidths: const <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2.2),
      1: pw.FlexColumnWidth(2.8),
      2: pw.FlexColumnWidth(0.6),
      3: pw.FlexColumnWidth(1.1),
      4: pw.FlexColumnWidth(1.1),
      5: pw.FlexColumnWidth(1.1),
      6: pw.FlexColumnWidth(1.1),
      7: pw.FlexColumnWidth(1.0),
      8: pw.FlexColumnWidth(0.7),
      9: pw.FlexColumnWidth(0.8),
      10: pw.FlexColumnWidth(0.9),
    },
    children: <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF204481)),
        children: <pw.Widget>[
          for (final String h in _structureHeaders) _pdfHeaderCell(h, fonts),
        ],
      ),
      for (final DailyProgressSectionGroup section in group.sections)
        for (final DailyProgressRow row in section.structures)
          pw.TableRow(
            children: <pw.Widget>[
              _pdfCell(row.section, fonts),
              _pdfCell(row.structure, fonts),
              _pdfCell(row.unit, fonts),
              _pdfCell(
                _qty(row.scope),
                fonts,
                align: pw.Alignment.centerRight,
              ),
              _pdfCell(
                _qty(row.plannedTillDate),
                fonts,
                align: pw.Alignment.centerRight,
              ),
              _pdfCell(
                _qty(row.actualTillDate),
                fonts,
                align: pw.Alignment.centerRight,
              ),
              _pdfCell(
                _qty(row.askingRatePerDay),
                fonts,
                align: pw.Alignment.centerRight,
              ),
              _pdfCell(
                _qty(row.actualForDay),
                fonts,
                align: pw.Alignment.centerRight,
              ),
              _pdfCell(_emptyDash(row.mpLabel), fonts),
              _pdfCell(_emptyDash(row.manpowerLabel), fonts),
              _pdfCell(row.tdc == null ? '' : row.tdcLabel, fonts),
            ],
          ),
    ],
  );
}

Future<Uint8List> buildDailyProgressPdfBytes({
  required List<DailyProgressActivityGroup> groups,
  required DateTime reportDate,
}) async {
  final _PdfFonts fonts = await _loadPdfFonts();
  final pw.Document document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(18),
      header: (pw.Context context) {
        if (context.pageNumber > 1) {
          return pw.SizedBox();
        }
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(
            _reportTitle(reportDate),
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        );
      },
      build: (pw.Context context) {
        final List<pw.Widget> widgets = <pw.Widget>[];
        for (int i = 0; i < groups.length; i++) {
          final DailyProgressActivityGroup group = groups[i];
          widgets.add(_activitySummaryTable(group, fonts));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(_structureDetailTable(group, fonts));
          if (i < groups.length - 1) {
            widgets.add(pw.SizedBox(height: 14));
          }
        }
        return widgets;
      },
    ),
  );
  return document.save();
}

Future<void> shareDailyProgressPdf({
  required List<DailyProgressActivityGroup> groups,
  required DateTime reportDate,
  Rect? sharePositionOrigin,
}) async {
  if (groups.isEmpty) {
    return;
  }
  final Uint8List bytes = await buildDailyProgressPdfBytes(
    groups: groups,
    reportDate: reportDate,
  );
  final String fileName = dailyProgressExportFileName(
    reportDate: reportDate,
    extension: 'pdf',
  );
  final Directory directory = await getTemporaryDirectory();
  final File file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[
        XFile(file.path, mimeType: _pdfMime, name: fileName),
      ],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
