import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_log_report.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_log_links.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

typedef RfiLogPdfSection = List<pw.Widget> Function(RfiLogPdfScope scope);

class RfiLogPdfFonts {
  const RfiLogPdfFonts({
    required this.regular,
    required this.bold,
    required this.unicode,
  });

  final pw.Font regular;
  final pw.Font bold;
  final bool unicode;

  factory RfiLogPdfFonts.helvetica() {
    return RfiLogPdfFonts(
      regular: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      unicode: false,
    );
  }
}

class RfiLogPdfScope {
  const RfiLogPdfScope({
    required this.report,
    required this.fonts,
    required this.sanitize,
  });

  final RfiLogReport report;
  final RfiLogPdfFonts fonts;
  final bool sanitize;

  String text(String value) {
    final String shown = value.trim().isEmpty ? RfiLogLinks.pdfBlank : value;
    return sanitize ? _winAnsi(shown) : shown;
  }
}

class RfiLogPdf {
  const RfiLogPdf._();

  static const PdfColor _navy = PdfColor.fromInt(0xFF0B2F63);
  static const PdfColor _green = PdfColor.fromInt(0xFF198754);

  static Future<Uint8List> build({
    required RfiLogReport report,
    required RfiLogPdfFonts fonts,
    Uint8List? logoBytes,
  }) async {
    final List<({RfiLogPdfFonts fonts, bool sanitize, Uint8List? logo})>
    attempts = <({RfiLogPdfFonts fonts, bool sanitize, Uint8List? logo})>[
      (fonts: fonts, sanitize: !fonts.unicode, logo: logoBytes),
      (fonts: fonts, sanitize: true, logo: null),
      (fonts: RfiLogPdfFonts.helvetica(), sanitize: true, logo: null),
    ];
    Object? lastError;
    for (final ({RfiLogPdfFonts fonts, bool sanitize, Uint8List? logo}) attempt
        in attempts) {
      try {
        final Uint8List bytes = await _save(
          report: report,
          fonts: attempt.fonts,
          logoBytes: attempt.logo,
          sanitize: attempt.sanitize,
        );
        if (bytes.length >= 4 &&
            bytes[0] == 0x25 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x44 &&
            bytes[3] == 0x46) {
          return bytes;
        }
      } on Object catch (error) {
        lastError = error;
      }
    }
    if (lastError != null) {
      throw lastError;
    }
    return Uint8List(0);
  }

