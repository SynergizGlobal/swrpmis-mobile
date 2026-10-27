import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_dashboard.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _formatDate(String raw) {
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw.isEmpty ? '—' : raw;
    }
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<MailDashboardData> async = ref.watch(mailDashboardProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
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
              row.subject.toLowerCase().contains(q);
        }).toList(growable: false);
        final TablePage<MailCorrespondenceRow> page =
            TablePage.slice<MailCorrespondenceRow>(
              filtered,
              page: _page,
              pageSize: _pageSize,
            );
        final MailDashboardSummary s = data.summary;
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(mailDashboardProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
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
              const SizedBox(height: 20),
              Text(
                'Mail Correspondence Register',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: MailTheme.heading(context),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _search,
                decoration: mailSearchDecoration(
                  context: context,
                  hint: 'Search by mail no., reference no., contractor...',
                ),
                onChanged: (_) => setState(() {
                  _page = 1;
                }),
              ),
              const SizedBox(height: 12),
              if (page.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No correspondence found',
                      style: MailTheme.mutedStyle(context),
                    ),
                  ),
                )
              else
                ...page.items.map((MailCorrespondenceRow row) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            row.mailNo.isEmpty ? row.reference : row.mailNo,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: MailTheme.pillForeground(context),
                            ),
                          ),
                          if (row.subject.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(row.subject),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            '${row.contract.isEmpty ? '—' : row.contract} · ${row.contractor.isEmpty ? '—' : row.contractor}',
                            style: MailTheme.mutedStyle(context, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(row.date)} · Reply: ${row.replyRequired.isEmpty ? '—' : row.replyRequired} · ${row.person.isEmpty ? '—' : row.person}',
                            style: MailTheme.mutedStyle(context, fontSize: 12),
                          ),
                          if (row.status.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 6),
                            Text(
                              row.status,
                              style: MailTheme.mutedStyle(
                                context,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              if (filtered.isNotEmpty)
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
    final double cardWidth = width >= 900
        ? 150
        : (width - 42) / 2;
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
