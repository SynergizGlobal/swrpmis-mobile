import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_parse.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_ui_helpers.dart';

Future<void> showMailDetailSheet(
  BuildContext context,
  MailMessage message,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              message.displaySubject,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: MailTheme.heading(context),
              ),
            ),
            const SizedBox(height: 8),
            if (message.referenceId.isNotEmpty)
              mailReferencePill(context, message.referenceId),
            const SizedBox(height: 12),
            Text(
              'From: ${message.displaySender}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (message.toDisplay.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text('To: ${message.toDisplay}'),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                mailMetaPill(context, message.category),
                mailMetaPill(context, message.priority),
                mailMetaPill(context, message.status),
                for (final String tag in message.tags)
                  mailMetaPill(context, '#$tag'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              formatMailDate(message.sentAt ?? message.createdAt),
              style: MailTheme.mutedStyle(context, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.body.isEmpty ? '(No message body)' : message.body,
              ),
            ),
          ],
        ),
      );
    },
  );
}
