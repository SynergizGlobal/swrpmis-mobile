import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_fullscreen_loader.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_parse.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_thread.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_compose_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_ui_helpers.dart';

/// Opens the shared mail thread preview page.
///
/// When [localMessages] is provided, skips the network thread fetch (compose
/// local preview). Otherwise loads `GET /api/mail/{mailId}/thread`.
/// When [markAsRead] is true, also calls `PUT /api/mail/{mailId}/read/{userId}`.
Future<void> openMailThreadPage(
  BuildContext context, {
  int? mailId,
  MailThreadHeaderMeta? meta,
  MailMessage? message,
  bool markAsRead = false,
  List<MailThreadMessage>? localMessages,
}) {
  final MailThreadHeaderMeta? header = meta ??
      (message == null ? null : MailThreadHeaderMeta.fromMessage(message));
  final int? id = mailId ?? message?.mailId;
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => MailThreadPage(
        mailId: id,
        meta: header,
        markAsRead: markAsRead,
        localMessages: localMessages,
      ),
    ),
  );
}

class MailThreadPage extends ConsumerStatefulWidget {
  const MailThreadPage({
    super.key,
    this.mailId,
    this.meta,
    this.markAsRead = false,
    this.localMessages,
  });

  final int? mailId;
  final MailThreadHeaderMeta? meta;
  final bool markAsRead;
  final List<MailThreadMessage>? localMessages;

  static const String routeName = 'mail-thread';
  static const String routePath = '/module/mail/thread';

  static String pathFor(int mailId) => '$routePath/$mailId';

  @override
  ConsumerState<MailThreadPage> createState() => _MailThreadPageState();
}

class _MailThreadPageState extends ConsumerState<MailThreadPage> {
  bool _markReadStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeMarkRead());
  }

  Future<void> _maybeMarkRead() async {
    if (_markReadStarted || !widget.markAsRead) {
      return;
    }
    final int? mailId = widget.mailId;
    if (mailId == null || mailId <= 0) {
      return;
    }
    final AuthSession? session =
        ref.read(authControllerProvider).valueOrNull;
    final String userId = session?.userId.trim() ?? '';
    if (userId.isEmpty) {
      return;
    }
    _markReadStarted = true;
    try {
      await mailMarkRead(ref, mailId: mailId, userId: userId);
    } catch (_) {
      // Thread preview should still open even if mark-read fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MailThreadMessage>? local = widget.localMessages;
    if (local != null) {
      return _ThreadScaffold(
        meta: widget.meta,
        messages: local,
        loading: false,
        error: null,
        onRetry: null,
        showActions: false,
      );
    }

    final int? mailId = widget.mailId;
    if (mailId == null || mailId <= 0) {
      return _ThreadScaffold(
        meta: widget.meta,
        messages: const <MailThreadMessage>[],
        loading: false,
        error: 'Mail id missing',
        onRetry: null,
        showActions: false,
      );
    }

    final AsyncValue<List<MailThreadMessage>> thread =
        ref.watch(mailThreadProvider(mailId));

    return thread.when(
      loading: () => _ThreadScaffold(
        meta: widget.meta,
        messages: const <MailThreadMessage>[],
        loading: true,
        error: null,
        onRetry: null,
        showActions: false,
      ),
      error: (Object error, StackTrace _) => _ThreadScaffold(
        meta: widget.meta,
        messages: const <MailThreadMessage>[],
        loading: false,
        error: error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString(),
        onRetry: () => ref.invalidate(mailThreadProvider(mailId)),
        showActions: false,
      ),
      data: (List<MailThreadMessage> messages) => _ThreadScaffold(
        meta: widget.meta,
        messages: messages,
        loading: false,
        error: null,
        onRetry: null,
        showActions: true,
        // TODO: wire dedicated reply/reply-all/forward APIs when available.
        // Compose currently has no prefilled-recipient reply mode.
        onReply: () => context.push(MailComposePage.routePath),
        onReplyAll: () => context.push(MailComposePage.routePath),
        onForward: () => context.push(MailComposePage.routePath),
      ),
    );
  }
}

class _ThreadScaffold extends StatelessWidget {
  const _ThreadScaffold({
    required this.meta,
    required this.messages,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.showActions,
    this.onReply,
    this.onReplyAll,
    this.onForward,
  });

  final MailThreadHeaderMeta? meta;
  final List<MailThreadMessage> messages;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final bool showActions;
  final VoidCallback? onReply;
  final VoidCallback? onReplyAll;
  final VoidCallback? onForward;

