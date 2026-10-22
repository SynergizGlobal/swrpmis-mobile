import 'dart:math' as math;
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_detail.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_parse.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_log_links.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

enum MaterialReceiptAttachmentKind { pdf, png, jpg }

class MaterialReceiptAttachmentPlan {
  const MaterialReceiptAttachmentPlan({
    required this.document,
    required this.status,
    this.kind,
    this.bytes,
    this.pageCount = 0,
  });

  final MaterialReceiptDocument document;
  final String status;
  final MaterialReceiptAttachmentKind? kind;
  final Uint8List? bytes;
  final int pageCount;
}

class MaterialReceiptPdfFonts {
  const MaterialReceiptPdfFonts({
    required this.regular,
    required this.bold,
  });

  final pw.Font regular;
  final pw.Font bold;

  factory MaterialReceiptPdfFonts.helvetica() {
    return MaterialReceiptPdfFonts(
      regular: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );
  }
}

class MaterialReceiptPdf {
  const MaterialReceiptPdf._();

  static const PdfColor _ink = PdfColor.fromInt(0xFF1A1A1F);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B6B78);
  static const PdfColor _line = PdfColor.fromInt(0xFFCCCCD6);
  static const PdfColor _head = PdfColor.fromInt(0xFFEBF0F7);
  static const PdfColor _accent = PdfColor.fromInt(0xFF1A458F);
  static const PdfColor _warn = PdfColor.fromInt(0xFFB34D0D);

  static Future<Uint8List> buildCover({
    required MaterialReceiptDetail receipt,
    required List<MaterialReceiptAttachmentPlan> attachments,
    required MaterialReceiptPdfFonts fonts,
    Uint8List? logoBytes,
  }) async {
    final pw.Document document = pw.Document(
      title: 'Material Receipt ${receipt.receiptId}',
      producer: 'SWR PMIS',
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 40,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
        build: (pw.Context context) {
          return <pw.Widget>[
            ..._header(receipt, fonts, logoBytes),
            _sectionTitle('Receipt Details', fonts),
            ..._receiptDetails(receipt, fonts),
            pw.SizedBox(height: 8),
            _sectionTitle(
              'Material Details (${receipt.items.length} '
              'item${receipt.items.length == 1 ? '' : 's'})',
              fonts,
            ),
            if (receipt.items.isEmpty)
              _mutedText('No material items.', fonts)
            else
              _itemsTable(receipt.items, fonts),
            if (receipt.engineerRemarks.trim().isNotEmpty) ...<pw.Widget>[
              pw.SizedBox(height: 8),
              _sectionTitle('Engineer Remarks', fonts),
              pw.Text(
                _safe(receipt.engineerRemarks),
                style: pw.TextStyle(font: fonts.regular, fontSize: 9.5),
              ),
            ],
            pw.SizedBox(height: 8),
            _sectionTitle(
              'Attachments (${attachments.length})',
              fonts,
            ),
            if (attachments.isEmpty)
              _mutedText('No attachments uploaded for this receipt.', fonts)
            else
              _attachmentsTable(attachments, fonts),
          ];
        },
      ),
    );
    return document.save();
  }

  static Future<Uint8List> buildDividerPage({
    required MaterialReceiptDetail receipt,
    required MaterialReceiptAttachmentPlan attachment,
    required int index,
    required int total,
    required MaterialReceiptPdfFonts fonts,
  }) async {
    final pw.Document document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
        build: (pw.Context context) {
          final List<String> lines = <String>[
            if (attachment.document.fileName.trim().isNotEmpty)
              'File: ${attachment.document.fileName}',
            'Material Receipt: ${materialReceiptBlank(receipt.receiptId)}',
            if (attachment.kind != null)
              'Pages that follow: ${attachment.pageCount}'
            else
              attachment.status,
          ];
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.SizedBox(height: 220),
              pw.Text(
                'ATTACHMENT $index OF $total',
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 11,
                  color: _muted,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                _safe(
                  attachment.document.docType.trim().isEmpty
                      ? 'Document'
                      : attachment.document.docType,
                ),
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 26,
                  color: _accent,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(height: 1, color: _accent),
              pw.SizedBox(height: 16),
              for (int i = 0; i < lines.length; i++)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(
                    _safe(lines[i]),
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: 11,
                      color: attachment.kind != null || i < lines.length - 1
                          ? _ink
                          : _warn,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
    return document.save();
  }

  static Future<Uint8List> buildUnsupportedPage({
    required MaterialReceiptAttachmentPlan attachment,
    required MaterialReceiptPdfFonts fonts,
  }) async {
    final pw.Document document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(
              _safe(
                'Attachment could not be merged: '
                '${attachment.document.docType} '
                '(${attachment.document.fileName})',
              ),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 11,
                color: _warn,
              ),
            ),
          );
        },
      ),
    );
    return document.save();
  }

  static Future<Uint8List> buildImagePage({
    required Uint8List imageBytes,
    required String footer,
    required MaterialReceiptPdfFonts fonts,
  }) async {
    final pw.Document document = pw.Document();
    final pw.MemoryImage image = pw.MemoryImage(imageBytes);
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(30, 30, 30, 24),
        build: (pw.Context context) {
          return pw.Column(
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                _safe(footer),
                style: pw.TextStyle(
                  font: fonts.regular,
                  fontSize: 7,
                  color: _muted,
                ),
              ),
            ],
          );
        },
      ),
    );
    return document.save();
  }

  static List<pw.Widget> _header(
    MaterialReceiptDetail receipt,
    MaterialReceiptPdfFonts fonts,
    Uint8List? logoBytes,
  ) {
    pw.Widget mark = pw.SizedBox(width: 62, height: 62);
    if (logoBytes != null && RfiStoredFile.looksLikeImage(logoBytes)) {
      mark = pw.Image(
        pw.MemoryImage(logoBytes),
        width: 62,
        height: 62,
        fit: pw.BoxFit.contain,
      );
    }
    final String contract = [
      receipt.contractId,
      receipt.contractShortName,
    ].where((String value) => value.trim().isNotEmpty).join(' - ');
    final String generated = DateFormat(
      'dd/MM/yyyy, HH:mm:ss',
    ).format(DateTime.now());
    return <pw.Widget>[
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          mark,
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              children: <pw.Widget>[
                pw.Text(
                  RfiLogLinks.clientName,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: fonts.bold, fontSize: 18),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '(Ministry of Railways, Government of India)',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: 10,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 62),
        ],
      ),
      pw.SizedBox(height: 10),
      _banner('Contract :- ${materialReceiptBlank(contract)}', fonts, highlight: true),
      if (receipt.engineerName.trim().isNotEmpty)
        _banner('Engineer :- ${receipt.engineerName}', fonts, highlight: false),
      if (_contractorLine(receipt).isNotEmpty)
        _banner(
          'Contractor :- ${_contractorLine(receipt)}',
          fonts,
          highlight: true,
        ),
      pw.SizedBox(height: 10),
      pw.Row(
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Text(
              'Part - I : Material Receipt',
              style: pw.TextStyle(font: fonts.bold, fontSize: 13),
            ),
          ),
          pw.Text(
            'Receipt No. : ${materialReceiptBlank(receipt.receiptId)}',
            style: pw.TextStyle(font: fonts.bold, fontSize: 13),
          ),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Status: ${formatMaterialReceiptStatus(receipt.status)}'
        '        Generated on: $generated',
        style: pw.TextStyle(font: fonts.regular, fontSize: 8.5, color: _muted),
      ),
      pw.SizedBox(height: 10),
    ];
  }

  static String _contractorLine(MaterialReceiptDetail receipt) {
    final String contractor = receipt.contractorName.trim();
    if (contractor.isNotEmpty) {
      return contractor;
    }
    return receipt.createdByName.trim();
  }

  static pw.Widget _banner(
    String text,
    MaterialReceiptPdfFonts fonts, {
    required bool highlight,
  }) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 2),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: pw.BoxDecoration(
        color: highlight ? PdfColors.yellow : PdfColors.white,
        border: pw.Border.all(color: _ink, width: 0.8),
      ),
      child: pw.Text(
        _safe(text),
        style: pw.TextStyle(
          font: highlight ? fonts.bold : fonts.regular,
          fontSize: 11,
        ),
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, MaterialReceiptPdfFonts fonts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.SizedBox(height: 6),
        pw.Text(
          title,
          style: pw.TextStyle(font: fonts.bold, fontSize: 11, color: _accent),
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 0.8, color: _accent),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static List<pw.Widget> _receiptDetails(
    MaterialReceiptDetail receipt,
    MaterialReceiptPdfFonts fonts,
  ) {
    final List<(String, String)> pairs = <(String, String)>[
      (
        'Project',
        [
          receipt.projectId,
          receipt.projectName,
        ].where((String value) => value.trim().isNotEmpty).join(' - '),
      ),
      (
        'Section',
        [
          receipt.sectionId,
          receipt.sectionName,
        ].where((String value) => value.trim().isNotEmpty).join(' - '),
      ),
      (
        'Contract',
        [
          receipt.contractId,
          receipt.contractShortName,
        ].where((String value) => value.trim().isNotEmpty).join(' - '),
      ),
      ('Source / Supplier', receipt.sourceSupplier),
      ('Batch / Lot No.', receipt.batchLotNo),
      ('Invoice No.', receipt.invoiceNo),
      ('Vehicle / Challan No.', receipt.vehicleChallanNo),
      ('Date of Delivery', receipt.deliveryDate),
      ('Place / Chainage', receipt.placeChainage),
      ('Remarks', receipt.remarks),
    ];
    final List<pw.Widget> rows = <pw.Widget>[];
    for (int i = 0; i < pairs.length; i += 2) {
      final List<(String, String)> slice = pairs.sublist(
        i,
        math.min(i + 2, pairs.length),
      );
      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              for (int j = 0; j < slice.length; j++)
                pw.Expanded(
                  child: pw.Padding(
                    padding: pw.EdgeInsets.only(left: j == 0 ? 0 : 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: <pw.Widget>[
                        pw.Text(
                          slice[j].$1,
                          style: pw.TextStyle(
                            font: fonts.regular,
                            fontSize: 7.5,
                            color: _muted,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          _safe(materialReceiptBlank(slice[j].$2)),
                          style: pw.TextStyle(
                            font: fonts.regular,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (slice.length == 1) pw.Expanded(child: pw.SizedBox()),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  static pw.Widget _itemsTable(
    List<MaterialReceiptItem> items,
    MaterialReceiptPdfFonts fonts,
  ) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(color: _line, width: 0.4),
        bottom: const pw.BorderSide(color: _line, width: 0.4),
      ),
      headerDecoration: const pw.BoxDecoration(color: _head),
      headerStyle: pw.TextStyle(font: fonts.bold, fontSize: 8),
      cellStyle: pw.TextStyle(font: fonts.regular, fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FixedColumnWidth(22),
        1: const pw.FlexColumnWidth(2.2),
        2: const pw.FlexColumnWidth(1.6),
        3: const pw.FlexColumnWidth(1.3),
        4: const pw.FixedColumnWidth(34),
        5: const pw.FixedColumnWidth(46),
        6: const pw.FixedColumnWidth(52),
        7: const pw.FixedColumnWidth(56),
        8: const pw.FlexColumnWidth(2.4),
      },
      headers: const <String>[
        '#',
        'Material',
        'Spec / Grade',
        'Size / Type',
        'Unit',
        'Qty Recd',
        'Qty Verified',
        'Decision',
        'Remarks',
      ],
      data: <List<String>>[
        for (int i = 0; i < items.length; i++)
          <String>[
            '${i + 1}',
            _safe(
              items[i].materialName.trim().isEmpty
                  ? items[i].materialCode
                  : items[i].materialName,
            ),
            _safe(materialReceiptBlank(items[i].gradeSpec)),
            _safe(materialReceiptBlank(items[i].sizeType)),
            _safe(materialReceiptBlank(items[i].unit)),
            _safe(materialReceiptBlank(items[i].quantity)),
            _safe(materialReceiptBlank(items[i].verifiedQuantity)),
            _safe(
              formatMaterialReceiptStatus(items[i].itemDecision) == '-'
                  ? ''
                  : formatMaterialReceiptStatus(items[i].itemDecision),
            ),
            _safe(
              [
                items[i].remarks,
                if (items[i].engineerItemRemarks.trim().isNotEmpty)
                  'Engr: ${items[i].engineerItemRemarks}',
              ].where((String value) => value.trim().isNotEmpty).join(' | '),
            ),
          ],
      ],
    );
  }

  static pw.Widget _attachmentsTable(
    List<MaterialReceiptAttachmentPlan> attachments,
    MaterialReceiptPdfFonts fonts,
  ) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(color: _line, width: 0.4),
        bottom: const pw.BorderSide(color: _line, width: 0.4),
      ),
      headerDecoration: const pw.BoxDecoration(color: _head),
      headerStyle: pw.TextStyle(font: fonts.bold, fontSize: 8),
      cellStyle: pw.TextStyle(font: fonts.regular, fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      headers: const <String>['#', 'Document', 'File Name', 'In this PDF'],
      data: <List<String>>[
        for (int i = 0; i < attachments.length; i++)
          <String>[
            '${i + 1}',
            _safe(materialReceiptBlank(attachments[i].document.docType)),
            _safe(materialReceiptBlank(attachments[i].document.fileName)),
            _safe(attachments[i].status),
          ],
      ],
    );
  }

  static pw.Widget _mutedText(String text, MaterialReceiptPdfFonts fonts) {
    return pw.Text(
      text,
      style: pw.TextStyle(font: fonts.regular, fontSize: 9, color: _muted),
    );
  }

  static String _safe(String value) {
    return value
        .replaceAll(RegExp(r'[\u2013\u2014]'), '-')
        .replaceAll(RegExp(r'[\u2018\u2019]'), "'")
        .replaceAll(RegExp(r'[\u201c\u201d]'), '"')
        .replaceAll('\u2026', '...')
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .trim();
  }
}

MaterialReceiptAttachmentPlan planMaterialReceiptAttachment({
  required MaterialReceiptDocument document,
  required Uint8List? bytes,
}) {
  if (bytes == null || bytes.isEmpty) {
    return MaterialReceiptAttachmentPlan(
      document: document,
      status: 'Not included - file could not be read',
    );
  }
  if (RfiStoredFile.looksLikePdf(bytes)) {
    final int pages = estimatePdfPageCount(bytes);
    return MaterialReceiptAttachmentPlan(
      document: document,
      kind: MaterialReceiptAttachmentKind.pdf,
      bytes: bytes,
      pageCount: pages < 1 ? 1 : pages,
      status: 'Included - ${pages < 1 ? 1 : pages} page(s)',
    );
  }
  if (_looksLikePng(bytes)) {
    return MaterialReceiptAttachmentPlan(
      document: document,
      kind: MaterialReceiptAttachmentKind.png,
      bytes: bytes,
      pageCount: 1,
      status: 'Included - 1 page',
    );
  }
  if (_looksLikeJpg(bytes)) {
    return MaterialReceiptAttachmentPlan(
      document: document,
      kind: MaterialReceiptAttachmentKind.jpg,
      bytes: bytes,
      pageCount: 1,
      status: 'Included - 1 page',
    );
  }
  return MaterialReceiptAttachmentPlan(
    document: document,
    status:
        'Not included - format cannot be merged into PDF (download it separately)',
  );
}

int estimatePdfPageCount(Uint8List bytes) {
  final int limit = math.min(bytes.length, 512 * 1024);
  final String sample = String.fromCharCodes(bytes.sublist(0, limit));
  int maxCount = 0;
  for (final RegExpMatch match in RegExp(r'/Count\s+(\d+)').allMatches(sample)) {
    final int value = int.tryParse(match.group(1) ?? '') ?? 0;
    if (value > maxCount) {
      maxCount = value;
    }
  }
  return maxCount;
}

bool _looksLikePng(Uint8List bytes) {
  return bytes.length >= 4 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;
}

bool _looksLikeJpg(Uint8List bytes) {
  return bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
}
