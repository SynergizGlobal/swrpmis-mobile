import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/rfi_inspection_pdf.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_report.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_log_links.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

/// Builds the validation list / preview "Download PDF" report to match the web
/// client-side `{rfiId}_RfiReport.pdf` (jsPDF cover pages + merged file PDFs).
Future<Uint8List> buildRfiValidationReportPdf({
  required RfiValidationReport report,
  Uint8List? logoBytes,
  Map<String, Uint8List> imageBytesByPath = const <String, Uint8List>{},
  List<Uint8List> enclosurePdfs = const <Uint8List>[],
  List<Uint8List> attachmentPdfs = const <Uint8List>[],
  List<Uint8List> supportPdfs = const <Uint8List>[],
}) async {
  final _Fonts fonts = await _loadFonts();
  final Uint8List cover = await _buildCoverPages(
    report: report,
    fonts: fonts,
    logoBytes: logoBytes,
    imageBytesByPath: imageBytesByPath,
  );
  return mergeRfiInspectionPdf(
    main: cover,
    enclosures: enclosurePdfs,
    supporting: <Uint8List>[...attachmentPdfs, ...supportPdfs],
  );
}

Future<_Fonts> _loadFonts() async {
  try {
    return _Fonts(
      regular: await PdfGoogleFonts.notoSansRegular(),
      bold: await PdfGoogleFonts.notoSansBold(),
    );
  } on Object {
    return _Fonts(
      regular: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );
  }
}

class _Fonts {
  const _Fonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}

