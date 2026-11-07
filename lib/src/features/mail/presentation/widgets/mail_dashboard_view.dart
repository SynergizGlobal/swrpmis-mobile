import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_button_lottie.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_fullscreen_loader.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/mail/data/mail_dashboard_export_file.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_dashboard.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_correspondence_detail_sheet.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_correspondence_table.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_ui_helpers.dart';

class MailDashboardView extends ConsumerStatefulWidget {
  const MailDashboardView({super.key});

  @override
  ConsumerState<MailDashboardView> createState() => _MailDashboardViewState();
}

class _MailDashboardViewState extends ConsumerState<MailDashboardView> {
  final TextEditingController _search = TextEditingController();
  int _page = 1;
  int _pageSize = 10;
  bool _exporting = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Rect _shareOrigin(BuildContext origin) {
    final RenderObject? box = origin.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    return Rect.zero;
  }

  Future<void> _onExport(
    BuildContext origin,
    List<MailCorrespondenceRow> rows,
  ) async {
    if (_exporting || !mounted) {
      return;
    }
    if (rows.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: 'Export Excel',
        message: 'There are no records to export.',
      );
      return;
    }
    final Rect originRect = _shareOrigin(origin);
    setState(() => _exporting = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      await shareMailCorrespondenceXlsx(
        rows: rows,
        sharePositionOrigin: originRect,
      );
    } on Object {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Export Excel',
        message: 'Unable to export correspondence to Excel.',
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<MailDashboardData> async = ref.watch(mailDashboardProvider);
    return async.when(
      loading: () => const AppFullscreenLoader(),
      error: (Object error, StackTrace _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                error is DioException
                    ? userFriendlyErrorMessage(error)
                    : error.toString(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(mailDashboardProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (MailDashboardData data) {
        final String q = _search.text.trim().toLowerCase();
        final List<MailCorrespondenceRow> filtered = data.rows.where((
          MailCorrespondenceRow row,
        ) {
          if (q.isEmpty) {
            return true;
          }
          return row.mailNo.toLowerCase().contains(q) ||
              row.reference.toLowerCase().contains(q) ||
              row.contractor.toLowerCase().contains(q) ||
              row.contract.toLowerCase().contains(q) ||
              row.subject.toLowerCase().contains(q) ||
              row.person.toLowerCase().contains(q);
        }).toList(growable: false);
        final TablePage<MailCorrespondenceRow> page =
            TablePage.slice<MailCorrespondenceRow>(
              filtered,
              page: _page,
              pageSize: _pageSize,
            );
        if (page.page != _page) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _page != page.page) {
              setState(() => _page = page.page);
            }
          });
        }
        final MailDashboardSummary s = data.summary;
        final bool showFooter = filtered.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Mail',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: MailTheme.heading(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        _KpiCard(
                          label: 'Total Mail',
                          value: s.totalMail,
                          icon: Icons.mail_outline,
                          color: const Color(0xFF2563EB),
                        ),
                        _KpiCard(
                          label: 'Reply Required',
                          value: s.replyRequired,
                          icon: Icons.reply_outlined,
                          color: const Color(0xFFDC2626),
                        ),
                        _KpiCard(
                          label: 'Replied',
                          value: s.replied,
                          icon: Icons.mark_email_read_outlined,
                          color: const Color(0xFF16A34A),
                        ),
                        _KpiCard(
                          label: 'Pending to Reply',
                          value: s.pendingToReply,
                          icon: Icons.hourglass_empty,
                          color: const Color(0xFFEA580C),
                        ),
                        _KpiCard(
                          label: 'Pending with Others',
                          value: s.pendingWithOthers,
                          icon: Icons.groups_outlined,
                          color: const Color(0xFF2563EB),
                        ),
                        _KpiCard(
                          label: 'Overdue Mails',
                          value: s.overdueMails,
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFDC2626),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mail Correspondence Register',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: MailTheme.heading(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _search,
                            textInputAction: TextInputAction.search,
                            decoration: mailSearchDecoration(
                              context: context,
                              hint:
                                  'Search by mail no., reference no., contractor...',
                              suffix: _search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear',
                                      onPressed: () {
                                        _search.clear();
                                        setState(() => _page = 1);
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                            ),
                            onChanged: (_) => setState(() {
                              _page = 1;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _exporting
                              ? null
                              : () => _onExport(context, filtered),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(0, AppTheme.fieldHeight),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          icon: _exporting
                              ? const AppButtonLoader.navy(height: 16)
                              : const Icon(Icons.table_view_rounded, size: 18),
                          label: const Text('Export Excel'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No correspondence found',
                            style: MailTheme.mutedStyle(context),
                          ),
                        ),
                      )
                    else
                      MailCorrespondenceTable(
                        rows: page.items,
                        startSerial: page.total == 0
                            ? 1
                            : ((page.page - 1) * page.pageSize) + 1,
                        shrinkWrap: true,
                        onView: (MailCorrespondenceRow row) {
                          showMailCorrespondenceDetailSheet(context, row);
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (showFooter)
              TablePaginationFooter(
                label: page.label,
                total: page.total,
                page: page.page,
                pageCount: page.pageCount,
                pageSize: page.pageSize,
                onPageChanged: (int value) => setState(() => _page = value),
                onPageSizeChanged: (int value) {
                  setState(() {
                    _pageSize = value;
                    _page = 1;
                  });
                },
              ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double cardWidth = width >= 900 ? 150 : (width - 42) / 2;
    return SizedBox(
      width: cardWidth.clamp(140, 200),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: MailTheme.mutedStyle(context, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
