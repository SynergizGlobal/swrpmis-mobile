import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/providers/mail_providers.dart';

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
  } on DioException catch (error) {
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: 'Star',
      message: userFriendlyErrorMessage(error),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: 'Star',
      message: error.toString(),
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
  } on DioException catch (error) {
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: title,
      message: userFriendlyErrorMessage(error),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: title,
      message: error.toString(),
    );
  }
}
