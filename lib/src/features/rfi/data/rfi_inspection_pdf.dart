import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:printing/printing.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

/// One checklist row printed under an enclosure.
class RfiPdfChecklistRow {
  const RfiPdfChecklistRow({
    required this.description,
    this.contractorStatus = '',
    this.engineerStatus = '',
    this.contractorRemark = '',
    this.engineerRemark = '',
  });

  final String description;
  final String contractorStatus;
  final String engineerStatus;
  final String contractorRemark;
  final String engineerRemark;

  bool get hasContent =>
      contractorStatus.trim().isNotEmpty ||
      engineerStatus.trim().isNotEmpty ||
      contractorRemark.trim().isNotEmpty ||
      engineerRemark.trim().isNotEmpty;
}

class RfiPdfEnclosure {
  const RfiPdfEnclosure({
    required this.rfiDescription,
    required this.enclosure,
    this.checklist = const <RfiPdfChecklistRow>[],
  });

  final String rfiDescription;
  final String enclosure;
  final List<RfiPdfChecklistRow> checklist;
}

class RfiPdfMeasurement {
  const RfiPdfMeasurement({
    this.component = '',
    this.element = '',
    this.activityName = '',
    this.type = '',
    this.units = '',
    this.l = '',
    this.b = '',
    this.h = '',
    this.weight = '',
    this.no = '',
    this.total = '',
  });

  final String component;
  final String element;
  final String activityName;
  final String type;
  final String units;
  final String l;
  final String b;
  final String h;
  final String weight;
  final String no;
  final String total;
}

/// Everything the inspection PDF prints. Mirrors the web `pdfPayload`
/// (InspectionForm.jsx) passed to `generateInspectionPdf` (pdfUtils.js).
class RfiInspectionPdfData {
  const RfiInspectionPdfData({
    required this.rfiNo,
    required this.rfiCategory,
    required this.inspectionMode,
    required this.contract,
    required this.contractor,
    required this.contractorRep,
    required this.location,
    required this.conSubmittedOn,
    required this.enggSubmittedOn,
    required this.raisedOn,
    required this.rfiDescriptionSelected,
    required this.rfiDescription,
    required this.structureType,
    required this.structure,
    required this.component,
    required this.element,
    required this.activity,
    this.chainageFrom = '',
    this.chainageTo = '',
    this.layer = '',
    this.inspectionStatus = '',
    this.engineerRemarks = '',
    this.enclosures = const <RfiPdfEnclosure>[],
    this.inspDescriptionCon = '',
    this.inspDescriptionEngg = '',
    this.measurements = const <RfiPdfMeasurement>[],
    this.workDetails = const <List<String>>[],
    this.earthworkDetails = const <(String, String)>[],
    this.validationRows = const <List<String>>[],
    this.contractorImages = const <Uint8List>[],
    this.engineerImages = const <Uint8List>[],
  });

  final String rfiNo;
  final String rfiCategory;
  final String inspectionMode;
  final String contract;
  final String contractor;
  final String contractorRep;
  final String location;
  final String conSubmittedOn;
  final String enggSubmittedOn;
  final String raisedOn;
  final String rfiDescriptionSelected;
  final String rfiDescription;
  final String structureType;
  final String structure;
  final String component;
  final String element;
  final String activity;
  final String chainageFrom;
  final String chainageTo;
  final String layer;
  final String inspectionStatus;
  final String engineerRemarks;
  final List<RfiPdfEnclosure> enclosures;
  final String inspDescriptionCon;
  final String inspDescriptionEngg;
  final List<RfiPdfMeasurement> measurements;

  /// Activity, Unit, Scope, Completed Till Date, Inspection Quantity.
  final List<List<String>> workDetails;

  /// FDD Test Pit Nos, Field Compaction (%), ... (label, value).
  final List<(String, String)> earthworkDetails;

  /// No., Validation Type, Validated By, Status, Validated On, Remarks.
  final List<List<String>> validationRows;
  final List<Uint8List> contractorImages;
  final List<Uint8List> engineerImages;