Future<Uint8List> _buildCoverPages({
  required RfiValidationReport report,
  required _Fonts fonts,
  Uint8List? logoBytes,
  required Map<String, Uint8List> imageBytesByPath,
}) async {
  final RfiValidationReportDetails d = report.details;
  final pw.Document doc = pw.Document();
  pw.MemoryImage? logo;
  if (logoBytes != null && RfiStoredFile.looksLikeImage(logoBytes)) {
    try {
      logo = pw.MemoryImage(logoBytes);
    } on Object {
      logo = null;
    }
  }

  final String status = d.displayStatus;
  final PdfColor statusColor = switch (status) {
    'Rejected' || 'Deleted' => const PdfColor.fromInt(0xFFFF0000),
    'Closed' => const PdfColor.fromInt(0xFF0066CC),
    _ => const PdfColor.fromInt(0xFF008000),
  };

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
      ),
      build: (pw.Context context) {
        return <pw.Widget>[
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              if (logo != null)
                pw.Container(
                  width: 56,
                  height: 56,
                  margin: const pw.EdgeInsets.only(right: 8),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
              pw.Expanded(
                child: pw.Column(
                  children: <pw.Widget>[
                    pw.Text(
                      RfiLogLinks.clientName,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'REQUEST FOR INSPECTION (RFI) REPORT',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (logo != null) pw.SizedBox(width: 64),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 0.8),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text(
                'Client:\n${RfiLogLinks.clientName}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  children: <pw.TextSpan>[
                    pw.TextSpan(
                      text: 'RFI Status: ',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.TextSpan(
                      text: status,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          _kvTable(<List<String>>[
            <String>['Consultant', rfiValidationBlank(d.consultant)],
            <String>['Contract', rfiValidationBlank(d.contract)],
            <String>['Contractor', rfiValidationBlank(d.contractor)],
            <String>['Contract ID', rfiValidationBlank(d.contractId)],
            <String>['RFI ID', rfiValidationBlank(d.rfiId)],
            <String>['Location', rfiValidationBlank(d.location)],
            <String>[
              'Proposed Date',
              rfiValidationBlank(d.proposedInspectionDate),
            ],
            <String>[
              'Proposed Time',
              rfiValidationBlank(d.proposedInspectionTime),
            ],
            <String>[
              'Contractor Inspected On',
              rfiValidationBlank(d.conInspectedOn),
            ],
            <String>[
              'Client Inspected On',
              rfiValidationBlank(d.enggInspectedOn),
            ],
            <String>['RFI Description', rfiValidationBlank(d.rfiDescription)],
            <String>['RFI Category', rfiValidationBlank(d.rfiCategory)],
            <String>['Enclosures', rfiValidationBlank(d.enclosures)],
            <String>[
              "Contractor's Representative",
              rfiValidationBlank(d.contractorRepresentative),
            ],
            <String>[
              'Client Representative',
              rfiValidationBlank(d.clientRepresentative),
            ],
            <String>[
              'Engineer inspection approval',
              rfiValidationBlank(d.testStatus),
            ],
            <String>[
              'Description by Contractor',
              rfiValidationBlank(d.descriptionByContractor),
            ],
          ]),
          pw.SizedBox(height: 12),
          pw.Text(
            'RFI Validation Details:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 6),
          if (report.validationList.isEmpty)
            pw.Text(
              'No validation history found.',
              style: const pw.TextStyle(fontSize: 9),
            )
          else
            _dataTable(
              headers: const <String>[
                'No.',
                'Validation Type',
                'Validated By',
                'Status',
                'Validated On',
                'Remarks',
                'Comment',
              ],
              rows: <List<String>>[
                for (int i = 0; i < report.validationList.length; i++)
                  <String>[
                    '${i + 1}',
                    rfiValidationBlank(report.validationList[i].validationType),
                    rfiValidationBlank(report.validationList[i].validatorName),
                    rfiValidationBlank(
                      report.validationList[i].status,
                    ).replaceAll('_', ' '),
                    rfiValidationBlank(report.validationList[i].validatedOn),
                    rfiValidationBlank(report.validationList[i].remarks),
                    rfiValidationBlank(report.validationList[i].comment),
                  ],
              ],
            ),
        ];
      },
    ),
  );

  final bool isWork = d.rfiCategory.trim().toUpperCase() == 'WORK';
  final bool isMaterial = d.rfiCategory.trim().toUpperCase() == 'MATERIAL';

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
      ),
      build: (pw.Context context) {
        final List<pw.Widget> children = <pw.Widget>[];
        if (isWork && report.workDetails.isNotEmpty) {
          children.addAll(<pw.Widget>[
            _sectionTitle('Work Details'),
            _dataTable(
              headers: const <String>[
                'Activity Name',
                'Unit',
                'Scope',
                'Completed Till Date',
                'Inspection Quantity',
              ],
              rows: <List<String>>[
                for (final RfiValidationWorkDetail row in report.workDetails)
                  <String>[
                    rfiValidationBlank(row.activityName),
                    rfiValidationBlank(row.unit),
                    rfiValidationBlank(row.scope),
                    rfiValidationBlank(row.completedTillDate),
                    rfiValidationBlank(row.inspectionQuantity),
                  ],
              ],
            ),
            pw.SizedBox(height: 12),
          ]);
        }
        if (isMaterial && report.materialDetails.isNotEmpty) {
          children.addAll(<pw.Widget>[
            _sectionTitle('Material Details'),
            _dataTable(
              headers: const <String>['Material', 'Inspection Quantity'],
              rows: <List<String>>[
                for (final RfiValidationMaterialDetail row
                    in report.materialDetails)
                  <String>[
                    rfiValidationBlank(row.material),
                    rfiValidationBlank(row.inspectionQuantity),
                  ],
              ],
            ),
            pw.SizedBox(height: 12),
          ]);
        }
        if (report.measurementDetails.isNotEmpty) {
          children.addAll(<pw.Widget>[
            _sectionTitle('Measurement Details'),
            _dataTable(
              headers: <String>[
                if (isWork) ...<String>['Component', 'Element', 'Activity'],
                'Description',
                'Type',
                'Units',
                'Length',
                'Breadth',
                'Height',
                'Weight',
                'Count',
                'Total Quantity',
              ],
              rows: <List<String>>[
                for (final RfiValidationMeasurement row
                    in report.measurementDetails)
                  <String>[
                    if (isWork) ...<String>[
                      rfiValidationBlank(row.component),
                      rfiValidationBlank(row.element),
                      rfiValidationBlank(row.activityName),
                    ],
                    rfiValidationBlank(row.description),
                    rfiValidationBlank(row.measurementType),
                    rfiValidationBlank(row.units),
                    rfiValidationBlank(row.length),
                    rfiValidationBlank(row.breadth),
                    rfiValidationBlank(row.height),
                    rfiValidationBlank(row.weight),
                    rfiValidationBlank(row.count),
                    rfiValidationBlank(row.totalQty),
                  ],
              ],
            ),
            pw.SizedBox(height: 12),
          ]);
        }
        for (final RfiValidationChecklistGroup group
            in report.checklistGroups) {
          children.addAll(<pw.Widget>[
            _sectionTitle(
              group.enclosureName.isEmpty
                  ? rfiValidationBlank(group.rfiDescription)
                  : group.enclosureName,
            ),
            pw.Text(
              'RFI Description: ${rfiValidationBlank(group.rfiDescription)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Grade Of Concrete: ${rfiValidationBlank(group.gradeOfConcrete)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 6),
            _dataTable(
              headers: const <String>[
                'ID',
                'Description',
                'Contractor Status',
                'AE Status',
                'Contractor Remarks',
                'AE Remarks',
              ],
              rows: <List<String>>[
                for (int i = 0; i < group.checklist.length; i++)
                  <String>[
                    '${i + 1}',
                    rfiValidationBlank(group.checklist[i].checklistDescription),
                    rfiValidationBlank(group.checklist[i].conStatus),
                    rfiValidationBlank(group.checklist[i].aeStatus),
                    rfiValidationBlank(group.checklist[i].contractorRemark),
                    rfiValidationBlank(group.checklist[i].aeRemark),
                  ],
              ],
            ),
            pw.SizedBox(height: 12),
          ]);
        }
        children.addAll(
          _imageSection(
            'Contractor Selfie',
            d.contractorSelfiePaths,
            imageBytesByPath,
          ),
        );
        children.addAll(
          _imageSection(
            'Contractor Site Images',
            d.contractorSiteImagePaths,
            imageBytesByPath,
          ),
        );
        children.addAll(
          _imageSection(
            'Inspector Selfie',
            d.clientSelfiePaths,
            imageBytesByPath,
          ),
        );
        children.addAll(
          _imageSection(
            'Inspector Site Images',
            d.clientSiteImagePaths,
            imageBytesByPath,
          ),
        );
        if (children.isEmpty) {
          children.add(pw.SizedBox());
        }
        return children;
      },
    ),
  );

  return doc.save();
}

pw.Widget _sectionTitle(String title) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      title,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
    ),
  );
}

