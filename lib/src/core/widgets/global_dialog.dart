import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';

class GlobalDialog {
  const GlobalDialog._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get _context => navigatorKey.currentContext;

  static Future<void> show({
    required String message,
    String? title,
    AppDialogType type = AppDialogType.info,
    List<AppDialogAction>? actions,
    IconData? leadingIcon,
    bool barrierDismissible = true,
  }) async {
    final BuildContext? context = _context;
    if (context == null || !context.mounted) {
      return;
    }
    await AppDialog.show(
      context: context,
      message: message,
      title: title,
      type: type,
      actions: actions,
      leadingIcon: leadingIcon,
      barrierDismissible: barrierDismissible,
    );
  }

  static Future<void> info(String message, {String? title, IconData? icon}) {
    return show(
      message: message,
      title: title ?? 'Information',
      type: AppDialogType.info,
      leadingIcon: icon,
    );
  }

  static Future<void> success(String message, {String? title, IconData? icon}) {
    return show(
      message: message,
      title: title ?? 'Success',
      type: AppDialogType.success,
      leadingIcon: icon,
    );
  }

  static Future<void> error(String message, {String? title, IconData? icon}) {
    return show(
      message: message,
      title: title ?? 'Error',
      type: AppDialogType.error,
      leadingIcon: icon,
    );
  }

  static Future<bool> confirm({
    required String message,
    String? title,
    String confirmLabel = 'OK',
    String cancelLabel = 'Cancel',
  }) async {
    bool confirmed = false;
    await show(
      message: message,
      title: title ?? 'Confirm',
      type: AppDialogType.confirmation,
      barrierDismissible: false,
      actions: <AppDialogAction>[
        AppDialogAction(label: cancelLabel),
        AppDialogAction(
          label: confirmLabel,
          isPrimary: true,
          onPressed: () => confirmed = true,
        ),
      ],
    );
    return confirmed;
  }
}
