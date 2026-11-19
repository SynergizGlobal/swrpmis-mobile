import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config_controller.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_log_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_validation_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/rfi_log_print.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/rfi_validation_report_download.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_report.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_log_links.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';

final rfiValidationStoredFileProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((Ref ref, String path) {
      ref.keepAlive();
      return ref
          .read(rfiValidationRemoteDataSourceProvider)
          .previewStoredFile(path);
    });

class RfiValidationPreviewPage extends ConsumerStatefulWidget {
  const RfiValidationPreviewPage({
    super.key,
    required this.longRfiId,
    this.stringRfiId,
  });

  final String longRfiId;
  final String? stringRfiId;

  static Future<void> open(
    BuildContext context, {
    required String longRfiId,
    String? stringRfiId,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => RfiValidationPreviewPage(
          longRfiId: longRfiId,
          stringRfiId: stringRfiId,
        ),
      ),
    );
  }

  @override
  ConsumerState<RfiValidationPreviewPage> createState() =>
      _RfiValidationPreviewPageState();
}

class _RfiValidationPreviewPageState
    extends ConsumerState<RfiValidationPreviewPage> {
  RfiValidationReport? _report;
  Object? _error;
  bool _loading = true;
  bool _busyPdf = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final RfiValidationReport report = await ref
          .read(rfiValidationRemoteDataSourceProvider)
          .fetchReportDetail(widget.longRfiId);
      if (!mounted) {
        return;
      }
      setState(() {
        _report = report;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Rect _shareOrigin() {
    final Size size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 2,
      height: 2,
    );
  }

  Future<void> _downloadPdf() async {
    final RfiValidationReport? report = _report;
    if (report == null || _busyPdf) {
      return;
    }
    setState(() => _busyPdf = true);
    try {
      await downloadRfiValidationReportPdf(
        validationSource: ref.read(rfiValidationRemoteDataSourceProvider),
        logSource: ref.read(rfiLogRemoteDataSourceProvider),
        baseUrl: ref.read(appConfigProvider).baseUrl,
        longRfiId: widget.longRfiId,
        report: report,
        sharePositionOrigin: _shareOrigin(),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Download failed',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : 'Failed to generate PDF. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _busyPdf = false);
      }
    }
  }

  Future<void> _printPdf() async {
    final RfiValidationReport? report = _report;
    if (report == null || _busyPdf) {
      return;
    }
    setState(() => _busyPdf = true);
    try {
      final RfiValidationReportPdfResult result =
          await buildRfiValidationReportPdfBytes(
            validationSource: ref.read(rfiValidationRemoteDataSourceProvider),
            logSource: ref.read(rfiLogRemoteDataSourceProvider),
            baseUrl: ref.read(appConfigProvider).baseUrl,
            longRfiId: widget.longRfiId,
            report: report,
          );
      if (!mounted) {
        return;
      }
      await presentRfiLogPdf(bytes: result.bytes, fileName: result.fileName);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Print failed',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : 'Unable to open the print sheet. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _busyPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFI Details Preview'),
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RfiContentLoader(loading: _loading || _busyPdf),
          Expanded(child: _body(context)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton(
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll<Size>(Size(88, 44)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  FilledButton(
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll<Size>(Size(88, 44)),
                      backgroundColor: WidgetStatePropertyAll<Color>(
                        Color(0xFF0B2F63),
                      ),
                    ),
                    onPressed: _report == null || _busyPdf ? null : _printPdf,
                    child: const Text('Print'),
                  ),
                  FilledButton(
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll<Size>(Size(120, 44)),
                      backgroundColor: WidgetStatePropertyAll<Color>(
                        Color(0xFF0B2F63),
                      ),
                    ),
                    onPressed: _report == null || _busyPdf ? null : _downloadPdf,
                    child: _busyPdf
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Download PDF'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null && _report == null) {
      final String message = _error is DioException
          ? userFriendlyErrorMessage(_error! as DioException)
          : 'Unable to load this preview.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final RfiValidationReport? report = _report;
    if (report == null) {
      return const SizedBox.expand();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: _content(context, report),
    );
  }

  List<Widget> _content(BuildContext context, RfiValidationReport report) {
    final RfiValidationReportDetails d = report.details;
    final String status = d.displayStatus;
    final Color statusColor = switch (status) {
      'Rejected' || 'Deleted' => const Color(0xFFDC2626),
      'Closed' => const Color(0xFF1D4ED8),
      _ => const Color(0xFF198754),
    };
    final bool isWork = d.rfiCategory.trim().toUpperCase() == 'WORK';

    return <Widget>[
      Text(
        'Request For Inspection (RFI)',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppTheme.brandPrimary,
        ),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          status,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
      const SizedBox(height: 8),
      _field('Client', RfiLogLinks.clientName),
      _field('Consultant', rfiValidationBlank(d.consultant)),
      _field('Contract', rfiValidationBlank(d.contract)),
      _field('Contractor', rfiValidationBlank(d.contractor)),
      _field('Contract ID', rfiValidationBlank(d.contractId)),
      _field('RFI ID', rfiValidationBlank(d.rfiId)),
      _field('Location', rfiValidationBlank(d.location)),
      _field('Proposed Date', rfiValidationBlank(d.proposedInspectionDate)),
      _field('Proposed Time', rfiValidationBlank(d.proposedInspectionTime)),
      _field(
        'Contractor Inspected On',
        rfiValidationBlank(d.conInspectedOn),
      ),
      _field('Client Inspected On', rfiValidationBlank(d.enggInspectedOn)),
      _field('RfiDescription', rfiValidationBlank(d.rfiDescription)),
      _field('Enclosures', rfiValidationBlank(d.enclosures)),
      _field(
        "Contractor's Representative",
        rfiValidationBlank(d.contractorRepresentative),
      ),
      _field(
        'Client Representative',
        rfiValidationBlank(d.clientRepresentative),
      ),
      _field('RFI Category', rfiValidationBlank(d.rfiCategory)),
      _field(
        'Engineer inspection approval',
        rfiValidationBlank(d.testStatus),
      ),
      _field(
        'Description by Contractor',
        rfiValidationBlank(d.descriptionByContractor),
      ),
      if (report.measurementDetails.isNotEmpty) ...<Widget>[
        const SizedBox(height: 8),
        _banner('Measurement Details'),
        _hTable(
          <String>[
            if (isWork) ...<String>['Component', 'Element', 'Activity'],
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
            for (final RfiValidationMeasurement row in report.measurementDetails)
              <String>[
                if (isWork) ...<String>[
                  rfiValidationBlank(row.component),
                  rfiValidationBlank(row.element),
                  rfiValidationBlank(row.activityName),
                ],
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
      ],
      for (final RfiValidationChecklistGroup group in report.checklistGroups) ...<
        Widget
      >[
        const SizedBox(height: 12),
        _banner(
          group.enclosureName.isEmpty
              ? rfiValidationBlank(group.rfiDescription)
              : group.enclosureName,
        ),
        _field('RFI Description', rfiValidationBlank(group.rfiDescription)),
        _field(
          'Grade Of Concrete',
          rfiValidationBlank(group.gradeOfConcrete),
        ),
        _hTable(
          const <String>[
            'ID',
            'Description',
            'Contractor Status',
            'AE Status',
            'Contractor Remarks',
            'AE Remarks',
          ],
          <List<String>>[
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
      ],
      const SizedBox(height: 12),
      _banner('RFI Validation Details'),
      if (report.validationList.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('No validation history found.'),
        )
      else
        _hTable(
          const <String>[
            'No.',
            'Validation Type',
            'Validated By',
            'Status',
            'Validated On',
            'Remarks',
            'Comment',
          ],
          <List<String>>[
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
      const SizedBox(height: 12),
      _inspectionPanel(
        title: 'Contractor Inspection',
        selfiePaths: d.contractorSelfiePaths,
        sitePaths: d.contractorSiteImagePaths,
      ),
      const SizedBox(height: 12),
      _inspectionPanel(
        title: 'Client Inspection',
        selfiePaths: d.clientSelfiePaths,
        sitePaths: d.clientSiteImagePaths,
      ),
      if (report.enclosures.isNotEmpty) ...<Widget>[
        const SizedBox(height: 16),
        Text(
          'Enclosures Uploaded',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.brandPrimary,
          ),
        ),
        for (final RfiValidationEnclosureFile enclosure
            in report.enclosures) ...<Widget>[
          const SizedBox(height: 8),
          _field(
            'RFI Description',
            rfiValidationBlank(enclosure.rfiDescription),
          ),
          _field('Enclosure', rfiValidationBlank(enclosure.enclosureName)),
          _EmbeddedPdfCard(
            title: RfiStoredFile.fileName(enclosure.file),
            loader: () => ref
                .read(rfiValidationRemoteDataSourceProvider)
                .previewStoredFile(enclosure.file),
          ),
        ],
      ],
      if (d.attachments.isNotEmpty) ...<Widget>[
        const SizedBox(height: 16),
        Text(
          'Attached Documents',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        for (final RfiValidationAttachment attachment in d.attachments) ...<
          Widget
        >[
          const SizedBox(height: 8),
          Text(
            'Description: ${rfiValidationBlank(attachment.description)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _EmbeddedPdfCard(
            title: attachment.fileName,
            loader: () => ref
                .read(rfiValidationRemoteDataSourceProvider)
                .previewNamedFile(
                  fileName: attachment.fileName,
                  dir: 'attachment',
                ),
          ),
        ],
      ],
    ];
  }

  Widget _inspectionPanel({
    required String title,
    required List<String> selfiePaths,
    required List<String> sitePaths,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppPalette.of(context).borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Selfie', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (selfiePaths.isEmpty)
              Text(
                RfiLogLinks.pdfBlank,
                style: TextStyle(color: AppPalette.of(context).mutedText),
              )
            else
              _ValidationImageGrid(paths: selfiePaths),
            const SizedBox(height: 12),
            const Text(
              'Site Images',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (sitePaths.isEmpty)
              Text(
                RfiLogLinks.pdfBlank,
                style: TextStyle(color: AppPalette.of(context).mutedText),
              )
            else
              _ValidationImageGrid(paths: sitePaths),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _banner(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: const Color(0xFF6B7280),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _hTable(List<String> headers, List<List<String>> rows) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return SizedBox(
          width: width,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: const WidgetStatePropertyAll<Color>(
                Color(0xFF4B5563),
              ),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              columns: <DataColumn>[
                for (final String header in headers)
                  DataColumn(label: Text(header)),
              ],
              rows: <DataRow>[
                for (final List<String> row in rows)
                  DataRow(
                    cells: <DataCell>[
                      for (final String cell in row)
                        DataCell(
                          SizedBox(
                            width: cell.length > 40 ? 220 : null,
                            child: Text(cell),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ValidationImageGrid extends ConsumerWidget {
  const _ValidationImageGrid({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        for (int i = 0; i < paths.length; i++)
          _ValidationImageThumb(path: paths[i], index: i + 1),
      ],
    );
  }
}

class _ValidationImageThumb extends ConsumerWidget {
  const _ValidationImageThumb({required this.path, required this.index});

  final String path;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AsyncValue<Uint8List> image = ref.watch(
      rfiValidationStoredFileProvider(path),
    );
    final Uint8List? bytes =
        image.hasValue && RfiStoredFile.looksLikeImage(image.requireValue)
        ? image.requireValue
        : null;
    const double size = 96;
    final Widget content = image.isLoading
        ? const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : bytes != null
        ? Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          )
        : Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: scheme.onSurfaceVariant,
            ),
          );
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: bytes == null
          ? () => ref.invalidate(rfiValidationStoredFileProvider(path))
          : () => _open(context, bytes),
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: content,
      ),
    );
  }

  Future<void> _open(BuildContext context, Uint8List bytes) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Center(child: Image.memory(bytes)),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    tooltip: 'Close',
                    color: Colors.white,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmbeddedPdfCard extends StatefulWidget {
  const _EmbeddedPdfCard({required this.title, required this.loader});

  final String title;
  final Future<Uint8List> Function() loader;

  @override
  State<_EmbeddedPdfCard> createState() => _EmbeddedPdfCardState();
}

class _EmbeddedPdfCardState extends State<_EmbeddedPdfCard> {
  Uint8List? _bytes;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Uint8List bytes = await widget.loader();
      if (!mounted) {
        return;
      }
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openFull() async {
    final Uint8List? bytes = _bytes;
    if (bytes == null || !RfiStoredFile.looksLikePdf(bytes)) {
      return;
    }
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: PdfPreview(
            build: (_) async => bytes,
            pdfFileName: widget.title,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
          ),
        ),
      ),
    );
  }

  Future<void> _share() async {
    final Uint8List? bytes = _bytes;
    if (bytes == null || !RfiStoredFile.looksLikePdf(bytes)) {
      return;
    }
    final Size size = MediaQuery.sizeOf(context);
    await shareRfiLogFile(
      bytes: bytes,
      fileName: widget.title,
      sharePositionOrigin: Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 2,
        height: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _bytes == null || !RfiStoredFile.looksLikePdf(_bytes!)) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppPalette.of(context).borderSubtle),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(widget.title)),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppPalette.of(context).borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Open',
                  onPressed: _openFull,
                  icon: const Icon(Icons.open_in_full_rounded),
                ),
                IconButton(
                  tooltip: 'Share',
                  onPressed: _share,
                  icon: const Icon(Icons.share_rounded),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 360,
            child: PdfPreview(
              build: (_) async => _bytes!,
              pdfFileName: widget.title,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: false,
              allowSharing: false,
              actions: const <PdfPreviewAction>[],
            ),
          ),
        ],
      ),
    );
  }
}
