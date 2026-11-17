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

class P6UploadSheet extends ConsumerStatefulWidget {
  const P6UploadSheet({super.key, required this.kind});

  final P6UploadKind kind;

  @override
  ConsumerState<P6UploadSheet> createState() => _P6UploadSheetState();
}

class _P6UploadSheetState extends ConsumerState<P6UploadSheet> {
  String _projectId = '';
  String _contractId = '';
  DateTime? _dataDate;
  String? _filePath;
  bool _uploading = false;

  P6UploadKind get _kind => widget.kind;

  Future<void> _onProjectChanged(String projectId) async {
    setState(() {
      _projectId = projectId;
      _contractId = '';
    });
    await ref
        .read(p6NewDataControllerProvider.notifier)
        .loadContractsForProject(kind: _kind, projectId: projectId);
  }

  Future<void> _pickFile() async {
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
    setState(() => _filePath = path);
  }

  Future<void> _submit() async {
    if (_uploading) {
      return;
    }
    final String projectId = _projectId.trim();
    final String contractId = _contractId.trim();
    if (projectId.isEmpty ||
        contractId.isEmpty ||
        _dataDate == null ||
        _filePath == null ||
        _filePath!.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: _kind.actionLabel,
        message:
            'Please select Project, Contract, Data Date, and a P6 export file.',
      );
      return;
    }
    setState(() => _uploading = true);
    try {
      final String message = await ref
          .read(p6NewDataControllerProvider.notifier)
          .upload(
            kind: _kind,
            projectId: projectId,
            contractId: contractId,
            dataDateIso: DateFormat('yyyy-MM-dd').format(_dataDate!),
            filePath: _filePath!,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: _kind.title,
        message: message,
      );
      await ref.read(p6HistoryControllerProvider.notifier).load();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: _kind.title,
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error is StateError
                ? error.message
                : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final P6NewDataState state = ref.watch(p6NewDataControllerProvider);
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = AppPalette.of(context);
    final List<P6Option> contracts = state.contractsFor(_kind);
    final bool loadingContracts = state.isLoadingContracts(_kind);
    final bool busy = _uploading || state.loading;
    final String? fileName =
        _filePath == null ? null : p.basename(_filePath!);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          ColoredBox(
            color: AppTheme.brandPrimary.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                _kind.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          RfiContentLoader(loading: state.loading),
          // Form body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
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
                        options: state.master.projects,
                        selectedId: _projectId,
                        onPick: _onProjectChanged,
                      ),
                      const SizedBox(height: 12),
                      _dropdown(
                        label: 'Contract *',
                        emptyLabel: 'Select Contract',
                        options: contracts,
                        selectedId: _contractId,
                        enabled:
                            _projectId.isNotEmpty && !loadingContracts,
                        onPick: (String id) =>
                            setState(() => _contractId = id),
                      ),
                      if (loadingContracts) ...<Widget>[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(minHeight: 2),
                      ],
                      const SizedBox(height: 12),
                      _dateField(context),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: busy ? null : _pickFile,
                        icon:
                            const Icon(Icons.attach_file_rounded, size: 18),
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
                          onPressed: busy ? null : _submit,
                          child: _uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_kind.actionLabel),
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
                                  'Note : Please make sure the uploading P6 '
                                  'data file will be in the given format. '
                                  'Click ',
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: wire download when backend provides a file-format URL.
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'here',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          theme.colorScheme.primary,
                                    ),
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
    String? labelOf(String id) {
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

    final String? value = labelOf(selectedId);
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
    final String text = _dataDate == null
        ? 'dd/mm/yyyy'
        : DateFormat('dd/MM/yyyy').format(_dataDate!);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      onTap: () async {
        final DateTime now = DateTime.now();
        final DateTime? picked = await showDatePicker(
          context: context,
          useRootNavigator: true,
          initialDate: _dataDate ?? now,
          firstDate: DateTime(now.year - 15),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) {
          setState(
            () => _dataDate = DateTime(picked.year, picked.month, picked.day),
          );
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
            color: _dataDate == null ? AppPalette.of(context).mutedText : null,
          ),
        ),
      ),
    );
  }
}
