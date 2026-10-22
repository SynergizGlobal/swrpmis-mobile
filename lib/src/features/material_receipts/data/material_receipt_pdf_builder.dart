import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:printing/printing.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/data/datasources/material_receipt_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/data/material_receipt_pdf.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_detail.dart';

typedef MaterialReceiptPdfProgress = void Function(String message);

Future<({Uint8List bytes, String fileName})> buildMergedMaterialReceiptPdf({
  required MaterialReceiptRemoteDataSource source,
  required String receiptId,
  required String baseUrl,
  MaterialReceiptPdfProgress? onProgress,
}) async {
  onProgress?.call('Loading receipt details…');
  final MaterialReceiptDetail detail = await source.fetchDetail(receiptId);
  final Uint8List? logoBytes = await source.loadLogo(baseUrl);

  final List<MaterialReceiptAttachmentPlan> plans =
      <MaterialReceiptAttachmentPlan>[];
  final int docTotal = detail.documents.length;
  for (int i = 0; i < detail.documents.length; i++) {
    final MaterialReceiptDocument document = detail.documents[i];
    onProgress?.call('Downloading attachments (${i + 1}/$docTotal)…');
    Uint8List? bytes;
    try {
      final ({Uint8List bytes, String fileName}) file = await source
          .downloadDocument(document.docId);
      bytes = file.bytes;
    } on Object {
      bytes = null;
    }
    plans.add(planMaterialReceiptAttachment(document: document, bytes: bytes));
  }

  onProgress?.call('Building cover pages…');
  final MaterialReceiptPdfFonts fonts = await _fonts();
  final Uint8List coverBytes = await MaterialReceiptPdf.buildCover(
    receipt: detail,
    attachments: plans,
    fonts: fonts,
    logoBytes: logoBytes,
  );

  final Directory tempRoot = await getTemporaryDirectory();
  final Directory workDir = await Directory(
    p.join(
      tempRoot.path,
      'mr_pdf_${DateTime.now().millisecondsSinceEpoch}',
    ),
  ).create(recursive: true);

  try {
    final List<MergeInput> inputs = <MergeInput>[
      MergeInput.bytes(coverBytes),
    ];

    for (int i = 0; i < plans.length; i++) {
      final MaterialReceiptAttachmentPlan plan = plans[i];
      onProgress?.call('Merging attachments (${i + 1}/${plans.length})…');
      final Uint8List divider = await MaterialReceiptPdf.buildDividerPage(
        receipt: detail,
        attachment: plan,
        index: i + 1,
        total: plans.length,
        fonts: fonts,
      );
      inputs.add(MergeInput.bytes(divider));

      final MaterialReceiptAttachmentKind? kind = plan.kind;
      final Uint8List? bytes = plan.bytes;
      if (kind == null || bytes == null) {
        inputs.add(
          MergeInput.bytes(
            await MaterialReceiptPdf.buildUnsupportedPage(
              attachment: plan,
              fonts: fonts,
            ),
          ),
        );
        continue;
      }

      if (kind == MaterialReceiptAttachmentKind.pdf) {
        final File pdfFile = File(
          p.join(workDir.path, 'doc_${plan.document.docId}.pdf'),
        );
        await pdfFile.writeAsBytes(bytes, flush: true);
        inputs.add(MergeInput.path(pdfFile.path));
        continue;
      }

      final String footer =
          'Attachment ${i + 1} of ${plans.length}: '
          '${plan.document.docType}'
          '${plan.document.fileName.trim().isEmpty ? '' : ' (${plan.document.fileName})'}'
          ' - Receipt ${detail.receiptId}';
      inputs.add(
        MergeInput.bytes(
          await MaterialReceiptPdf.buildImagePage(
            imageBytes: bytes,
            footer: footer,
            fonts: fonts,
          ),
        ),
      );
    }

    onProgress?.call('Combining PDF…');
    final String outputPath = p.join(
      workDir.path,
      'Material_Receipt_${_safeId(detail.receiptId)}.pdf',
    );
    final String mergedPath = await PdfCombiner.generatePDFFromDocuments(
      inputs: inputs,
      outputPath: outputPath,
    );
    final Uint8List mergedBytes = await File(mergedPath).readAsBytes();
    return (
      bytes: mergedBytes,
      fileName: 'Material_Receipt_${_safeId(detail.receiptId)}.pdf',
    );
  } finally {
    try {
      if (await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
    } on Object {
      // Best-effort cleanup.
    }
  }
}

Future<MaterialReceiptPdfFonts> _fonts() async {
  try {
    return MaterialReceiptPdfFonts(
      regular: await PdfGoogleFonts.notoSansRegular(),
      bold: await PdfGoogleFonts.notoSansBold(),
    );
  } on Object {
    return MaterialReceiptPdfFonts.helvetica();
  }
}

String _safeId(String receiptId) {
  final String safe = receiptId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return safe.isEmpty ? 'receipt' : safe;
}
