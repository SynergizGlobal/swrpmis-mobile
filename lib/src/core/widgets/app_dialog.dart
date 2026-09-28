import 'package:flutter/material.dart';

enum AppDialogType { error, info, success, confirmation }

class AppDialogAction {
  const AppDialogAction({
    required this.label,
    this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
}

class AppDialog {
  const AppDialog._();

  static Future<void> show({
    required BuildContext context,
    required String message,
    String? title,
    AppDialogType type = AppDialogType.info,
    List<AppDialogAction>? actions,
    IconData? leadingIcon,
    bool barrierDismissible = true,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final String trimmedTitle = title?.trim() ?? '';
    final bool showTitle = trimmedTitle.isNotEmpty;

    final (IconData defaultIcon, Color accentColor) = switch (type) {
      AppDialogType.error => (Icons.error_outline_rounded, colorScheme.error),
      AppDialogType.success => (
          Icons.check_circle_rounded,
          theme.brightness == Brightness.dark
              ? const Color(0xFF66BB6A)
              : const Color(0xFF2E7D32),
        ),
      AppDialogType.info => (Icons.info_outline_rounded, colorScheme.primary),
      AppDialogType.confirmation => (
          Icons.help_outline_rounded,
          colorScheme.primary,
        ),
    };

    final List<AppDialogAction> dialogActions =
        actions ?? _defaultActions(type);

    return showDialog<void>(
      context: context,
      barrierDismissible:
          barrierDismissible && type != AppDialogType.confirmation,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Icon(
                      leadingIcon ?? defaultIcon,
                      color: accentColor,
                      size: 32,
                    ),
                  ),
                  if (showTitle) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      trimmedTitle,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: showTitle ? 10 : 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: SingleChildScrollView(
                      child: Text(
                        message,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: List<Widget>.generate(dialogActions.length, (
                      int index,
                    ) {
                      final AppDialogAction action = dialogActions[index];
                      void handleTap() {
                        Navigator.of(dialogContext).pop();
                        final VoidCallback? pressed = action.onPressed;
                        if (pressed != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            pressed();
                          });
                        }
                      }

                      final Widget button = action.isPrimary
                          ? FilledButton(
                              onPressed: handleTap,
                              child: Text(action.label),
                            )
                          : OutlinedButton(
                              onPressed: handleTap,
                              child: Text(action.label),
                            );
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 0 : 6,
                            right: index == dialogActions.length - 1 ? 0 : 6,
                          ),
                          child: button,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static List<AppDialogAction> _defaultActions(AppDialogType type) {
    return switch (type) {
      AppDialogType.confirmation => <AppDialogAction>[
          const AppDialogAction(label: 'Cancel'),
          const AppDialogAction(label: 'OK', isPrimary: true),
        ],
      AppDialogType.error ||
      AppDialogType.info ||
      AppDialogType.success =>
        <AppDialogAction>[const AppDialogAction(label: 'OK', isPrimary: true)],
    };
  }
}
