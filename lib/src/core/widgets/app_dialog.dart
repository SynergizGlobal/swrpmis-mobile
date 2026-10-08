import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';

enum AppDialogVariant { info, success, warning, error, confirm }

class AppDialog {
  const AppDialog._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String secondaryLabel = 'Cancel';

  static IconData iconFor(
    AppDialogVariant variant, {
    bool destructive = false,
  }) {
    if (variant == AppDialogVariant.confirm && destructive) {
      return Icons.warning_amber_rounded;
    }
    return switch (variant) {
      AppDialogVariant.info => Icons.info_outline_rounded,
      AppDialogVariant.success => Icons.check_circle_outline_rounded,
      AppDialogVariant.warning => Icons.warning_amber_rounded,
      AppDialogVariant.error => Icons.error_outline_rounded,
      AppDialogVariant.confirm => Icons.help_outline_rounded,
    };
  }

  static String primaryLabelFor(AppDialogVariant variant) {
    return variant == AppDialogVariant.confirm ? 'Confirm' : 'OK';
  }

  static bool barrierDismissibleFor(AppDialogVariant variant) {
    return variant != AppDialogVariant.confirm;
  }

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    AppDialogVariant variant = AppDialogVariant.info,
    IconData? icon,
    String? primaryLabel,
    String? secondaryLabel,
    bool destructive = false,
    bool? barrierDismissible,
    VoidCallback? onPrimary,
    VoidCallback? onSecondary,
  }) async {
    if (!context.mounted) {
      return null;
    }
    final bool dismissible =
        barrierDismissible ?? barrierDismissibleFor(variant);
    final bool? result = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: dismissible,
      builder: (BuildContext dialogContext) {
        return _AppDialogBody(
          title: title,
          message: message,
          variant: variant,
          icon: icon ?? iconFor(variant, destructive: destructive),
          primaryLabel: primaryLabel ?? primaryLabelFor(variant),
          secondaryLabel: secondaryLabel ?? AppDialog.secondaryLabel,
          destructive: destructive,
          dismissible: dismissible,
        );
      },
    );
    if (result == true) {
      onPrimary?.call();
    } else if (result == false) {
      onSecondary?.call();
    }
    return result;
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    IconData? icon,
    String? primaryLabel,
    String? secondaryLabel,
    bool destructive = false,
    bool barrierDismissible = false,
    VoidCallback? onPrimary,
    VoidCallback? onSecondary,
  }) async {
    final bool? result = await show(
      context,
      title: title,
      message: message,
      variant: AppDialogVariant.confirm,
      icon: icon,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      destructive: destructive,
      barrierDismissible: barrierDismissible,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
    );
    return result ?? false;
  }
}

class _AppDialogBody extends StatelessWidget {
  const _AppDialogBody({
    required this.title,
    required this.message,
    required this.variant,
    required this.icon,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.destructive,
    required this.dismissible,
  });

  final String title;
  final String message;
  final AppDialogVariant variant;
  final IconData icon;
  final String primaryLabel;
  final String secondaryLabel;
  final bool destructive;
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool dark = scheme.brightness == Brightness.dark;
    final AppPalette palette = AppPalette.of(context);
    final Color accent = _accent(dark, palette);
    final Color surface = dark
        ? const Color(0xFF122844)
        : AppTheme.surfaceLight;
    final Color onSurface = scheme.onSurface;
    final Color buttonFill = destructive
        ? AppTheme.railwayRed
        : (dark ? AppTheme.brandSecondary : AppTheme.brandPrimary);

    return PopScope(
      canPop: dismissible,
      child: Dialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: dark ? 0 : 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: dark ? 0.22 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(icon, color: accent, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: SingleChildScrollView(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.mutedText,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (variant == AppDialogVariant.confirm)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: onSurface,
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(secondaryLabel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _primaryButton(context, buttonFill)),
                    ],
                  )
                else
                  _primaryButton(context, buttonFill),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton(BuildContext context, Color buttonFill) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        backgroundColor: buttonFill,
        foregroundColor: Colors.white,
      ),
      onPressed: () => Navigator.of(context).pop(true),
      child: Text(primaryLabel),
    );
  }

  Color _accent(bool dark, AppPalette palette) {
    return switch (variant) {
      AppDialogVariant.info =>
        dark ? const Color(0xFF9DC0F0) : AppTheme.brandPrimary,
      AppDialogVariant.success => palette.success,
      AppDialogVariant.warning =>
        dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
      AppDialogVariant.error =>
        dark ? const Color(0xFFFF8A93) : AppTheme.railwayRed,
      AppDialogVariant.confirm =>
        destructive
            ? (dark ? const Color(0xFFFF8A93) : AppTheme.railwayRed)
            : (dark ? const Color(0xFF9DC0F0) : AppTheme.brandPrimary),
    };
  }
}
