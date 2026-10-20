import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';
import 'package:swr_pmis_mobile/src/core/widgets/table_pagination_footer.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_parse.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_compose_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_detail_sheet.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_message_actions.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_ui_helpers.dart';

bool mailMatchesQuery(MailMessage message, String query) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return true;
  }
  return message.displaySubject.toLowerCase().contains(q) ||
      message.body.toLowerCase().contains(q) ||
      message.displaySender.toLowerCase().contains(q) ||
      message.referenceId.toLowerCase().contains(q) ||
      message.toDisplay.toLowerCase().contains(q);
}

class MailInboxListView extends ConsumerStatefulWidget {
  const MailInboxListView({super.key});

  @override
  ConsumerState<MailInboxListView> createState() => _MailInboxListViewState();
}

class _MailInboxListViewState extends ConsumerState<MailInboxListView> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MailMessage>> inbox = ref.watch(mailInboxProvider);
    return inbox.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => _ErrorRetry(
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
        onRetry: () => ref.invalidate(mailInboxProvider),
      ),
      data: (List<MailMessage> items) {
        final List<MailMessage> filtered = items
            .where((MailMessage m) => mailMatchesQuery(m, _search.text))
            .toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                decoration: mailSearchDecoration(hint: 'Search mail...'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No mail in inbox'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        return _InboxRow(
                          message: filtered[index],
                          onOpen: () => showMailDetailSheet(context, filtered[index]),
                          onStar: () => mailToggleStarAction(
                            context,
                            ref,
                            filtered[index],
                          ),
                          onTrash: () => mailTrashAction(
                            context,
                            ref,
                            filtered[index],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({
    required this.message,
    required this.onOpen,
    required this.onStar,
    required this.onTrash,
  });

  final MailMessage message;
  final VoidCallback onOpen;
  final VoidCallback onStar;
  final VoidCallback onTrash;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: message.read
                      ? Colors.transparent
                      : MailColors.unreadDot,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          message.displaySender,
                          style: TextStyle(
                            fontWeight:
                                message.read ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                      ),
                      mailReferencePill(message.referenceId),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: <InlineSpan>[
                        TextSpan(
                          text: message.displaySubject,
                          style: TextStyle(
                            fontWeight:
                                message.read ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' — ${message.snippet}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      mailMetaPill(message.category),
                      mailMetaPill(message.priority),
                      mailMetaPill(message.status),
                      for (final String tag in message.tags)
                        mailMetaPill('#$tag'),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: <Widget>[
                IconButton(
                  tooltip: message.starred ? 'Unstar' : 'Star',
                  icon: Icon(
                    message.starred ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: message.starred ? Colors.amber : Colors.black45,
                  ),
                  onPressed: onStar,
                ),
                IconButton(
                  tooltip: 'Trash',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: onTrash,
                ),
                if (message.hasAttachments)
                  const Icon(Icons.attach_file, size: 18, color: Colors.black45),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MailDraftsListView extends ConsumerStatefulWidget {
  const MailDraftsListView({super.key});

  @override
  ConsumerState<MailDraftsListView> createState() => _MailDraftsListViewState();
}

class _MailDraftsListViewState extends ConsumerState<MailDraftsListView> {
  final TextEditingController _search = TextEditingController();
  int _page = 1;
  int _pageSize = TablePage.defaultPageSize;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MailMessage>> drafts = ref.watch(mailDraftsProvider);
    return drafts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => _ErrorRetry(
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
        onRetry: () => ref.invalidate(mailDraftsProvider),
      ),
      data: (List<MailMessage> items) {
        final List<MailMessage> filtered = items
            .where((MailMessage m) => mailMatchesQuery(m, _search.text))
            .toList(growable: false);
        final TablePage<MailMessage> page = TablePage.slice(
          filtered,
          page: _page,
          pageSize: _pageSize,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Drafts',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: MailColors.navy,
                          ),
                        ),
                        Text(
                          '${filtered.length} drafts messages',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _search,
                      decoration: mailSearchDecoration(hint: 'Search drafts...'),
                      onChanged: (_) => setState(() => _page = 1),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: <Widget>[
                  const Divider(height: 1),
                  for (final MailMessage message in page.items)
                    _DraftRow(
                      message: message,
                      onEdit: () {
                        context.push(
                          MailComposePage.draftPath(message.mailId),
                        );
                      },
                      onStar: () =>
                          mailToggleStarAction(context, ref, message),
                      onTrash: () =>
                          mailTrashAction(context, ref, message),
                    ),
                ],
              ),
            ),
            TablePaginationFooter(
              label: page.label,
              total: page.total,
              page: page.page,
              pageCount: page.pageCount,
              pageSize: page.pageSize,
              onPageChanged: (int value) => setState(() => _page = value),
              onPageSizeChanged: (int value) =>
                  setState(() {
                    _pageSize = value;
                    _page = 1;
                  }),
            ),
          ],
        );
      },
    );
  }
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({
    required this.message,
    required this.onEdit,
    required this.onStar,
    required this.onTrash,
  });

  final MailMessage message;
  final VoidCallback onEdit;
  final VoidCallback onStar;
  final VoidCallback onTrash;

  @override
  Widget build(BuildContext context) {
    final DateTime? modified = message.lastModified;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Text(
                  message.displaySubject,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(formatMailDateShort(modified)),
                    Text(
                      formatMailTime(modified),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      message.starred
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: message.starred ? Colors.amber : MailColors.navy,
                    ),
                    onPressed: onStar,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: onTrash,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class MailSentListView extends ConsumerStatefulWidget {
  const MailSentListView({super.key});

  @override
  ConsumerState<MailSentListView> createState() => _MailSentListViewState();
}

class _MailSentListViewState extends ConsumerState<MailSentListView> {
  final TextEditingController _search = TextEditingController();
  int _page = 1;
  int _pageSize = TablePage.defaultPageSize;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MailMessage>> sent = ref.watch(mailSentProvider);
    return sent.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => _ErrorRetry(
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
        onRetry: () => ref.invalidate(mailSentProvider),
      ),
      data: (List<MailMessage> items) {
        final List<MailMessage> filtered = items
            .where((MailMessage m) => mailMatchesQuery(m, _search.text))
            .toList(growable: false);
        final TablePage<MailMessage> page = TablePage.slice(
          filtered,
          page: _page,
          pageSize: _pageSize,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Sent Mail',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: MailColors.navy,
                          ),
                        ),
                        Text(
                          '${filtered.length} messages',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _search,
                      decoration: mailSearchDecoration(
                        hint: 'Search sent mails...',
                      ),
                      onChanged: (_) => setState(() => _page = 1),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: <Widget>[
                  const Divider(height: 1),
                  for (final MailMessage message in page.items)
                    _SentRow(
                      message: message,
                      onTrash: () =>
                          mailTrashAction(context, ref, message),
                    ),
                ],
              ),
            ),
            TablePaginationFooter(
              label: page.label,
              total: page.total,
              page: page.page,
              pageCount: page.pageCount,
              pageSize: page.pageSize,
              onPageChanged: (int value) => setState(() => _page = value),
              onPageSizeChanged: (int value) =>
                  setState(() {
                    _pageSize = value;
                    _page = 1;
                  }),
            ),
          ],
        );
      },
    );
  }
}

