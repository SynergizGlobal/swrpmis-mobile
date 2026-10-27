import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_parse.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';

String mailActionErrorMessage(Object error) {
  if (error is DioException) {
    final String? api = mailApiMessage(error.response?.data);
    if (api != null && api.isNotEmpty) {
      return api;
    }
    return userFriendlyErrorMessage(error);
  }
  return error.toString();
}

Future<void> mailToggleStarAction(
  BuildContext context,
  WidgetRef ref,
  MailMessage message,
) async {
  try {
    await mailToggleStar(
      ref,
      mailId: message.mailId,
      starred: !message.starred,
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: 'Star',
      message: mailActionErrorMessage(error),
    );
  }
}

Future<void> mailTrashAction(
  BuildContext context,
  WidgetRef ref,
  MailMessage message, {
  String title = 'Move to trash',
}) async {
  final bool confirmed = await AppDialog.confirm(
    context,
    title: title,
    message: 'Move this mail to trash?',
    primaryLabel: 'Move',
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  try {
    final String result = await mailTrashMessage(
      ref,
      mailId: message.mailId,
    );
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.success,
      title: title,
      message: result,
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: title,
      message: mailActionErrorMessage(error),
    );
  }
}

Future<void> mailRestoreAction(
  BuildContext context,
  WidgetRef ref,
  MailMessage message, {
  String title = 'Restore',
}) async {
  try {
    final String result = await mailRestoreMessage(
      ref,
      mailId: message.mailId,
    );
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.success,
      title: title,
      message: result,
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: title,
      message: mailActionErrorMessage(error),
    );
  }
}

Future<void> mailPermanentDeleteAction(
  BuildContext context,
  WidgetRef ref,
  MailMessage message, {
  String title = 'Delete Permanently',
}) async {
  final bool confirmed = await AppDialog.confirm(
    context,
    title: title,
    message: 'Permanently delete this mail? This cannot be undone.',
    primaryLabel: 'Delete',
    destructive: true,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  try {
    final String result = await mailPermanentDeleteMessage(
      ref,
      mailId: message.mailId,
    );
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.success,
      title: title,
      message: result,
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: title,
      message: mailActionErrorMessage(error),
    );
  }
}

Future<void> mailRestoreAllAction(
  BuildContext context,
  WidgetRef ref,
  List<MailMessage> messages, {
  String title = 'Restore All',
}) async {
  if (messages.isEmpty) {
    return;
  }
  final bool confirmed = await AppDialog.confirm(
    context,
    title: title,
    message: 'Restore all ${messages.length} items from trash?',
    primaryLabel: 'Restore All',
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  int restored = 0;
  String? lastError;
  for (final MailMessage message in messages) {
    try {
      await mailRestoreMessage(ref, mailId: message.mailId);
      restored += 1;
    } catch (error) {
      lastError = mailActionErrorMessage(error);
    }
  }
  if (!context.mounted) {
    return;
  }
  if (lastError != null && restored == 0) {
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: title,
      message: lastError,
    );
    return;
  }
  await AppDialog.show(
    context,
    variant: AppDialogVariant.success,
    title: title,
    message: lastError == null
        ? 'Mail restored successfully'
        : 'Restored $restored of ${messages.length}. Last error: $lastError',
  );
}
