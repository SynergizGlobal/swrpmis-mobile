import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rdso/data/datasources/rdso_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';

Future<void> showRdsoSendMailDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String fileId,
  required String fileName,
}) async {
  final TextEditingController email = TextEditingController();
  final TextEditingController message = TextEditingController();
  try {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        bool sending = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Send via mail'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      fileName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Recipient email',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: message,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Message (optional)',
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          final String recipient = email.text.trim();
                          if (recipient.isEmpty) {
                            await AppDialog.show(
                              context,
                              variant: AppDialogVariant.warning,
                              title: 'Send via mail',
                              message: 'Enter a recipient email address.',
                            );
                            return;
                          }
                          setState(() => sending = true);
                          try {
                            await ref
                                .read(rdsoRemoteDataSourceProvider)
                                .sendFileMail(
                                  fileId: fileId,
                                  recipient: recipient,
                                  message: message.text,
                                );
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.pop(context);
                            await AppDialog.show(
                              context,
                              variant: AppDialogVariant.success,
                              title: 'Send via mail',
                              message:
                                  'Your message has been queued for delivery.',
                            );
                          } on Object catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            setState(() => sending = false);
                            await AppDialog.show(
                              context,
                              variant: AppDialogVariant.error,
                              title: 'Send via mail',
                              message: error is DioException
                                  ? userFriendlyErrorMessage(error)
                                  : 'Unable to send this file.',
                            );
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    email.dispose();
    message.dispose();
  }
}

Future<void> showRdsoImportStatusDialog({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return _ImportStatusDialog(ref: ref);
    },
  );
}

