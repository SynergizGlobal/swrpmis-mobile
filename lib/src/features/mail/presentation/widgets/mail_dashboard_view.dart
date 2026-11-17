import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_button_lottie.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_filter_section.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_fullscreen_loader.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/mail/data/mail_dashboard_export_file.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_dashboard.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_correspondence_detail_sheet.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_correspondence_table.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_ui_helpers.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_clear_button.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

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

  String _contractFilter = '';
  String _replyFilter = '';
  String _statusFilter = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;

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
          if (q.isNotEmpty) {
            final bool matchesSearch =
                row.mailNo.toLowerCase().contains(q) ||
                row.reference.toLowerCase().contains(q) ||
                row.contractor.toLowerCase().contains(q) ||
                row.contract.toLowerCase().contains(q) ||
                row.subject.toLowerCase().contains(q) ||
                row.person.toLowerCase().contains(q);
            if (!matchesSearch) {
              return false;
            }
          }
          if (_contractFilter.isNotEmpty) {
            final String combined =
                '${row.contract} / ${row.contractor}'.trim();
            if (combined != _contractFilter) {
              return false;
            }
          }
          if (_replyFilter.isNotEmpty &&
              row.replyRequired != _replyFilter) {
            return false;
          }
          if (_statusFilter.isNotEmpty && row.status != _statusFilter) {
            return false;
          }
          if (_dateFrom != null || _dateTo != null) {
            final DateTime? rowDate = _parseRowDate(row.date);
            if (rowDate == null) {
              return false;
            }
            if (_dateFrom != null && rowDate.isBefore(_dateFrom!)) {
              return false;
            }
            if (_dateTo != null &&
                rowDate.isAfter(
                  _dateTo!.add(const Duration(days: 1)),
                )) {
              return false;
            }
          }
          return true;
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

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(mailDashboardProvider),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
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
                    _CorrespondenceFilterBar(
                      rows: data.rows,
                      contractFilter: _contractFilter,
                      replyFilter: _replyFilter,
                      statusFilter: _statusFilter,
                      dateFrom: _dateFrom,
                      dateTo: _dateTo,
                      onContractChanged: (String? v) => setState(() {
                        _contractFilter = v ?? '';
                        _page = 1;
                      }),
                      onReplyChanged: (String? v) => setState(() {
                        _replyFilter = v ?? '';
                        _page = 1;
                      }),
                      onStatusChanged: (String? v) => setState(() {
                        _statusFilter = v ?? '';
                        _page = 1;
                      }),
                      onDateFromChanged: (DateTime? d) => setState(() {
                        _dateFrom = d;
                        _page = 1;
                      }),
                      onDateToChanged: (DateTime? d) => setState(() {
                        _dateTo = d;
                        _page = 1;
                      }),
                      onClear: () => setState(() {
                        _contractFilter = '';
                        _replyFilter = '';
                        _statusFilter = '';
                        _dateFrom = null;
                        _dateTo = null;
                        _page = 1;
                      }),
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
          ),
        );
      },
    );
  }
}

DateTime? _parseRowDate(String text) {
  final String t = text.trim();
  if (t.isEmpty || t == '-') {
    return null;
  }
  try {
    return DateFormat('dd-MM-yyyy').parseStrict(t);
  } on FormatException {
    return DateTime.tryParse(t);
  }
}

class _CorrespondenceFilterBar extends StatelessWidget {
  const _CorrespondenceFilterBar({
    required this.rows,
    required this.contractFilter,
    required this.replyFilter,
    required this.statusFilter,
    required this.dateFrom,
    required this.dateTo,
    required this.onContractChanged,
    required this.onReplyChanged,
    required this.onStatusChanged,
    required this.onDateFromChanged,
    required this.onDateToChanged,
    required this.onClear,
  });

  final List<MailCorrespondenceRow> rows;
  final String contractFilter;
  final String replyFilter;
  final String statusFilter;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final ValueChanged<String?> onContractChanged;
  final ValueChanged<String?> onReplyChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<DateTime?> onDateFromChanged;
  final ValueChanged<DateTime?> onDateToChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final Set<String> contracts = <String>{};
    final Set<String> replies = <String>{};
    final Set<String> statuses = <String>{};
    for (final MailCorrespondenceRow r in rows) {
      final String c = '${r.contract} / ${r.contractor}'.trim();
      if (c.isNotEmpty && c != ' / ') {
        contracts.add(c);
      }
      if (r.replyRequired.isNotEmpty) {
        replies.add(r.replyRequired);
      }
      if (r.status.isNotEmpty) {
        statuses.add(r.status);
      }
    }
    final List<String> sortedContracts = contracts.toList()..sort();
    final List<String> sortedReplies = replies.toList()..sort();
    final List<String> sortedStatuses = statuses.toList()..sort();

    return AppFilterSection(
      activeCount: AppFilterSection.countActive(<String?>[
        contractFilter.isEmpty ? null : contractFilter,
        replyFilter.isEmpty ? null : replyFilter,
        statusFilter.isEmpty ? null : statusFilter,
        dateFrom == null ? null : 'set',
        dateTo == null ? null : 'set',
      ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RfiFilterGrid(
            children: <Widget>[
              RfiFilterField(
                label: 'Contract / Contractor',
                emptyLabel: 'All Contracts / Contractors',
                value: contractFilter.isEmpty ? null : contractFilter,
                options: <RfiFilterOption>[
                  for (final String c in sortedContracts)
                    RfiFilterOption(id: c, label: c),
                ],
                selectedId:
                    contractFilter.isEmpty ? null : contractFilter,
                onClear: contractFilter.isEmpty
                    ? null
                    : () => onContractChanged(null),
                onPick: (RfiFilterOption o) => onContractChanged(o.id),
              ),
              _DateFilterField(
                label: 'Date From',
                value: dateFrom,
                onChanged: onDateFromChanged,
              ),
              _DateFilterField(
                label: 'Date To',
                value: dateTo,
                onChanged: onDateToChanged,
              ),
              RfiFilterField(
                label: 'Reply Required',
                emptyLabel: 'All',
                value: replyFilter.isEmpty ? null : replyFilter,
                options: <RfiFilterOption>[
                  for (final String r in sortedReplies)
                    RfiFilterOption(id: r, label: r),
                ],
                selectedId: replyFilter.isEmpty ? null : replyFilter,
                onClear: replyFilter.isEmpty
                    ? null
                    : () => onReplyChanged(null),
                onPick: (RfiFilterOption o) => onReplyChanged(o.id),
              ),
              RfiFilterField(
                label: 'Status',
                emptyLabel: 'All',
                value: statusFilter.isEmpty ? null : statusFilter,
                options: <RfiFilterOption>[
                  for (final String s in sortedStatuses)
                    RfiFilterOption(id: s, label: s),
                ],
                selectedId: statusFilter.isEmpty ? null : statusFilter,
                onClear: statusFilter.isEmpty
                    ? null
                    : () => onStatusChanged(null),
                onPick: (RfiFilterOption o) => onStatusChanged(o.id),
              ),
              RfiFilterClearButton(
                label: 'Clear',
                onPressed: onClear,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final String text = value == null
        ? 'dd/mm/yyyy'
        : DateFormat('dd/MM/yyyy').format(value!);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      onTap: () async {
        final DateTime now = DateTime.now();
        final DateTime? picked = await showDatePicker(
          context: context,
          useRootNavigator: true,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 15),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) {
          onChanged(DateTime(picked.year, picked.month, picked.day));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today_rounded, size: 18)
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: value == null
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : null,
          ),
        ),
      ),
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
