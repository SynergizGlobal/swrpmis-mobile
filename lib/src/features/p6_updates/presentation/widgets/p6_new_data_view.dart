import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/domain/p6_list.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/presentation/providers/p6_providers.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

class P6NewDataView extends ConsumerStatefulWidget {
  const P6NewDataView({super.key});

  @override
  ConsumerState<P6NewDataView> createState() => _P6NewDataViewState();
}

class _P6NewDataViewState extends ConsumerState<P6NewDataView> {
  final Map<P6UploadKind, _PanelDraft> _drafts = <P6UploadKind, _PanelDraft>{
    for (final P6UploadKind kind in P6UploadKind.values) kind: _PanelDraft(),
  };

  Future<void> _retry() {
    return ref.read(p6NewDataControllerProvider.notifier).load();
  }

  Future<void> _onProjectChanged(P6UploadKind kind, String projectId) async {
    final _PanelDraft draft = _drafts[kind]!;
    setState(() {
      draft.projectId = projectId;
      draft.contractId = '';
    });
    await ref
        .read(p6NewDataControllerProvider.notifier)
        .loadContractsForProject(kind: kind, projectId: projectId);
  }

  Future<void> _pickFile(P6UploadKind kind) async {
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['xlsx', 'xls'],
      withData: false,
    );
    final String? path = picked?.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }
    final String lower = path.toLowerCase();
    if (!lower.endsWith('.xlsx') && !lower.endsWith('.xls')) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Upload',
        message: 'Please select a P6 export Excel file (.xlsx or .xls).',
      );
      return;
    }
    setState(() {
      _drafts[kind]!.filePath = path;
    });
  }

  Future<void> _onFormatTap() async {
    if (!mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: 'File format',
      message:
          'P6 file-format download URL is not confirmed in the mobile API '
          'surface yet. Use the web Structure P6 Updates note link for the '
          'template until a dedicated download path is provided.',
    );
  }

  Future<void> _submit(P6UploadKind kind) async {
    final _PanelDraft draft = _drafts[kind]!;
    if (draft.uploading) {
      return;
    }
    final String projectId = draft.projectId.trim();
    final String contractId = draft.contractId.trim();
    final DateTime? date = draft.dataDate;
    final String? filePath = draft.filePath;
    if (projectId.isEmpty ||
        contractId.isEmpty ||
        date == null ||
        filePath == null ||
        filePath.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: kind.actionLabel,
        message:
            'Please select Project, Contract, Data Date, and a P6 export file.',
      );
      return;
    }
    setState(() => draft.uploading = true);
    try {
      final String message = await ref
          .read(p6NewDataControllerProvider.notifier)
          .upload(
            kind: kind,
            projectId: projectId,
            contractId: contractId,
            dataDateIso: DateFormat('yyyy-MM-dd').format(date),
            filePath: filePath,
          );
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: kind.title,
        message: message,
      );
      setState(() {
        draft.filePath = null;
      });
      await ref.read(p6HistoryControllerProvider.notifier).load();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: kind.title,
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error is StateError
            ? error.message
            : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => draft.uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final P6NewDataState state = ref.watch(p6NewDataControllerProvider);
    final bool failed = state.error != null && state.master.projects.isEmpty;

    if (failed && !state.loading) {
      return _Message(
        message: state.error is DioException
            ? userFriendlyErrorMessage(state.error! as DioException)
            : state.error.toString(),
        onRetry: _retry,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RfiContentLoader(loading: state.loading),
        Expanded(
          child: state.loading && state.master.projects.isEmpty
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: <Widget>[
                    for (final P6UploadKind kind in P6UploadKind.values) ...<
                      Widget
                    >[
                      _UploadCard(
                        kind: kind,
                        draft: _drafts[kind]!,
                        projects: state.master.projects,
                        contracts: state.contractsFor(kind),
                        loadingContracts: state.isLoadingContracts(kind),
                        enabled: !state.loading,
                        onProject: (String id) => _onProjectChanged(kind, id),
                        onContract: (String id) {
                          setState(() => _drafts[kind]!.contractId = id);
                        },
                        onDate: (DateTime date) {
                          setState(() => _drafts[kind]!.dataDate = date);
                        },
                        onPickFile: () => _pickFile(kind),
                        onSubmit: () => _submit(kind),
                        onFormatTap: _onFormatTap,
                      ),
                      if (kind != P6UploadKind.update)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _PanelDraft {
  String projectId = '';
  String contractId = '';
  DateTime? dataDate;
  String? filePath;
  bool uploading = false;
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.kind,
    required this.draft,
    required this.projects,
    required this.contracts,
    required this.loadingContracts,
    required this.enabled,
    required this.onProject,
    required this.onContract,
    required this.onDate,
    required this.onPickFile,
    required this.onSubmit,
    required this.onFormatTap,
  });

  final P6UploadKind kind;
  final _PanelDraft draft;
  final List<P6Option> projects;
  final List<P6Option> contracts;
  final bool loadingContracts;
  final bool enabled;
  final ValueChanged<String> onProject;
  final ValueChanged<String> onContract;
  final ValueChanged<DateTime> onDate;
  final VoidCallback onPickFile;
  final VoidCallback onSubmit;
  final VoidCallback onFormatTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    final bool busy = draft.uploading || !enabled;
    final String? fileName = draft.filePath == null
        ? null
        : p.basename(draft.filePath!);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ColoredBox(
            color: AppTheme.brandPrimary.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                kind.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: IgnorePointer(
              ignoring: busy,
              child: Opacity(
                opacity: busy ? 0.65 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _dropdown(
                      label: 'Project *',
                      emptyLabel: 'Select...',
                      options: projects,
                      selectedId: draft.projectId,
                      onPick: onProject,
                    ),
                    const SizedBox(height: 12),
                    _dropdown(
                      label: 'Contract *',
                      emptyLabel: 'Select Contract',
                      options: contracts,
                      selectedId: draft.contractId,
                      enabled: draft.projectId.isNotEmpty && !loadingContracts,
                      onPick: onContract,
                    ),
                    if (loadingContracts) ...<Widget>[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    const SizedBox(height: 12),
                    _dateField(context),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: busy ? null : onPickFile,
                      icon: const Icon(Icons.attach_file_rounded, size: 18),
                      label: Text(
                        fileName == null || fileName.isEmpty
                            ? 'Upload P6 Export File'
                            : fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      child: FilledButton(
                        onPressed: busy ? null : onSubmit,
                        child: draft.uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(kind.actionLabel),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.mutedText,
                          height: 1.35,
                        ),
                        children: <InlineSpan>[
                          const TextSpan(
                            text:
                                'Note : Please make sure the uploading P6 data '
                                'file will be in the given format. Click ',
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: onFormatTap,
                              child: Text(
                                'here',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' for the file format.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String emptyLabel,
    required List<P6Option> options,
    required String selectedId,
    required ValueChanged<String> onPick,
    bool enabled = true,
  }) {
    final String? value = _labelOf(options, selectedId);
    return SizedBox(
      height: 56,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: RfiFilterField(
            label: label,
            emptyLabel: emptyLabel,
            value: value,
            options: <RfiFilterOption>[
              for (final P6Option option in options)
                RfiFilterOption(id: option.value, label: option.label),
            ],
            selectedId: selectedId.isEmpty ? null : selectedId,
            onClear: !enabled || selectedId.isEmpty ? null : () => onPick(''),
            onPick: (RfiFilterOption option) => onPick(option.id),
          ),
        ),
      ),
    );
  }

  Widget _dateField(BuildContext context) {
    final String text = draft.dataDate == null
        ? 'dd/mm/yyyy'
        : DateFormat('dd/MM/yyyy').format(draft.dataDate!);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      onTap: () async {
        final DateTime now = DateTime.now();
        final DateTime? picked = await showDatePicker(
          context: context,
          useRootNavigator: true,
          initialDate: draft.dataDate ?? now,
          firstDate: DateTime(now.year - 15),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) {
          onDate(DateTime(picked.year, picked.month, picked.day));
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Data Date *',
          suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: draft.dataDate == null
                ? AppPalette.of(context).mutedText
                : null,
          ),
        ),
      ),
    );
  }

  String? _labelOf(List<P6Option> options, String id) {
    if (id.isEmpty) {
      return null;
    }
    for (final P6Option option in options) {
      if (option.value == id) {
        return option.label;
      }
    }
    return id;
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