  @override
  Widget build(BuildContext context) {
    final String subject = meta?.displaySubject ??
        (messages.isNotEmpty ? messages.last.displaySubject : 'Mail');
    final String referenceId = meta?.referenceId.trim() ?? '';
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mail'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: loading
                ? const AppFullscreenLoader()
                : error != null
                    ? _ThreadError(message: error!, onRetry: onRetry)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: <Widget>[
                          Text(
                            subject,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: MailTheme.heading(context),
                            ),
                          ),
                          if (referenceId.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: mailReferencePill(context, referenceId),
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (meta != null) _HeaderMetaCard(meta: meta!),
                          if (messages.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 48),
                              child: Center(
                                child: Text(
                                  'No messages in this thread',
                                  style: MailTheme.mutedStyle(context),
                                ),
                              ),
                            )
                          else
                            for (int i = 0; i < messages.length; i++) ...<Widget>[
                              if (i > 0)
                                Divider(
                                  height: 28,
                                  color: MailTheme.borderSubtle(context),
                                ),
                              _ThreadMessageCard(message: messages[i]),
                            ],
                        ],
                      ),
          ),
          if (showActions && error == null && !loading)
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(color: palette.borderSubtle),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReply,
                          icon: const Icon(Icons.reply_rounded, size: 18),
                          label: const Text('Reply'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReplyAll,
                          icon: const Icon(Icons.reply_all_rounded, size: 18),
                          label: const Text('Reply All'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                          ),
                          onPressed: onForward,
                          icon: const Icon(Icons.forward_rounded, size: 18),
                          label: const Text('Forward'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThreadError extends StatelessWidget {
  const _ThreadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderMetaCard extends StatelessWidget {
  const _HeaderMetaCard({required this.meta});

  final MailThreadHeaderMeta meta;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MailTheme.referencePanelBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MailTheme.borderSubtle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Avatar(letter: meta.avatarLetter),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      meta.displaySender,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (meta.senderId.isNotEmpty)
                      Text(
                        'User ID: ${meta.senderId}',
                        style: MailTheme.mutedStyle(context, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (meta.status.trim().isNotEmpty)
                _StatusPill(label: meta.status),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (meta.referenceId.isNotEmpty)
                _MetaChip(label: 'Reference', value: meta.referenceId),
              if (meta.category.isNotEmpty)
                _MetaChip(label: 'Category', value: meta.category),
              if (meta.priority.isNotEmpty)
                _MetaChip(label: 'Priority', value: meta.priority),
              _MetaChip(
                label: 'Response Required',
                value: meta.requiredResponse ? 'Yes' : 'No',
              ),
              if (meta.targetResponseDate != null)
                _MetaChip(
                  label: 'Target Response Date',
                  value: formatMailDateShort(meta.targetResponseDate),
                ),
            ],
          ),
          if (meta.to.isNotEmpty || meta.cc.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            if (meta.to.isNotEmpty)
              _RecipientBox(
                label: 'To',
                values: meta.to,
                background: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
              ),
            if (meta.cc.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              _RecipientBox(
                label: 'CC',
                values: meta.cc,
                background: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ThreadMessageCard extends StatelessWidget {
  const _ThreadMessageCard({required this.message});

  final MailThreadMessage message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Avatar(letter: message.avatarLetter),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    message.displaySender,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (message.senderId.isNotEmpty)
                    Text(
                      'User ID: ${message.senderId}',
                      style: MailTheme.mutedStyle(context, fontSize: 12),
                    ),
                ],
              ),
            ),
            Text(
              formatMailThreadTimestamp(message.sentAt),
              style: MailTheme.mutedStyle(context, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                message.displaySubject,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            _ActionBadge(action: message.actionLabel),
          ],
        ),
        if (message.toUserIds.isNotEmpty ||
            message.ccUserIds.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          if (message.toUserIds.isNotEmpty)
            _RecipientBox(
              label: 'To',
              values: message.toUserIds,
              background: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            ),
          if (message.ccUserIds.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            _RecipientBox(
              label: 'CC',
              values: message.ccUserIds,
              background: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            ),
          ],
        ],
        const SizedBox(height: 10),
        Text(
          message.body.trim().isEmpty ? '(No message body)' : message.body,
          style: const TextStyle(height: 1.35),
        ),
        if (message.attachments.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            'Attachments',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: MailTheme.heading(context),
            ),
          ),
          const SizedBox(height: 6),
          for (final MailThreadAttachment file in message.attachments)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.insert_drive_file_outlined,
                color: MailTheme.pillForeground(context),
              ),
              title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 18,
      backgroundColor: scheme.primary.withValues(alpha: 0.15),
      foregroundColor: scheme.primary,
      child: Text(
        letter,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        action,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: palette.success,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: palette.success,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: MailTheme.borderSubtle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: MailTheme.mutedStyle(context, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RecipientBox extends StatelessWidget {
  const _RecipientBox({
    required this.label,
    required this.values,
    required this.background,
  });

  final String label;
  final List<String> values;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13),
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: values.join(', ')),
          ],
        ),
      ),
    );
  }
}