  String get _structureKey =>
      structureType.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  bool get isWork => rfiCategory.trim().toUpperCase() == 'WORK';

  /// "Structure Type/Structure/.../Rfi-Description" label and value, which
  /// change for Earthwork/Blanketing and Tunnel/Trackwork like the web.
  (String, String) get detailsLine {
    final String category = rfiCategory.trim().toUpperCase();
    if (category == 'QUALITY_OR_SAFETY') {
      return (
        'Structure Type/Structure/Rfi-Description :',
        '$structureType/$structure/$rfiDescriptionSelected',
      );
    }
    if (category == 'MATERIAL') {
      return ('Rfi-Description :', rfiDescriptionSelected);
    }
    if (category == 'WORK' &&
        (_structureKey == 'earthwork' || _structureKey == 'blanketing')) {
      return (
        'Structure Type/Structure/Component/Element/Chainage From/Chainage To/Layer/Rfi-Description :',
        '$structureType/$structure/$component/$element/$chainageFrom/$chainageTo/$layer/$rfiDescriptionSelected',
      );
    }
    if (category == 'WORK' &&
        (_structureKey == 'tunnel' || _structureKey == 'trackwork')) {
      return (
        'Structure Type/Structure/Component/Element/Chainage From/Chainage To/Rfi-Description :',
        '$structureType/$structure/$component/$element/$chainageFrom/$chainageTo/$rfiDescriptionSelected',
      );
    }
    return (
      'Structure Type/Structure/Component/Element/Activity/Rfi-Description :',
      '$structureType/$structure/$component/$element/$activity/$rfiDescriptionSelected',
    );
  }
}

class RfiInspectionPdfFonts {
  const RfiInspectionPdfFonts({
    required this.regular,
    required this.bold,
    this.fallback = const <pw.Font>[],
    this.unicode = false,
  });

  final pw.Font regular;
  final pw.Font bold;

  /// Extra scripts (e.g. Devanagari for a Hindi location).
  final List<pw.Font> fallback;
  final bool unicode;

  factory RfiInspectionPdfFonts.helvetica() => RfiInspectionPdfFonts(
    regular: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
  );

  /// Noto Sans (+ Devanagari) when reachable, Helvetica otherwise.
  static Future<RfiInspectionPdfFonts> load() async {
    try {
      final pw.Font regular = await PdfGoogleFonts.notoSansRegular();
      final pw.Font bold = await PdfGoogleFonts.notoSansBold();
      final List<pw.Font> fallback = <pw.Font>[];
      try {
        fallback.add(await PdfGoogleFonts.notoSansDevanagariRegular());
      } on Object {
        // Latin-only location then.
      }
      return RfiInspectionPdfFonts(
        regular: regular,
        bold: bold,
        fallback: fallback,
        unicode: true,
      );
    } on Object {
      return RfiInspectionPdfFonts.helvetica();
    }
  }
}

/// Builds the inspection PDF pages (before external PDFs are appended).
class RfiInspectionPdf {
  const RfiInspectionPdf._();

  static const double _pageH = 842;
  static const PdfColor _yellow = PdfColor(1, 1, 0);
  static const PdfColor _grey = PdfColor.fromInt(0xFF646464);
  static const PdfColor _headFill = PdfColor.fromInt(0xFFDCDCDC);

