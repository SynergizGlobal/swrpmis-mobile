import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_module_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_ui_helpers.dart';

class MailNotificationsMenu extends ConsumerWidget {
  const MailNotificationsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MailMessage>> inbox = ref.watch(mailInboxProvider);
    final List<MailMessage> unread = inbox.valueOrNull
            ?.where((MailMessage m) => !m.read)
            .toList(growable: false) ??
        const <MailMessage>[];
    final int count = unread.length;

    return PopupMenuButton<void>(
      tooltip: 'Notifications',
      offset: const Offset(0, 40),
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<void>>[
          PopupMenuItem<void>(
            enabled: false,
            child: Row(
              children: <Widget>[
                const Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count unread',
                  style: MailTheme.mutedStyle(context, fontSize: 12),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () => ref.invalidate(mailInboxProvider),
                ),
              ],
            ),
          ),
          for (final MailMessage message in unread.take(4))
            PopupMenuItem<void>(
              onTap: () {
                context.go(MailModulePage.folderPath(MailFolder.inbox));
              },
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: MailTheme.pillBackground(context),
                  child: Icon(
                    Icons.mail_outline,
                    color: MailTheme.pillForeground(context),
                  ),
                ),
                title: Text(
                  message.displaySender,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      message.displaySubject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      message.snippet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MailTheme.mutedStyle(context),
                    ),
                  ],
                ),
                trailing: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: MailTheme.unreadIndicator(context),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          PopupMenuItem<void>(
            onTap: () => context.go(MailModulePage.folderPath(MailFolder.inbox)),
            child: Center(
              child: Text(
                'View all inbox',
                style: TextStyle(
                  color: MailTheme.linkAccent(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ];
      },
      child: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
