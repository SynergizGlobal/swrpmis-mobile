import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    await AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: 'Cancel run',
      message: 'Cancel is not available from the mobile app yet.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Status'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            RfiContentLoader(loading: _loading),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _error is DioException
                      ? userFriendlyErrorMessage(_error! as DioException)
                      : _error.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            else if (!_loading && _runs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No import runs found.'),
              )
            else if (!_loading)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _runs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final RdsoCrawlRun run = _runs[index];
                    return ListTile(
                      title: Text(
                        run.status.isEmpty ? 'Unknown' : run.status,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        _runSubtitle(run),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 4,
                        children: <Widget>[
                          TextButton(
                            onPressed: () => _showLogs(run),
                            child: const Text('View logs'),
                          ),
                          if (run.isRunning)
                            TextButton(
                              onPressed: () => _cancelRun(run),
                              child: const Text('Cancel'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _loading ? null : _load,
          child: const Text('Refresh'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _runSubtitle(RdsoCrawlRun run) {
    final List<String> parts = <String>[];
    if (run.phase.trim().isNotEmpty) {
      parts.add('Phase: ${run.phase}');
    }
    if (run.startedAt != null && run.startedAt!.trim().isNotEmpty) {
      parts.add('Started: ${run.startedAt}');
    }
    if (run.finishedAt != null && run.finishedAt!.trim().isNotEmpty) {
      parts.add('Finished: ${run.finishedAt}');
    }
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
    if (counts.isNotEmpty) {
      parts.add(counts.join(', '));
    }
    return parts.isEmpty ? 'Run ${run.id}' : parts.join('\n');
  }
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