class _SentRow extends StatelessWidget {
  const _SentRow({required this.message, required this.onTrash});

  final MailMessage message;
  final VoidCallback onTrash;

  @override
  Widget build(BuildContext context) {
    final DateTime? when = message.sentAt ?? message.createdAt;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Text(message.toDisplay, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  message.displaySubject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(formatMailDateShort(when)),
                    Text(
                      formatMailTime(when),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              mailSentStatusBadge(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: onTrash,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class MailStarredListView extends ConsumerStatefulWidget {
  const MailStarredListView({super.key, this.title = 'Starred'});

  final String title;

  @override
  ConsumerState<MailStarredListView> createState() => _MailStarredListViewState();
}

class _MailStarredListViewState extends ConsumerState<MailStarredListView> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MailMessage>> starred = ref.watch(mailStarredProvider);
    return starred.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => _ErrorRetry(
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
        onRetry: () => ref.invalidate(mailStarredProvider),
      ),
      data: (List<MailMessage> items) {
        final List<MailMessage> filtered = items
            .where((MailMessage m) => mailMatchesQuery(m, _search.text))
            .toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: MailColors.navy,
                    ),
                  ),
                  Text(
                    '${filtered.length} starred threads',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    decoration: mailSearchDecoration(
                      hint: 'Search starred mails...',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No starred mail'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final MailMessage message = filtered[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                          ),
                          title: Text(
                            message.displaySender,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${message.displaySubject} — ${message.snippet}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            formatMailDateShort(message.sentAt ?? message.createdAt),
                            style: const TextStyle(color: Colors.black54),
                          ),
                          onTap: () => showMailDetailSheet(context, message),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class MailTrashListView extends ConsumerWidget {
  const MailTrashListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MailMessage>> trash = ref.watch(mailTrashProvider);
    return trash.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => _ErrorRetry(
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
        onRetry: () => ref.invalidate(mailTrashProvider),
      ),
      data: (List<MailMessage> items) {
        if (items.isEmpty) {
          return const Center(child: Text('Trash is empty'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            final MailMessage message = items[index];
            return ListTile(
              title: Text(message.displaySubject),
              subtitle: Text(message.toDisplay),
              onTap: () => showMailDetailSheet(context, message),
            );
          },
        );
      },
    );
  }
}

class MailLabelListView extends ConsumerStatefulWidget {
  const MailLabelListView({super.key, required this.labelName});

  final String labelName;

  @override
  ConsumerState<MailLabelListView> createState() => _MailLabelListViewState();
}

class _MailLabelListViewState extends ConsumerState<MailLabelListView> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<MailMessage>> mails = ref.watch(
      mailLabelMailsProvider(widget.labelName),
    );
    return mails.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => _ErrorRetry(
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
        onRetry: () =>
            ref.invalidate(mailLabelMailsProvider(widget.labelName)),
      ),
      data: (List<MailMessage> items) {
        final List<MailMessage> filtered = items
            .where((MailMessage m) => mailMatchesQuery(m, _search.text))
            .toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'LABEL',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          widget.labelName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Mails assigned to this label',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${filtered.length} mails'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                decoration: mailSearchDecoration(hint: 'Search mails...'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final MailMessage message = filtered[index];
                  return ListTile(
                    leading: const Icon(Icons.mail_outline_rounded),
                    title: Text(message.displaySender),
                    subtitle: Text(message.displaySubject),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          formatMailDate(message.sentAt ?? message.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            message.starred
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                          ),
                          onPressed: () =>
                              mailToggleStarAction(context, ref, message),
                        ),
                      ],
                    ),
                    onTap: () => showMailDetailSheet(context, message),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