  static Future<Uint8List> build({
    required RfiInspectionPdfData data,
    required RfiInspectionPdfFonts fonts,
    Uint8List? logo,
  }) async {
    final String Function(String) t = fonts.unicode
        ? (String v) => v
        : _winAnsi;
    final pw.Document doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
        fontFallback: fonts.fallback,
      ),
      title: data.rfiNo,
    );
    doc.addPage(_firstPage(data, t, logo));
    doc.addPage(_detailPages(data, t));
    return doc.save();
  }

  // ---------------------------------------------------------------- page 1

  static pw.Page _firstPage(
    RfiInspectionPdfData d,
    String Function(String) t,
    Uint8List? logo,
  ) {
    final (String label, String value) = d.detailsLine;
    final String status = d.inspectionStatus.trim();
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context context) {
        return pw.Stack(
          children: <pw.Widget>[
            _box(30, 25, 540, 780),
            if (logo != null)
              pw.Positioned(
                left: 35,
                top: 30,
                child: pw.Image(pw.MemoryImage(logo), width: 60, height: 60),
              ),
            _centered(320, 55, 'South Western Railway', 16, bold: true),
            _centered(
              320,
              70,
              '(Ministry of Railways, Government of India)',
              10,
            ),
            _fill(31, 90, 538, 30, _yellow),
            _fitted(40, 90, 500, 30, t('Contract :- ${d.contract}')),
            _box(30, 120, 540, 20),
            _text(40, 135, 'Engineer :- South Western Railway', 11),
            _fill(31, 141, 538, 29, _yellow),
            _fitted(40, 141, 500, 29, t('Contractor :- ${d.contractor}')),
            _box(30, 170, 540, 490),
            _text(40, 185, 'Part - I :', 12, bold: true),
            _text(
              300,
              185,
              t('RFI.No : ${d.rfiNo.isEmpty ? '...' : d.rfiNo}'),
              10,
              bold: true,
              width: 250,
            ),
            _text(40, 205, "Name of Contractor's Representative :", 10),
            _text(212, 205, t(d.contractorRep), 10, width: 135),
            _text(350, 205, 'Contractor Submitted On:', 10),
            _text(465, 205, t(d.conSubmittedOn), 10, width: 100),
            _text(40, 225, 'RFI Raised On:', 10),
            _text(130, 225, t(d.raisedOn), 10),
            _text(350, 225, 'Engineer Submitted On:', 10),
            _text(465, 225, t(d.enggSubmittedOn), 10, width: 100),
            _text(40, 245, label, 10, bold: true, color: _grey, width: 520),
            _text(40, 260, t(value), 10, width: 500),
            _text(40, 282, 'Location:', 10, bold: true),
            _text(
              85,
              282,
              t(d.location.isEmpty ? 'Not Provided' : d.location),
              10,
              width: 400,
            ),
            _text(40, 317, 'RFI Description:', 10, bold: true),
            _box(40, 328, 510, 40),
            _text(45, 343, t(d.rfiDescription), 10, width: 500),
            _text(40, 445, "Part - II : Engineer's Remarks", 12, bold: true),
            _text(50, 460, 'Submitted By', 10),
            _text(350, 460, 'Received By', 10),
            _text(50, 475, 'Contractor', 10),
            _text(350, 475, 'Engineer', 10),
            _box(50, 490, 12, 12),
            _box(350, 490, 12, 12),
            if (status == 'Accepted') _tick(50, 490),
            if (status == 'Rejected') _tick(350, 490),
            _text(70, 500, 'Approved', 10),
            _text(370, 500, 'Not Approved', 10),
            _text(40, 530, 'Remarks:', 11, bold: true),
            if (status.toLowerCase() == 'rejected')
              _text(50, 550, t(d.engineerRemarks), 10, width: 495),
            _text(80, _pageH - 60, 'Contractor Representative', 10),
            _text(316, _pageH - 60, 'SWR Representative', 10),
          ],
        );
      },
    );
  }

  /// jsPDF draws text on a baseline; place the box so the baseline lands
  /// on [baseline].
  static pw.Widget _text(
    double x,
    double baseline,
    String text,
    double size, {
    bool bold = false,
    PdfColor color = PdfColors.black,
    double? width,
  }) {
    final pw.Widget child = pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
        lineSpacing: size * 0.2,
      ),
    );
    return pw.Positioned(
      left: x,
      top: baseline - size * 0.95,
      child: width == null ? child : pw.SizedBox(width: width, child: child),
    );
  }

  static pw.Widget _centered(
    double centerX,
    double baseline,
    String text,
    double size, {
    bool bold = false,
  }) {
    const double width = 400;
    return pw.Positioned(
      left: centerX - width / 2,
      top: baseline - size * 0.95,
      child: pw.SizedBox(
        width: width,
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: size,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Bold text shrunk from 11pt to 7pt until it fits the box height, like
  /// the web's `fitTextInFixedBox`.
  static pw.Widget _fitted(
    double x,
    double top,
    double width,
    double height,
    String text,
  ) {
    double size = 11;
    while (size > 7) {
      final double perLine = width / (size * 0.56);
      final int lines = (text.length / perLine).ceil().clamp(1, 99);
      if (lines * size * 1.15 <= height - 8) {
        break;
      }
      size--;
    }
    return pw.Positioned(
      left: x,
      top: top,
      child: pw.SizedBox(
        width: width,
        height: height,
        child: pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            text,
            maxLines: 2,
            style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ),
    );
  }

  static pw.Widget _box(double x, double y, double w, double h) {
    return pw.Positioned(
      left: x,
      top: y,
      child: pw.Container(
        width: w,
        height: h,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 1),
        ),
      ),
    );
  }

  static pw.Widget _fill(double x, double y, double w, double h, PdfColor c) {
    return pw.Positioned(
      left: x,
      top: y,
      child: pw.Container(width: w, height: h, color: c),
    );
  }

  static pw.Widget _tick(double x, double y) {
    return pw.Positioned(
      left: x,
      top: y,
      child: pw.SizedBox(
        width: 12,
        height: 12,
        child: pw.CustomPaint(
          size: const PdfPoint(12, 12),
          painter: (PdfGraphics canvas, PdfPoint size) {
            canvas
              ..setStrokeColor(PdfColors.black)
              ..setLineWidth(1.5)
              ..moveTo(2, 6)
              ..lineTo(5, 3)
              ..lineTo(10, 10)
              ..strokePath();
          },
        ),
      ),
    );
  }

  // --------------------------------------------------------- pages 2 ... n

  static pw.MultiPage _detailPages(
    RfiInspectionPdfData d,
    String Function(String) t,
  ) {
    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 45, 40, 45),
        buildBackground: (pw.Context context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
            ),
          ),
        ),
      ),
      build: (pw.Context context) => <pw.Widget>[
        if (d.validationRows.isNotEmpty) ...<pw.Widget>[
          _heading('Validation History:', 11),
          _table(
            const <String>[
              'No.',
              'Validation Type',
              'Validated By',
              'Status',
              'Validated On',
              'Remarks / Comment',
            ],
            d.validationRows,
            t,
            fontSize: 7,
          ),
          pw.SizedBox(height: 20),
        ],
        _heading('Enclosures:', 11),
        pw.SizedBox(height: 8),
        _enclosureTicks(d, t),
        pw.SizedBox(height: 22),
        _heading('Inspection Description (Contractor):', 10),
        pw.Text(t(_normalize(d.inspDescriptionCon)), style: _body9),
        pw.SizedBox(height: 15),
        _heading('Inspection Description (Client):', 10),
        pw.Text(t(_normalize(d.inspDescriptionEngg)), style: _body9),
        pw.SizedBox(height: 20),
        if (d.isWork && d.workDetails.isNotEmpty) ...<pw.Widget>[
          _heading('Work Details', 11),
          _table(
            const <String>[
              'Activity',
              'Unit',
              'Scope',
              'Completed Till Date',
              'Inspection Quantity',
            ],
            d.workDetails,
            t,
          ),
          pw.SizedBox(height: 20),
        ],
        if (d.isWork && d.earthworkDetails.isNotEmpty) ...<pw.Widget>[
          _heading(
            '${d.structureType.isEmpty ? 'Additional' : d.structureType} Inspection Details',
            11,
          ),
          _table(
            const <String>['Field', 'Details'],
            <List<String>>[
              for (final (String label, String value) in d.earthworkDetails)
                <String>[label, value],
            ],
            t,
          ),
          pw.SizedBox(height: 20),
        ],
        _heading('Measurement Record', 11),
        _table(
          <String>[
            if (d.isWork) ...<String>['Component', 'Element', 'Activity'],
            'Type of Measurement',
            'Units',
            'L',
            'B',
            'H',
            'Weight',
            'No.',
            'Total Qty.',
          ],
          <List<String>>[
            for (final RfiPdfMeasurement m in d.measurements)
              <String>[
                if (d.isWork) ...<String>[
                  m.component,
                  m.element,
                  m.activityName,
                ],
                m.type,
                m.units,
                m.l,
                m.b,
                m.h,
                m.weight,
                m.no,
                m.total,
              ],
          ],
          t,
        ),
        pw.SizedBox(height: 30),
        ..._checklists(d, t),
        ..._images('Contractor Site Images:', d.contractorImages),
        ..._images('Engineer Site Images:', d.engineerImages),
      ],
    );
  }

  static const pw.TextStyle _body9 = pw.TextStyle(fontSize: 9);

  static pw.Widget _heading(String text, double size) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _table(
    List<String> headers,
    List<List<String>> rows,
    String Function(String) t, {
    double fontSize = 8,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: <List<String>>[
        for (final List<String> row in rows)
          row.map((String v) => t(v)).toList(),
      ],
      headerStyle: pw.TextStyle(
        fontSize: fontSize,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: fontSize),
      headerDecoration: const pw.BoxDecoration(color: _headFill),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(3),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.25),
    );
  }

  /// "☑ 1) RCC Works - Concrete", three per row.
  static pw.Widget _enclosureTicks(
    RfiInspectionPdfData d,
    String Function(String) t,
  ) {
    final List<String> names = <String>[];
    for (final RfiPdfEnclosure e in d.enclosures) {
      final String name = e.enclosure.trim();
      if (name.isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 20),
      child: pw.Wrap(
        runSpacing: 10,
        children: <pw.Widget>[
          for (int i = 0; i < names.length; i++)
            pw.SizedBox(
              width: 160,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Stack(
                    children: <pw.Widget>[
                      pw.Container(
                        width: 8,
                        height: 8,
                        margin: const pw.EdgeInsets.only(top: 1),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 0.8),
                        ),
                      ),
                      pw.SizedBox(
                        width: 8,
                        height: 9,
                        child: pw.CustomPaint(
                          size: const PdfPoint(8, 9),
                          painter: (PdfGraphics canvas, PdfPoint size) {
                            canvas
                              ..setLineWidth(1.2)
                              ..moveTo(1.5, 4)
                              ..lineTo(3.5, 1.5)
                              ..lineTo(7, 7)
                              ..strokePath();
                          },
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 4),
                  pw.Expanded(
                    child: pw.Text(
                      t('${i + 1}) ${names[i]}'),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static List<pw.Widget> _checklists(
    RfiInspectionPdfData d,
    String Function(String) t,
  ) {
    if (d.inspectionMode.toUpperCase() == 'OFFLINE') {
      return const <pw.Widget>[];
    }
    final List<RfiPdfEnclosure> filled = d.enclosures
        .where(
          (RfiPdfEnclosure e) =>
              e.checklist.any((RfiPdfChecklistRow r) => r.hasContent),
        )
        .toList();
    if (filled.isEmpty) {
      return const <pw.Widget>[];
    }
    return <pw.Widget>[
      _heading('Enclosures: (RFI Description / Enclosure)', 12),
      pw.SizedBox(height: 6),
      for (int i = 0; i < filled.length; i++) ...<pw.Widget>[
        _heading(
          t(
            'Enclosure ${i + 1}: ${filled[i].rfiDescription} / ${filled[i].enclosure}',
          ),
          11,
        ),
        _table(
          const <String>[
            'ID',
            'Description',
            'Contractor Status',
            'Engineer Status',
            'Contractor Remark',
            'Engineer Remark',
          ],
          <List<String>>[
            for (final (int n, RfiPdfChecklistRow r)
                in filled[i].checklist
                    .where((RfiPdfChecklistRow r) => r.hasContent)
                    .indexed)
              <String>[
                '${n + 1}',
                r.description,
                r.contractorStatus,
                r.engineerStatus,
                r.contractorRemark,
                r.engineerRemark,
              ],
          ],
          t,
        ),
        pw.SizedBox(height: 20),
      ],
    ];
  }

  /// Two images per row, 220 x 140 (stretched like jsPDF `addImage`).
  static List<pw.Widget> _images(String title, List<Uint8List> images) {
    final List<pw.ImageProvider> decoded = <pw.ImageProvider>[];
    for (final Uint8List bytes in images) {
      if (RfiStoredFile.looksLikeImage(bytes)) {
        decoded.add(pw.MemoryImage(bytes));
      }
    }
    if (decoded.isEmpty) {
      return const <pw.Widget>[];
    }
    pw.Widget row(List<pw.ImageProvider> pair) => pw.Padding(
      padding: const pw.EdgeInsets.only(left: 20, bottom: 40),
      child: pw.Row(
        children: <pw.Widget>[
          for (int i = 0; i < pair.length; i++) ...<pw.Widget>[
            if (i > 0) pw.SizedBox(width: 30),
            pw.SizedBox(
              width: 220,
              height: 140,
              child: pw.Image(pair[i], fit: pw.BoxFit.fill),
            ),
          ],
        ],
      ),
    );
    final List<List<pw.ImageProvider>> rows = <List<pw.ImageProvider>>[
      for (int i = 0; i < decoded.length; i += 2)
        decoded.sublist(i, i + 2 > decoded.length ? decoded.length : i + 2),
    ];
    // The heading travels with the first row, so it never sits alone at the
    // bottom of a page (the web starts a new page in that case too).
    return <pw.Widget>[
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.SizedBox(height: 10),
            _heading(title, 12),
            pw.SizedBox(height: 8),
            row(rows.first),
          ],
        ),
      ),
      for (final List<pw.ImageProvider> pair in rows.skip(1)) row(pair),
    ];
  }

  static String _normalize(String text) {
    final String value = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return value.isEmpty ? '-' : value;
  }
}

/// Appends stored PDFs after the inspection pages, in the web's order:
/// enclosures, supporting documents, test reports. Invalid or duplicate
/// PDFs are skipped.
Future<Uint8List> mergeRfiInspectionPdf({
  required Uint8List main,
  List<Uint8List> enclosures = const <Uint8List>[],
  List<Uint8List> supporting = const <Uint8List>[],
  List<Uint8List> testReports = const <Uint8List>[],
}) async {
  final List<Uint8List> extra = rfiUniquePdfs(<Uint8List>[
    ...enclosures,
    ...supporting,
    ...testReports,
  ]);
  if (extra.isEmpty) {
    return main;
  }
  final Directory tmp = await getTemporaryDirectory();
  final Directory work = await tmp.createTemp('rfi_inspection_pdf_');
  try {
    final String output = p.join(work.path, 'inspection.pdf');
    final String merged = await PdfCombiner.generatePDFFromDocuments(
      inputs: <MergeInput>[
        MergeInput.bytes(main),
        for (final Uint8List pdf in extra) MergeInput.bytes(pdf),
      ],
      outputPath: output,
    );
    return File(merged).readAsBytes();
  } finally {
    try {
      await work.delete(recursive: true);
    } on Object {
      // Best-effort cleanup.
    }
  }
}

/// Keeps real PDFs only, dropping repeats (size + first 20 bytes, like the
/// web's fingerprint).
List<Uint8List> rfiUniquePdfs(List<Uint8List> pdfs) {
  final Set<String> seen = <String>{};
  final List<Uint8List> out = <Uint8List>[];
  for (final Uint8List pdf in pdfs) {
    if (!RfiStoredFile.looksLikePdf(pdf)) {
      continue;
    }
    final String key =
        '${pdf.length}-${pdf.sublist(0, pdf.length < 20 ? pdf.length : 20).join(',')}';
    if (seen.add(key)) {
      out.add(pdf);
    }
  }
  return out;
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
