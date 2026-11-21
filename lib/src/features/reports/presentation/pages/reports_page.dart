import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_fullscreen_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/contract_detail_report_file.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/activities_export_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/contractors_list_report_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/issues_summary_report_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/activities_export_option.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/bg_contractual_letters.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/bg_insurance_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_completion_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/doc_contractual_letters.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/insurance_contractual_letters.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/issue_details_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/issues_summary_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/land_acquisition_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/list_of_contractors_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/list_of_contracts_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/pending_issues_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/quality_control_summary_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/reports_tree.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/rfi_summary_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/station_improvements_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/tpc_status_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/utility_shifting_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/activities_export_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/bg_contractual_letters_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/bg_insurance_report_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/contract_completion_report_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/contract_detail_report_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/doc_contractual_letters_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/insurance_contractual_letters_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/issue_details_report_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/land_acquisition_report_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/list_of_contracts_report_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/pending_issues_report_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/quality_control_summary_report_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/report_placeholder_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/rfi_summary_report_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/utility_shifting_report_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/providers/reports_providers.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/widgets/report_generating_dialog.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  static const String routeName = 'reports';
  static const String routePath = '/reports';

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String? _expandedId;
  final Set<String> _expandedChildIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ReportsTree> tree = ref.watch(reportsTreeProvider);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(reportsTreeProvider);
            await ref.read(reportsTreeProvider.future);
          },
          child: tree.when(
            loading: () => const _FillScroll(
              minHeight: 240,
              child: AppFullscreenLoader(),
            ),
            error: (Object error, StackTrace stackTrace) {
              return _FillScroll(
                minHeight: minHeight,
                child: _StatusMessage(
                  message: error is DioException
                      ? userFriendlyErrorMessage(error)
                      : error.toString(),
                  onRetry: () => ref.invalidate(reportsTreeProvider),
                ),
              );
            },
            data: (ReportsTree data) {
              if (data.isEmpty) {
                return _FillScroll(
                  minHeight: minHeight,
                  child: _StatusMessage(
                    message: 'No reports found.',
                    onRetry: () => ref.invalidate(reportsTreeProvider),
                  ),
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount: data.forms.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final ReportFormNode node = data.forms[index];
                  if (!node.isExpandable) {
                    return _LeafCard(
                      node: node,
                      onTap: () => _open(context, node),
                    );
                  }
                  return _SectionCard(
                    node: node,
                    expanded: _expandedId == node.formId,
                    expandedChildIds: _expandedChildIds,
                    onToggle: () {
                      setState(() {
                        _expandedId = _expandedId == node.formId
                            ? null
                            : node.formId;
                      });
                    },
                    onToggleChild: (ReportFormNode child) {
                      final String key = '${node.formId}/${child.formId}';
                      setState(() {
                        if (!_expandedChildIds.add(key)) {
                          _expandedChildIds.remove(key);
                        }
                      });
                    },
                    onOpen: (ReportFormNode leaf) => _open(context, leaf),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _open(BuildContext context, ReportFormNode node) async {
    // Progress Report direct downloads before Activities Export (shared API prefix).
    if (isTpcStatusReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      final ActivitiesExportRemoteDataSource source = ref.read(
        activitiesExportRemoteDataSourceProvider,
      );
      await _confirmAndDownloadReport(
        context,
        label: node.formName.trim().isEmpty
            ? 'TPC Status Report'
            : node.formName.trim(),
        download: source.downloadTpcStatusReport,
      );
      return;
    }
    if (isStationImprovementsReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      final ActivitiesExportRemoteDataSource source = ref.read(
        activitiesExportRemoteDataSourceProvider,
      );
      await _confirmAndDownloadReport(
        context,
        label: node.formName.trim().isEmpty
            ? 'Station Improvement Progress Report'
            : node.formName.trim(),
        download: source.downloadStationImprovementsReport,
      );
      return;
    }
    if (isActivitiesExportReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        ActivitiesExportPage.routeName,
        queryParameters: <String, String>{'name': node.formName},
      );
      return;
    }
    if (isContractDetailReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        ContractDetailReportPage.routeName,
        queryParameters: <String, String>{'name': 'Contract Detail Report'},
      );
      return;
    }
    // Before List of Contracts — contractorslist is confirm→download only.
    if (isListOfContractorsReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      final ContractorsListReportRemoteDataSource source = ref.read(
        contractorsListReportRemoteDataSourceProvider,
      );
      await _confirmAndDownloadReport(
        context,
        label: node.formName.trim().isEmpty
            ? 'List of Contractors'
            : node.formName.trim(),
        download: source.download,
      );
      return;
    }
    if (isListOfContractsReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        ListOfContractsReportPage.routeName,
        queryParameters: <String, String>{'name': 'List of Contracts Report'},
      );
      return;
    }
    if (isBgInsuranceReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        BgInsuranceReportPage.routeName,
        queryParameters: <String, String>{'name': 'BG/Insurance Report'},
      );
      return;
    }
    if (isContractCompletionReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        ContractCompletionReportPage.routeName,
        queryParameters: <String, String>{
          'name': 'Contract Completion Report',
        },
      );
      return;
    }
    if (isBgContractualLettersReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        BgContractualLettersPage.routeName,
        queryParameters: <String, String>{
          'name': 'List of Contracts Closer to BG Expiry Date',
        },
      );
      return;
    }
    if (isInsuranceContractualLettersReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        InsuranceContractualLettersPage.routeName,
        queryParameters: <String, String>{
          'name': 'List of Contracts Closer to Insurance Expiry Date',
        },
      );
      return;
    }
    if (isDocContractualLettersReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        DocContractualLettersPage.routeName,
        queryParameters: <String, String>{
          'name': 'List of Contracts Closer to DOC Expiry Date',
        },
      );
      return;
    }
    if (isQualityControlSummaryReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        QualityControlSummaryReportPage.routeName,
        queryParameters: <String, String>{
          'name': 'Quality Control Summary Tests Report',
        },
      );
      return;
    }
    if (isRfiSummaryReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        RfiSummaryReportPage.routeName,
        queryParameters: <String, String>{
          'name': node.formName.trim().isEmpty
              ? 'RFI Summary Report'
              : node.formName.trim(),
        },
      );
      return;
    }
    // Issues → Pending Issues Report: HOD + Contract filter page.
    if (isPendingIssuesReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        PendingIssuesReportPage.routeName,
        queryParameters: <String, String>{
          'name': node.formName.trim().isEmpty
              ? 'Pending Issues Report'
              : node.formName.trim(),
        },
      );
      return;
    }
    // Issues → Issue Details Report: six-filter page (hod_user_id_fk = user id).
    if (isIssueDetailsReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        IssueDetailsReportPage.routeName,
        queryParameters: const <String, String>{
          // UI title matches web: "Issues Details Report".
          'name': 'Issues Details Report',
        },
      );
      return;
    }
    // Issues → Issues Summary Report: confirm → GET download (not a filter page).
    if (isIssuesSummaryReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      final IssuesSummaryReportRemoteDataSource source = ref.read(
        issuesSummaryReportRemoteDataSourceProvider,
      );
      await _confirmAndDownloadReport(
        context,
        label: node.formName.trim().isEmpty
            ? 'Issues Summary Report'
            : node.formName.trim(),
        download: source.download,
      );
      return;
    }
    // Land Acquisition Report: Project + Type Of Land + Sub Category filter page.
    if (isLandAcquisitionReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        LandAcquisitionReportPage.routeName,
        queryParameters: const <String, String>{
          'name': 'Land Acquisition Report',
        },
      );
      return;
    }
    // Utility → Utility Shifting Report: Project + Agency + Contract + HOD.
    if (isUtilityShiftingReport(
      formId: node.formId,
      formName: node.formName,
      webFormUrl: node.webFormUrl,
    )) {
      context.pushNamed(
        UtilityShiftingReportPage.routeName,
        queryParameters: const <String, String>{
          'name': 'Utility Shifting Report',
        },
      );
      return;
    }
    context.pushNamed(
      ReportPlaceholderPage.routeName,
      pathParameters: <String, String>{
        'formId': node.formId.isEmpty ? 'report' : node.formId,
      },
      queryParameters: <String, String>{
        'name': node.formName,
        'url': node.webFormUrl,
      },
    );
  }

  Future<void> _confirmAndDownloadReport(
    BuildContext context, {
    required String label,
    required Future<({Uint8List bytes, String fileName})> Function() download,
  }) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Download report',
      message: 'Download "$label" report now?',
      primaryLabel: 'Download',
      secondaryLabel: 'Cancel',
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      final ({Uint8List bytes, String fileName}) file =
          await runWithReportGeneratingDialog(
            context: context,
            title: 'Downloading report',
            message: 'Please wait while the file is being prepared.',
            action: download,
          );
      if (!context.mounted) {
        return;
      }
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final Rect? origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      await shareContractDetailReportFile(
        bytes: file.bytes,
        fileName: file.fileName,
        sharePositionOrigin: origin,
      );
      if (!context.mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Report ready',
        message: '"$label" downloaded successfully.',
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Download failed',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
      );
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.node,
    required this.expanded,
    required this.expandedChildIds,
    required this.onToggle,
    required this.onToggleChild,
    required this.onOpen,
  });

  final ReportFormNode node;
  final bool expanded;
  final Set<String> expandedChildIds;
  final VoidCallback onToggle;
  final ValueChanged<ReportFormNode> onToggleChild;
  final ValueChanged<ReportFormNode> onOpen;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: palette.cardSurface,
      elevation: 0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: <Widget>[
                      _IconBadge(icon: _iconForReport(node.formName)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          node.formName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                        ),
                      ),
                      Text(
                        '${node.children.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: palette.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: palette.mutedText,
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded) ...<Widget>[
                const SizedBox(height: 6),
                _ChildrenPanel(
                  children: <Widget>[
                    for (int i = 0; i < node.children.length; i++) ...<Widget>[
                      if (i > 0) const _ChildDivider(),
                      Builder(
                        builder: (BuildContext context) {
                          final ReportFormNode child = node.children[i];
                          if (child.isExpandable) {
                            return _NestedSection(
                              node: child,
                              expanded: expandedChildIds.contains(
                                '${node.formId}/${child.formId}',
                              ),
                              onToggle: () => onToggleChild(child),
                              onOpen: onOpen,
                              openParent: isContractDetailReport(
                                formId: child.formId,
                                formName: child.formName,
                                webFormUrl: child.webFormUrl,
                              ),
                            );
                          }
                          return _ChildRow(
                            node: child,
                            index: i,
                            onTap: () => onOpen(child),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NestedSection extends StatelessWidget {
  const _NestedSection({
    required this.node,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
    this.openParent = false,
  });

  final ReportFormNode node;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<ReportFormNode> onOpen;
  final bool openParent;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: palette.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  Icon(
                    _iconForReport(node.formName),
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: openParent ? () => onOpen(node) : onToggle,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          node.formName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                        ),
                      ),
                    ),
                  ),
                  if (openParent)
                    IconButton(
                      tooltip: 'Open report',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onOpen(node),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    ),
                  Text(
                    '${node.children.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: palette.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    tooltip: expanded ? 'Collapse' : 'Expand',
                    visualDensity: VisualDensity.compact,
                    onPressed: onToggle,
                    icon: Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: palette.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (expanded) ...<Widget>[
              const SizedBox(height: 6),
              _ChildrenPanel(
                children: <Widget>[
                  for (int i = 0; i < node.children.length; i++) ...<Widget>[
                    if (i > 0) const _ChildDivider(),
                    _ChildRow(
                      node: node.children[i],
                      index: i,
                      onTap: () => onOpen(node.children[i]),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeafCard extends StatelessWidget {
  const _LeafCard({required this.node, required this.onTap});

  final ReportFormNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = _accentFor(node.formName, colors);
    return Material(
      color: palette.cardSurface,
      elevation: 0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: accent.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Row(
            children: <Widget>[
              _IconBadge(icon: _iconForReport(node.formName), accent: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  node.formName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildrenPanel extends StatelessWidget {
  const _ChildrenPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _ChildDivider extends StatelessWidget {
  const _ChildDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 44,
      endIndent: 8,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({
    required this.node,
    required this.index,
    required this.onTap,
  });

  final ReportFormNode node;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = _accentFor(node.formName, colors, index: index);
    final String label = node.formName.isEmpty ? node.formId : node.formName;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 6, 10),
          child: Row(
            children: <Widget>[
              _IconBadge(
                icon: _iconForReport(label),
                accent: accent,
                size: 34,
                iconSize: 18,
                radius: 10,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accent.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    this.accent,
    this.size = 40,
    this.iconSize = 22,
    this.radius = 12,
  });

  final IconData icon;
  final Color? accent;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Color tone = accent ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: tone, size: iconSize),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _FillScroll extends StatelessWidget {
  const _FillScroll({required this.child, required this.minHeight});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : minHeight;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: math.max(height, minHeight), child: child),
        );
      },
    );
  }
}

IconData _iconForReport(String name) {
  final String normalized = name.toLowerCase();
  if (normalized.contains('contract')) {
    return Icons.request_quote_rounded;
  }
  if (normalized.contains('activit')) {
    return Icons.table_chart_rounded;
  }
  if (normalized.contains('progress')) {
    return Icons.insights_rounded;
  }
  if (normalized.contains('fob')) {
    return Icons.show_chart_rounded;
  }
  if (normalized.contains('new line') || normalized.contains('network')) {
    return Icons.account_tree_outlined;
  }
  if (normalized.contains('issue')) {
    return Icons.assignment_late_rounded;
  }
  if (normalized.contains('land')) {
    return Icons.handshake_rounded;
  }
  if (normalized.contains('util')) {
    return Icons.electrical_services_rounded;
  }
  if (normalized.contains('letter')) {
    return Icons.mail_outline_rounded;
  }
  if (normalized.contains('quality')) {
    return Icons.verified_outlined;
  }
  return Icons.description_outlined;
}

Color _accentFor(String name, ColorScheme colors, {int index = 0}) {
  const List<double> hues = <double>[210, 160, 28, 280, 190, 340];
  final int seed = name.trim().isEmpty
      ? index
      : name.toLowerCase().codeUnits.fold<int>(0, (int a, int b) => a + b);
  final double hue = hues[(seed + index) % hues.length];
  return HSLColor.fromAHSL(
    1,
    hue,
    colors.brightness == Brightness.dark ? 0.42 : 0.48,
    colors.brightness == Brightness.dark ? 0.72 : 0.42,
  ).toColor();
}
