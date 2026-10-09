import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/config/app_config_provider.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_log_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/rfi_log_print.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_log_report.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_log_links.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_stored_file.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:url_launcher/url_launcher.dart';

class RfiLogPreviewDialog extends ConsumerStatefulWidget {
  const RfiLogPreviewDialog({super.key, required this.id});

  final int id;

  @override
  ConsumerState<RfiLogPreviewDialog> createState() =>
      _RfiLogPreviewDialogState();
}

class _RfiLogPreviewDialogState extends ConsumerState<RfiLogPreviewDialog> {
  RfiLogReport? _report;
  Object? _error;
  bool _loading = true;
  bool _printing = false;

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
      final RfiLogReport report = await ref
          .read(rfiLogRemoteDataSourceProvider)
          .fetchReport(widget.id);
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

  Future<void> _print() async {
    final RfiLogReport? report = _report;
    if (report == null || _printing) {
      return;
    }
    setState(() => _printing = true);
    try {
      final RfiLogRemoteDataSource source = ref.read(
        rfiLogRemoteDataSourceProvider,
      );
      final Uint8List? logo = await source.loadLogo(
        ref.read(appConfigProvider).baseUrl,
      );
      final Uint8List bytes = await buildRfiLogPdf(
        report: report,
        logoBytes: logo,
      );
      if (!mounted) {
        return;
      }
      if (!RfiStoredFile.looksLikePdf(bytes)) {
        await AppDialog.show(
          context,
          variant: AppDialogVariant.error,
          title: 'Print failed',
          message: 'Unable to open the print sheet. Please try again.',
        );
        return;
      }
      final String name = report.details.rfiId.trim().isEmpty
          ? 'RFI_Report.pdf'
          : 'RFI_Report_${report.details.rfiId}.pdf';
      await presentRfiLogPdf(bytes: bytes, fileName: name);
    } on Object {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Print failed',
        message: 'Unable to open the print sheet. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _printing = false);
      }
    }
  }

  Future<void> _openStored(String path) async {
    if (RfiStoredFile.isHttpUrl(path)) {
      final Uri? uri = Uri.tryParse(path.trim());
      if (uri == null) {
        await _fileUnavailable();
        return;
      }
      try {
        final bool opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened && mounted) {
          await _fileUnavailable();
        }
      } on Object {
        if (mounted) {
          await _fileUnavailable();
        }
      }
      return;
    }
    try {
      final Uint8List bytes = await ref
          .read(rfiLogRemoteDataSourceProvider)
          .previewFile(path);
      if (!mounted) {
        return;
      }
      if (RfiStoredFile.looksLikeImage(bytes)) {
        await showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) {
            return Dialog(
              child: InteractiveViewer(
                child: Image.memory(
                  bytes,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('This file is not available yet.'),
                  ),
                ),
              ),
            );
          },
        );
        return;
      }
      if (RfiStoredFile.looksLikePdf(bytes)) {
        await presentRfiLogPdf(
          bytes: bytes,
          fileName: RfiStoredFile.fileName(path),
        );
        return;
      }
      await _fileUnavailable();
    } on Object {
      if (mounted) {
        await _fileUnavailable();
      }
    }
  }

  Future<void> _fileUnavailable() {
    return AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: 'File unavailable',
      message: 'This file is not available yet.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
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
            RfiContentLoader(loading: _loading),
            Expanded(child: _body(context)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      OutlinedButton(
                        style: const ButtonStyle(
                          minimumSize: WidgetStatePropertyAll<Size>(
                            Size(88, 44),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: const ButtonStyle(
                          minimumSize: WidgetStatePropertyAll<Size>(
                            Size(88, 44),
                          ),
                        ),
                        onPressed: _report == null || _printing ? null : _print,
                        child: _printing
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Print'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
    final RfiLogReport? report = _report;
    if (report == null) {
      return const SizedBox.expand();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: _content(context, report),
    );
  }

  List<Widget> _content(BuildContext context, RfiLogReport report) {
    final RfiLogReportDetails details = report.details;
    return <Widget>[
      Text(
        'Request For Inspection (RFI)',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppTheme.brandPrimary,
        ),
      ),
      const SizedBox(height: 12),
      _field('Client', RfiLogLinks.clientName),
      _field(
        'RFI Status',
        rfiLogDialogText(details.statusText),
        emphasize: details.statusText.isNotEmpty,
      ),
      _field(
        'Consultant',
        rfiLogDialogText(details.consultant, empty: RfiLogLinks.dialogMissing),
      ),
      _field('RFI ID', rfiLogDialogText(details.rfiId)),
      _field('RFI Raised Date', rfiLogDialogText(details.dateOfCreation)),
      _field('Project', rfiLogDialogText(details.project)),
      _field('Contract', rfiLogDialogText(details.contract)),
      _field('Contract ID', rfiLogDialogText(details.contractId)),
      _field('Structure Type', rfiLogDialogText(details.structureType)),
      _field('Structure', rfiLogDialogText(details.structure)),
      _field('Component', rfiLogDialogText(details.component)),
      _field('Element', rfiLogDialogText(details.element)),
      _field('Activity', rfiLogDialogText(details.activity)),
      _field('RFI Description', rfiLogDialogText(details.rfiDescription)),
      _field('RFI Category', rfiLogDialogText(details.rfiCategory)),
      _field('Type of RFI', rfiLogDialogText(details.typeOfRfi)),
      _field('Enclosures', rfiLogDialogText(details.enclosures)),
      _field(
        'Contractor',
        rfiLogDialogText(details.contractor, empty: RfiLogLinks.dialogMissing),
      ),
      _field(
        "Contractor's Representative",
        rfiLogDialogText(details.contractorRepresentative),
      ),
      _field(
        'Client Representative',
        rfiLogDialogText(
          details.clientRepresentative,
          empty: RfiLogLinks.dialogMissing,
        ),
      ),
      _field(
        'Chainage',
        rfiLogDialogText(
          details.chainageText,
          empty: RfiLogLinks.dialogMissing,
        ),
      ),
      _field(
        'Proposed Inspection Date',
        rfiLogDialogText(details.proposedDateOfInspection),
      ),
      _field('Proposed Time', rfiLogDialogText(details.proposedInspectionTime)),
      _field(
        'Contractor Inspected Date',
        rfiLogDialogText(details.conInspDate),
      ),
      _field(
        'Contractor Inspection Time',
        rfiLogDialogText(details.conInspTime),
      ),
      _field(
        'Client Inspection Date',
        rfiLogDialogText(
          details.enggInspDate,
          empty: RfiLogLinks.dialogMissing,
        ),
      ),
      _field('Description', rfiLogDialogText(details.descriptionByContractor)),
      _field('Contractor Location', rfiLogDialogText(details.conLocation)),
      _field('Client Location', rfiLogDialogText(details.clientLocation)),
      _field('Inspection Test Type', rfiLogDialogText(details.typeOfTest)),
      _field(
        'Test Report Approval By Inspector',
        rfiLogDialogText(details.testStatus),
      ),
      _field('DyHod', rfiLogDialogText(details.dyHodUserName)),
      if (report.workDetails.isNotEmpty) ...<Widget>[
        const SizedBox(height: 8),
        _banner('Work Details'),
        _hTable(
          const <String>[
            'Activity Name',
            'Unit',
            'Scope',
            'Completed Till Date',
            'Inspection Quantity',
          ],
          <List<String>>[
            for (final RfiLogWorkDetail row in report.workDetails)
              <String>[
                rfiLogDialogText(row.activityName),
                rfiLogDialogText(row.unit),
                rfiLogDialogText(row.scope),
                rfiLogDialogText(row.completedTillDate),
                rfiLogDialogText(row.inspectionQuantity),
              ],
          ],
        ),
      ],
      if (report.measurement != null) ...<Widget>[
        const SizedBox(height: 12),
        _banner('Measurement Details'),
        _hTable(
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
              rfiLogDialogText(report.measurement!.measurementType),
              rfiLogDialogText(report.measurement!.units),
              rfiLogDialogText(report.measurement!.length),
              rfiLogDialogText(report.measurement!.breadth),
              rfiLogDialogText(report.measurement!.height),
              rfiLogDialogText(report.measurement!.weight),
              rfiLogDialogText(report.measurement!.count),
              rfiLogDialogText(report.measurement!.totalQty),
            ],
          ],
        ),
      ],
      if (report.checklistItems.isNotEmpty) ...<Widget>[
        const SizedBox(height: 12),
        _banner('RFI Description: ${details.rfiDescription}'),
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
            for (int index = 0; index < report.checklistItems.length; index++)
              <String>[
                '${index + 1}',
                rfiLogDialogText(
                  report.checklistItems[index].checklistDescription,
                ),
                rfiLogDialogText(report.checklistItems[index].conStatus),
                rfiLogDialogText(report.checklistItems[index].aeStatus),
                rfiLogDialogText(report.checklistItems[index].contractorRemark),
                rfiLogDialogText(report.checklistItems[index].aeRemark),
              ],
          ],
        ),
      ],
      const SizedBox(height: 12),
      _banner('Validation Status & Remarks'),
      _field('Status', rfiLogDialogText(details.validationStatus)),
      _field('Remarks', rfiLogDialogText(details.remarks)),
      _field('Comment', rfiLogDialogText(details.validationComments)),
      const SizedBox(height: 8),
      _banner('Contractor Inspection'),
      _storedLine(label: 'Contractor Selfie', path: details.selfieContractor),
      const SizedBox(height: 8),
      _banner('Client Inspection'),
      _storedLine(label: 'Inspector Selfie', path: details.selfieClient),
      const SizedBox(height: 12),
      if (!report.hasEnclosures)
        const Text('No enclosures uploaded.')
      else
        for (final String path in <String>[
          ...report.enclosurePaths,
          ...report.attachmentPaths,
        ])
          _storedLine(label: RfiStoredFile.fileName(path), path: path),
      const SizedBox(height: 16),
      const Text(
        'Test Report Uploaded By Contractor',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      if (details.testSiteDocumentsContractor.isEmpty)
        const SizedBox.shrink()
      else if (RfiStoredFile.isWindowsPath(details.testSiteDocumentsContractor))
        _storedLine(
          label: RfiStoredFile.fileName(details.testSiteDocumentsContractor),
          path: details.testSiteDocumentsContractor,
        )
      else
        _storedLine(
          label: RfiStoredFile.isHttpUrl(details.testSiteDocumentsContractor)
              ? details.testSiteDocumentsContractor
              : RfiStoredFile.fileName(details.testSiteDocumentsContractor),
          path: details.testSiteDocumentsContractor,
        ),
    ];
  }

  Widget _field(String label, String value, {bool emphasize = false}) {
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
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: emphasize ? const Color(0xFF198754) : null,
            ),
          ),
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
                AppTheme.brandPrimary,
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

  Widget _storedLine({required String label, required String path}) {
    if (path.trim().isEmpty) {
      return Text(label, style: const TextStyle(fontWeight: FontWeight.w700));
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(onPressed: () => _openStored(path), child: Text(label)),
    );
  }
}
