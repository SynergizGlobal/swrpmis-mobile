import 'dart:typed_data';
import 'dart:ui';

import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_log_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_validation_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/rfi_log_print.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/rfi_validation_report_pdf.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_report.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';

class RfiValidationReportPdfResult {
  const RfiValidationReportPdfResult({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

/// Fetches report detail (if needed) and media/PDF binaries, then builds the
/// same client-side `{rfiId}_RfiReport.pdf` the web Download button produces.
Future<RfiValidationReportPdfResult> buildRfiValidationReportPdfBytes({
  required RfiValidationRemoteDataSource validationSource,
  required RfiLogRemoteDataSource logSource,
  required String baseUrl,
  required String longRfiId,
  RfiValidationReport? report,
}) async {
  final RfiValidationReport resolved =
      report ?? await validationSource.fetchReportDetail(longRfiId);
  final Uint8List? logo = await logSource.loadLogo(baseUrl);

  final Map<String, Uint8List> images = <String, Uint8List>{};
  final List<Uint8List> enclosurePdfs = <Uint8List>[];
  final List<Uint8List> attachmentPdfs = <Uint8List>[];
  final List<Uint8List> supportPdfs = <Uint8List>[];

  Future<void> loadPath(String path) async {
    final String trimmed = path.trim();
    if (trimmed.isEmpty) {
      return;
    }
    try {
      final Uint8List bytes = await validationSource.previewStoredFile(trimmed);
      if (RfiStoredFile.looksLikePdf(bytes)) {
        enclosurePdfs.add(bytes);
      } else if (RfiStoredFile.looksLikeImage(bytes)) {
        images[trimmed] = bytes;
      }
    } on Object {
      // Skip missing media; still emit the cover pages.
    }
  }

  for (final String path in <String>[
    ...resolved.details.contractorSelfiePaths,
    ...resolved.details.contractorSiteImagePaths,
    ...resolved.details.clientSelfiePaths,
    ...resolved.details.clientSiteImagePaths,
  ]) {
    if (!path.toLowerCase().endsWith('.pdf')) {
      await loadPath(path);
    }
  }

  for (final RfiValidationEnclosureFile enclosure in resolved.enclosures) {
    await loadPath(enclosure.file);
  }

  for (final String path in splitRfiValidationPaths(
    resolved.details.testSiteDocumentsContractor,
  )) {
    await loadPath(path);
  }
  for (final String path in splitRfiValidationPaths(
    resolved.details.testResultContractor,
  )) {
    await loadPath(path);
  }
  for (final String path in splitRfiValidationPaths(
    resolved.details.testResultEngineer,
  )) {
    await loadPath(path);
  }

  Future<void> loadNamed(
    String fileName,
    String dir,
    List<Uint8List> sink,
  ) async {
    final String name = fileName.trim();
    if (name.isEmpty) {
      return;
    }
    try {
      final Uint8List bytes = await validationSource.previewNamedFile(
        fileName: name,
        dir: dir,
      );
      if (RfiStoredFile.looksLikePdf(bytes)) {
        sink.add(bytes);
      }
    } on Object {
      // Skip missing attachments.
    }
  }

  for (final RfiValidationAttachment attachment
      in resolved.details.attachments) {
    await loadNamed(attachment.fileName, 'attachment', attachmentPdfs);
  }
  for (final String name in splitRfiValidationPaths(
    resolved.details.conSupportFilePaths,
  )) {
    await loadNamed(RfiStoredFile.fileName(name), 'support', supportPdfs);
  }
  for (final String name in splitRfiValidationPaths(
    resolved.details.enggSupportFilePaths,
  )) {
    await loadNamed(RfiStoredFile.fileName(name), 'support', supportPdfs);
  }

  final Uint8List pdf = await buildRfiValidationReportPdf(
    report: resolved,
    logoBytes: logo,
    imageBytesByPath: images,
    enclosurePdfs: enclosurePdfs,
    attachmentPdfs: attachmentPdfs,
    supportPdfs: supportPdfs,
  );
  if (!RfiStoredFile.looksLikePdf(pdf)) {
    throw StateError('Unable to generate the RFI report PDF.');
  }
  return RfiValidationReportPdfResult(
    bytes: pdf,
    fileName: resolved.reportFileName,
  );
}

Future<void> downloadRfiValidationReportPdf({
  required RfiValidationRemoteDataSource validationSource,
  required RfiLogRemoteDataSource logSource,
  required String baseUrl,
  required String longRfiId,
  RfiValidationReport? report,
  Rect? sharePositionOrigin,
}) async {
  final RfiValidationReportPdfResult result =
      await buildRfiValidationReportPdfBytes(
        validationSource: validationSource,
        logSource: logSource,
        baseUrl: baseUrl,
        longRfiId: longRfiId,
        report: report,
      );
  await shareRfiLogFile(
    bytes: result.bytes,
    fileName: result.fileName,
    sharePositionOrigin: sharePositionOrigin,
  );
}