class _ImportStatusDialog extends ConsumerStatefulWidget {
  const _ImportStatusDialog({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_ImportStatusDialog> createState() =>
      _ImportStatusDialogState();
}

class _ImportStatusDialogState extends ConsumerState<_ImportStatusDialog> {
  List<RdsoCrawlRun> _runs = const <RdsoCrawlRun>[];
  bool _loading = true;
  Object? _error;
  String? _cancellingRunId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<RdsoCrawlRun> runs = await ref
          .read(rdsoRemoteDataSourceProvider)
          .fetchCrawlRuns();
      if (!mounted) {
        return;
      }
      setState(() {
        _runs = runs;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _showLogs(RdsoCrawlRun run) async {
    try {
      final String logs = await ref
          .read(rdsoRemoteDataSourceProvider)
          .fetchCrawlRunLogs(run.id);
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          final String body = logs.trim().isEmpty
              ? (run.logTail.trim().isEmpty ? 'No logs available.' : run.logTail)
              : logs;
          return AlertDialog(
            title: Text('Run ${run.id} logs'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'View logs',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : 'Unable to load logs.',
      );
    }
  }

  Future<void> _cancelRun(RdsoCrawlRun run) async {
    if (_cancellingRunId != null) {
      return;
    }
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Cancel run',
      message:
          'Stop this import run? It may take a moment to finish cancelling.',
      primaryLabel: 'Cancel run',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _cancellingRunId = run.id);
    try {
      await ref.read(rdsoRemoteDataSourceProvider).cancelCrawlRun(run.id);
      if (!mounted) {
        return;
      }
      await _load();
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Cancel run',
        message: 'The import run has been cancelled.',
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Cancel run',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : 'Unable to cancel this run.',
      );
    } finally {
      if (mounted) {
        setState(() => _cancellingRunId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final double maxListHeight =
        MediaQuery.sizeOf(context).height * 0.52;

    return AlertDialog(
      title: const Text('Import Status'),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            RfiContentLoader(loading: _loading),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  _error is DioException
                      ? userFriendlyErrorMessage(_error! as DioException)
                      : _error.toString(),
                  style: TextStyle(color: colors.error),
                ),
              )
            else if (!_loading && _runs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('No import runs found.'),
              )
            else if (!_loading)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _runs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final RdsoCrawlRun run = _runs[index];
                    return _ImportRunCard(
                      run: run,
                      cancelling: _cancellingRunId == run.id,
                      cancelDisabled: _cancellingRunId != null,
                      onViewLogs: () => _showLogs(run),
                      onCancel: run.isRunning ? () => _cancelRun(run) : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton.icon(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ImportRunCard extends StatelessWidget {
  const _ImportRunCard({
    required this.run,
    required this.cancelling,
    required this.cancelDisabled,
    required this.onViewLogs,
    this.onCancel,
  });

  final RdsoCrawlRun run;
  final bool cancelling;
  final bool cancelDisabled;
  final VoidCallback onViewLogs;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final _RunStatusStyle statusStyle = _runStatusStyle(run.status, colors);
    final String? counts = _runCountsSummary(run);
    final String? started = _formatCrawlRunTimestamp(run.startedAt);
    final String? finished = _formatCrawlRunTimestamp(run.finishedAt);
    final String phase = run.phase.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
        color: colors.surfaceContainerLowest,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _RunStatusChip(label: statusStyle.label, style: statusStyle),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '#${run.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (phase.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                phase,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (started != null || finished != null) ...<Widget>[
              const SizedBox(height: 6),
              if (started != null)
                _RunMetaRow(label: 'Started', value: started),
              if (finished != null)
                _RunMetaRow(label: 'Finished', value: finished),
            ],
            if (counts != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                counts,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 0,
              children: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onViewLogs,
                  child: const Text('View logs'),
                ),
                if (onCancel != null)
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: colors.error,
                    ),
                    onPressed: cancelDisabled ? null : onCancel,
                    child: cancelling
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.error,
                            ),
                          )
                        : const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RunMetaRow extends StatelessWidget {
  const _RunMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    final TextStyle? valueStyle = theme.textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 58,
            child: Text(label, style: labelStyle),
          ),
          Expanded(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}

class _RunStatusChip extends StatelessWidget {
  const _RunStatusChip({required this.label, required this.style});

  final String label;
  final _RunStatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: style.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: style.foreground,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _RunStatusStyle {
  const _RunStatusStyle({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color border;
}

_RunStatusStyle _runStatusStyle(String rawStatus, ColorScheme colors) {
  final String normalized =
      rawStatus.trim().toLowerCase().replaceAll('-', '_');
  final String label = rawStatus.trim().isEmpty
      ? 'Unknown'
      : rawStatus.trim().replaceAll('_', ' ');

  if (normalized == 'running' ||
      normalized == 'in_progress' ||
      normalized == 'pending') {
    return _RunStatusStyle(
      label: _titleCase(label),
      foreground: colors.onPrimaryContainer,
      background: colors.primaryContainer,
      border: colors.primary.withValues(alpha: 0.35),
    );
  }
  if (normalized == 'failed' ||
      normalized == 'error' ||
      normalized == 'cancelled' ||
      normalized == 'canceled') {
    return _RunStatusStyle(
      label: _titleCase(label),
      foreground: colors.onErrorContainer,
      background: colors.errorContainer,
      border: colors.error.withValues(alpha: 0.35),
    );
  }
  if (normalized == 'succeeded' ||
      normalized == 'success' ||
      normalized == 'completed' ||
      normalized == 'done') {
    return _RunStatusStyle(
      label: _titleCase(label),
      foreground: colors.onTertiaryContainer,
      background: colors.tertiaryContainer,
      border: colors.tertiary.withValues(alpha: 0.35),
    );
  }
  return _RunStatusStyle(
    label: _titleCase(label),
    foreground: colors.onSurfaceVariant,
    background: colors.surfaceContainerHighest,
    border: colors.outlineVariant,
  );
}

String _titleCase(String value) {
  if (value.isEmpty) {
    return value;
  }
  return value
      .split(RegExp(r'\s+'))
      .map(
        (String word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String? _formatCrawlRunTimestamp(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  final String trimmed = raw.trim();
  final DateTime? parsed = DateTime.tryParse(trimmed);
  if (parsed != null) {
    final DateTime local = parsed.toLocal();
    return DateFormat('MMM d, yyyy · HH:mm').format(local);
  }
  if (trimmed.length > 24) {
    return '${trimmed.substring(0, 24)}…';
  }
  return trimmed;
}

String? _runCountsSummary(RdsoCrawlRun run) {
  final List<String> counts = <String>[];
  if (run.categoriesCount != null) {
    counts.add('${run.categoriesCount} categories');
  }
  if (run.drawingsCount != null) {
    counts.add('${run.drawingsCount} drawings');
  }
  if (run.filesCount != null) {
    counts.add('${run.filesCount} files');
  }
  if (counts.isEmpty) {
    return null;
  }
  return counts.join(' · ');
}

Future<void> runRdsoSyncNow({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  try {
    await ref.read(rdsoRemoteDataSourceProvider).startCrawl();
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.success,
      title: 'Sync Now',
      message: 'RDSO library sync has been started.',
    );
  } on RdsoCrawlConflictException catch (error) {
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.warning,
      title: 'Sync Now',
      message: error.message,
    );
  } on Object catch (error) {
    if (!context.mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: 'Sync Now',
      message: error is DioException
          ? userFriendlyErrorMessage(error)
          : 'Unable to start sync.',
    );
  }
}