pw.Widget _kvTable(List<List<String>> rows) {
  return pw.Table(
    columnWidths: const <int, pw.TableColumnWidth>{
      0: pw.FixedColumnWidth(150),
      1: pw.FlexColumnWidth(),
    },
    children: <pw.TableRow>[
      for (final List<String> row in rows)
        pw.TableRow(
          children: <pw.Widget>[
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(
                row[0],
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(row[1], style: const pw.TextStyle(fontSize: 9)),
            ),
          ],
        ),
    ],
  );
}

pw.Widget _dataTable({
  required List<String> headers,
  required List<List<String>> rows,
}) {
  final PdfColor head = const PdfColor.fromInt(0xFF006699);
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(
      color: PdfColors.white,
      fontWeight: pw.FontWeight.bold,
      fontSize: 7,
    ),
    headerDecoration: pw.BoxDecoration(color: head),
    cellStyle: const pw.TextStyle(fontSize: 7),
    cellAlignment: pw.Alignment.topLeft,
    headerAlignment: pw.Alignment.center,
    cellPadding: const pw.EdgeInsets.all(3),
    border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.4),
  );
}

List<pw.Widget> _imageSection(
  String title,
  List<String> paths,
  Map<String, Uint8List> imageBytesByPath,
) {
  final List<pw.MemoryImage> images = <pw.MemoryImage>[];
  for (final String path in paths) {
    if (path.toLowerCase().endsWith('.pdf')) {
      continue;
    }
    final Uint8List? bytes = imageBytesByPath[path];
    if (bytes == null || !RfiStoredFile.looksLikeImage(bytes)) {
      continue;
    }
    try {
      images.add(pw.MemoryImage(bytes));
    } on Object {
      continue;
    }
  }
  if (images.isEmpty) {
    return const <pw.Widget>[];
  }
  return <pw.Widget>[
    pw.SizedBox(height: 10),
    pw.Text(
      '$title:',
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
    ),
    pw.SizedBox(height: 8),
    pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <pw.Widget>[
        for (final pw.MemoryImage image in images)
          pw.Container(
            width: 220,
            height: 160,
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
      ],
    ),
  ];
}