  static Future<Uint8List> _save({
    required RfiLogReport report,
    required RfiLogPdfFonts fonts,
    required Uint8List? logoBytes,
    required bool sanitize,
  }) async {
    final RfiLogPdfScope scope = RfiLogPdfScope(
      report: report,
      fonts: fonts,
      sanitize: sanitize,
    );
    final pw.Document document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 40,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 28),
        build: (pw.Context context) {
          return <pw.Widget>[
            ...header(scope, logoBytes),
            ...fieldGrid(scope),
            for (final RfiLogPdfSection section in sections())
              ...section(scope),
          ];
        },
      ),
    );
    return document.save();
  }

  static List<pw.Widget> header(RfiLogPdfScope scope, Uint8List? logoBytes) {
    pw.Widget mark = pw.SizedBox(width: 46, height: 46);
    if (logoBytes != null && RfiStoredFile.looksLikeImage(logoBytes)) {
      mark = pw.Image(
        pw.MemoryImage(logoBytes),
        width: 46,
        height: 46,
        fit: pw.BoxFit.contain,
      );
    }
    return <pw.Widget>[
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: <pw.Widget>[
          mark,
          pw.Expanded(
            child: pw.Text(
              scope.text(RfiLogLinks.clientName),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: scope.fonts.bold, fontSize: 14),
            ),
          ),
          pw.SizedBox(width: 46),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Center(
        child: pw.Text(
          scope.text('REQUEST FOR INSPECTION (RFI) REPORT'),
          style: pw.TextStyle(font: scope.fonts.bold, fontSize: 12),
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Divider(thickness: 1, color: PdfColors.black),
      pw.SizedBox(height: 8),
    ];
  }

  static List<pw.Widget> fieldGrid(RfiLogPdfScope scope) {
    final RfiLogReportDetails details = scope.report.details;
    final String consultant = details.consultant.trim().isEmpty
        ? 'N/A'
        : details.consultant;
    final List<(String, String)> pairs = <(String, String)>[
      ('Consultant:', consultant),
      ('RFI ID:', rfiLogPdfText(details.rfiId)),
      ('RFI Raised Date:', rfiLogPdfText(details.dateOfCreation)),
      ('Project:', rfiLogPdfText(details.project)),
      ('Contract:', rfiLogPdfText(details.contract)),
      ('Contract ID:', rfiLogPdfText(details.contractId)),
      ('Structure Type:', rfiLogPdfText(details.structureType)),
      ('Structure:', rfiLogPdfText(details.structure)),
      ('Component:', rfiLogPdfText(details.component)),
      ('Element:', rfiLogPdfText(details.element)),
      ('Activity:', rfiLogPdfText(details.activity)),
      ('RFI Description:', rfiLogPdfText(details.rfiDescription)),
      ('RFI Category:', rfiLogPdfText(details.rfiCategory)),
      ('Type of RFI:', rfiLogPdfText(details.typeOfRfi)),
      ('Enclosures:', rfiLogPdfText(details.enclosures)),
      ('Contractor:', rfiLogPdfText(details.contractor)),
      (
        "Contractor's Representative:",
        rfiLogPdfText(details.contractorRepresentative),
      ),
      ('Client Representative:', rfiLogPdfText(details.clientRepresentative)),
      ('Chainage:', rfiLogPdfText(details.chainageText)),
      (
        'Proposed Inspection Date:',
        rfiLogPdfText(details.proposedDateOfInspection),
      ),
      ('Proposed Time:', rfiLogPdfText(details.proposedInspectionTime)),
      ('Contractor Inspection Date:', rfiLogPdfText(details.conInspDate)),
      ('Client Inspected Date:', rfiLogPdfText(details.enggInspDate)),
      ('Contractor Inspection Time:', rfiLogPdfText(details.conInspTime)),
      ('Contractor Location:', rfiLogPdfText(details.conLocation)),
      ('Client Location:', rfiLogPdfText(details.clientLocation)),
      ('Inspection Test Type:', rfiLogPdfText(details.typeOfTest)),
      ('Test Report Approval By Inspector:', rfiLogPdfText(details.testStatus)),
      ('DyHod:', rfiLogPdfText(details.dyHodUserName)),
      ('Description:', rfiLogPdfText(details.descriptionByContractor)),
    ];
    final String status = details.statusText.trim().isEmpty
        ? RfiLogLinks.pdfBlank
        : details.statusText;
    return <pw.Widget>[
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  scope.text('Client:'),
                  style: pw.TextStyle(font: scope.fonts.bold, fontSize: 9),
                ),
                pw.Text(
                  scope.text(RfiLogLinks.clientName),
                  style: pw.TextStyle(font: scope.fonts.bold, fontSize: 9),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: <pw.Widget>[
              pw.Text(
                scope.text('RFI Status:'),
                style: pw.TextStyle(font: scope.fonts.bold, fontSize: 9),
              ),
              pw.Text(
                scope.text(status),
                style: pw.TextStyle(
                  font: scope.fonts.bold,
                  fontSize: 9,
                  color: status == RfiLogLinks.pdfBlank
                      ? PdfColors.black
                      : _green,
                ),
              ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.4),
        columnWidths: const <int, pw.TableColumnWidth>{
          0: pw.FlexColumnWidth(1.25),
          1: pw.FlexColumnWidth(1.75),
          2: pw.FlexColumnWidth(1.25),
          3: pw.FlexColumnWidth(1.75),
        },
        children: <pw.TableRow>[
          for (int index = 0; index < pairs.length; index += 2)
            pw.TableRow(
              children: <pw.Widget>[
                _label(scope, pairs[index].$1),
                _value(scope, pairs[index].$2),
                _label(scope, pairs[index + 1].$1),
                _value(scope, pairs[index + 1].$2),
              ],
            ),
        ],
      ),
    ];
  }

  static List<RfiLogPdfSection> sections() {
    return <RfiLogPdfSection>[
      workSection,
      measurementSection,
      checklistSection,
      validationSection,
      inspectorSelfieSection,
    ];
  }

  static List<pw.Widget> workSection(RfiLogPdfScope scope) {
    if (scope.report.workDetails.isEmpty) {
      return const <pw.Widget>[];
    }
    return <pw.Widget>[
      pw.SizedBox(height: 16),
      _title(scope, 'Work Details'),
      pw.SizedBox(height: 6),
      _dataTable(
        scope,
        const <String>[
          'Activity Name',
          'Unit',
          'Scope',
          'Completed Till Date',
          'Inspection Quantity',
        ],
        <List<String>>[
          for (final RfiLogWorkDetail row in scope.report.workDetails)
            <String>[
              rfiLogPdfText(row.activityName),
              rfiLogPdfText(row.unit),
              rfiLogPdfText(row.scope),
              rfiLogPdfText(row.completedTillDate),
              rfiLogPdfText(row.inspectionQuantity),
            ],
        ],
      ),
    ];
  }

  static List<pw.Widget> measurementSection(RfiLogPdfScope scope) {
    final RfiLogMeasurement? row = scope.report.measurement;
    if (row == null) {
      return const <pw.Widget>[];
    }
    return <pw.Widget>[
      pw.SizedBox(height: 16),
      _title(scope, 'Measurement Details'),
      pw.SizedBox(height: 6),
      _dataTable(
        scope,
        const <String>[
          'Type',
          'Units',
          'Length',
          'Breadth',
          'Height',
          'Weight',
          'Count',
          'Total Quantity',
        ],
        <List<String>>[
          <String>[
            rfiLogPdfText(row.measurementType),
            rfiLogPdfText(row.units),
            rfiLogPdfText(row.length),
            rfiLogPdfText(row.breadth),
            rfiLogPdfText(row.height),
            rfiLogPdfText(row.weight),
            rfiLogPdfText(row.count),
            rfiLogPdfText(row.totalQty),
          ],
        ],
      ),
    ];
  }

  static List<pw.Widget> checklistSection(RfiLogPdfScope scope) {
    if (scope.report.checklistItems.isEmpty) {
      return const <pw.Widget>[];
    }
    final List<pw.Widget> blocks = <pw.Widget>[];
    for (final RfiLogChecklistGroup group in scope.report.checklistGroups) {
      blocks
        ..add(pw.SizedBox(height: 16))
        ..add(
          _title(scope, group.titleFor(scope.report.details.rfiDescription)),
        )
        ..add(pw.SizedBox(height: 6))
        ..add(
          _dataTable(
            scope,
            const <String>[
              '#',
              'Description',
              'Contractor Status',
              'AE Status',
              'Contractor Remarks',
              'AE Remarks',
            ],
            <List<String>>[
              for (int index = 0; index < group.items.length; index++)
                <String>[
                  '${index + 1}',
                  rfiLogPdfText(group.items[index].checklistDescription),
                  rfiLogPdfText(group.items[index].conStatus),
                  rfiLogPdfText(group.items[index].aeStatus),
                  rfiLogPdfText(group.items[index].contractorRemark),
                  rfiLogPdfText(group.items[index].aeRemark),
                ],
            ],
            flex: const <int>[1, 4, 2, 2, 2, 2],
          ),
        );
    }
    return blocks;
  }

  static List<pw.Widget> validationSection(RfiLogPdfScope scope) {
    final RfiLogReportDetails details = scope.report.details;
    return <pw.Widget>[
      pw.SizedBox(height: 18),
      pw.Text(
        scope.text('Validation Status & Remarks:'),
        style: pw.TextStyle(font: scope.fonts.bold, fontSize: 11),
      ),
      pw.SizedBox(height: 6),
      _remarkLine(scope, 'Status:', details.validationStatus),
      _remarkLine(scope, 'Remarks:', details.remarks),
      _remarkLine(scope, 'Comment:', details.validationComments),
    ];
  }

  static List<pw.Widget> inspectorSelfieSection(RfiLogPdfScope scope) {
    return <pw.Widget>[
      pw.SizedBox(height: 28),
      pw.Center(
        child: pw.Text(
          scope.text('Inspector Selfie:'),
          style: pw.TextStyle(font: scope.fonts.bold, fontSize: 10),
        ),
      ),
    ];
  }

  static pw.Widget _title(RfiLogPdfScope scope, String title) {
    return pw.Center(
      child: pw.Text(
        scope.text(title),
        style: pw.TextStyle(font: scope.fonts.bold, fontSize: 12),
      ),
    );
  }

  static pw.Widget _remarkLine(
    RfiLogPdfScope scope,
    String label,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(
              text: scope.text(label),
              style: pw.TextStyle(font: scope.fonts.bold, fontSize: 9),
            ),
            pw.TextSpan(
              text: scope.text(' ${rfiLogPdfText(value)}'),
              style: pw.TextStyle(font: scope.fonts.bold, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _dataTable(
    RfiLogPdfScope scope,
    List<String> headers,
    List<List<String>> rows, {
    List<int>? flex,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.4),
      columnWidths: <int, pw.TableColumnWidth>{
        for (int index = 0; index < headers.length; index++)
          index: pw.FlexColumnWidth(
            (flex == null ? 1 : flex[index]).toDouble(),
          ),
      },
      children: <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _navy),
          children: <pw.Widget>[
            for (final String header in headers) _headerCell(scope, header),
          ],
        ),
        for (final List<String> row in rows)
          pw.TableRow(
            children: <pw.Widget>[
              for (final String cell in row) _value(scope, cell),
            ],
          ),
      ],
    );
  }

  static pw.Widget _headerCell(RfiLogPdfScope scope, String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: pw.Text(
        scope.text(label),
        style: pw.TextStyle(
          font: scope.fonts.bold,
          fontSize: 7.5,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _label(RfiLogPdfScope scope, String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: pw.Text(
        scope.text(label),
        style: pw.TextStyle(font: scope.fonts.bold, fontSize: 8),
      ),
    );
  }

  static pw.Widget _value(RfiLogPdfScope scope, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: pw.Text(
        scope.text(value),
        style: pw.TextStyle(font: scope.fonts.regular, fontSize: 8),
      ),
    );
  }
}

String _winAnsi(String value) {
  final StringBuffer buffer = StringBuffer();
  for (final int rune in value.runes) {
    if (rune == 0x00B3) {
      buffer.write('3');
    } else if (rune == 0x00B2) {
      buffer.write('2');
    } else if (rune == 0x2013 || rune == 0x2014) {
      buffer.write('-');
    } else if (rune <= 255) {
      buffer.writeCharCode(rune);
    } else {
      buffer.write('?');
    }
  }
  return buffer.toString();
}
