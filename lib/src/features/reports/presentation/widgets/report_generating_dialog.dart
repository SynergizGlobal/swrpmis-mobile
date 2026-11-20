import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';

/// Tracks whether a busy dialog is actually on screen so [hide] never pops
/// the underlying report page by mistake.
class ReportBusyDialogSession {
  ReportBusyDialogSession();

  BuildContext? _dialogContext;
  bool _open = false;

  bool get isOpen => _open;

  void show(
    BuildContext hostContext, {
    required String title,
    required String message,
    bool warnDoNotClose = false,
  }) {
    if (_open) {
      return;
    }
    _open = true;
    showDialog<void>(
      context: hostContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        _dialogContext = dialogContext;
        return PopScope(
          canPop: false,
          child: ReportBusyDialog(
            title: title,
            message: message,
            warnDoNotClose: warnDoNotClose,
          ),
        );
      },
    ).whenComplete(() {
      _open = false;
      _dialogContext = null;
    });
  }

  void hide() {
    if (!_open) {
      return;
    }
    final BuildContext? dialogContext = _dialogContext;
    _open = false;
    _dialogContext = null;
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
  }
}

/// Per-host session so filter-load sync never pops the report route.
final Map<int, ReportBusyDialogSession> _sessions =
    <int, ReportBusyDialogSession>{};

ReportBusyDialogSession _sessionFor(BuildContext context) {
  final int key = identityHashCode(context);
  return _sessions.putIfAbsent(key, ReportBusyDialogSession.new);
}

/// Blocking modal for report filter loads and file generation.
Future<T> runWithReportBusyDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required Future<T> Function() action,
  bool warnDoNotClose = true,
}) async {
  final ReportBusyDialogSession session = ReportBusyDialogSession();
  session.show(
    context,
    title: title,
    message: message,
    warnDoNotClose: warnDoNotClose,
  );
  // Let the dialog route push before awaiting a fast network call.
  await Future<void>.delayed(Duration.zero);
  try {
    return await action();
  } finally {
    session.hide();
  }
}

/// Alias kept for generate-report call sites.
Future<T> runWithReportGeneratingDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required Future<T> Function() action,
}) {
  return runWithReportBusyDialog(
    context: context,
    title: title,
    message: message,
    action: action,
  );
}

void showReportBusyDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool warnDoNotClose = false,
}) {
  _sessionFor(context).show(
    context,
    title: title,
    message: message,
    warnDoNotClose: warnDoNotClose,
  );
}

void hideReportBusyDialog(BuildContext context) {
  final int key = identityHashCode(context);
  final ReportBusyDialogSession? session = _sessions[key];
  session?.hide();
}

/// Keeps a state-driven busy dialog in sync (e.g. filter API loads).
void syncReportBusyDialog({
  required BuildContext context,
  required bool busy,
  required bool wasBusy,
  required String title,
  required String message,
}) {
  final ReportBusyDialogSession session = _sessionFor(context);
  if (!wasBusy && busy) {
    session.show(context, title: title, message: message);
  } else if (wasBusy && !busy) {
    session.hide();
  }
}

class ReportBusyDialog extends StatelessWidget {
  const ReportBusyDialog({
    super.key,
    required this.title,
    required this.message,
    this.warnDoNotClose = true,
  });

  final String title;
  final String message;
  final bool warnDoNotClose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.mutedText),
            ),
            if (warnDoNotClose) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'Do not close this page.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Back-compat typedef used by older call sites / imports.
typedef ReportGeneratingDialog = ReportBusyDialog;
