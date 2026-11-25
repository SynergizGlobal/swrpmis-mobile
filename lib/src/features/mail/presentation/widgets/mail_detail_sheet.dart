import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_thread_page.dart';

/// Opens the shared thread preview page for a list message.
///
/// Prefer [openMailThreadPage] directly when you need [markAsRead] or local
/// compose preview. This helper keeps older call sites working.
Future<void> showMailDetailSheet(
  BuildContext context,
  MailMessage message, {
  bool markAsRead = false,
}) {
  return openMailThreadPage(
    context,
    message: message,
    markAsRead: markAsRead,
  );
}
