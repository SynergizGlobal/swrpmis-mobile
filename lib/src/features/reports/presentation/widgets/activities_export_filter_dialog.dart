import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/activities_export_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/activities_export_option.dart';

/// Guided Project → Contract filter before generating the Excel report.
///
/// Returns selected ids, or `null` if cancelled.
Future<({String projectId, String contractId})?>
showActivitiesExportFilterDialog(
  BuildContext context, {
  required List<ActivitiesExportProject> projects,
  String initialProjectId = '',
  String initialContractId = '',
}) {
  return showDialog<({String projectId, String contractId})>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return ActivitiesExportFilterDialog(
        projects: projects,
        initialProjectId: initialProjectId,
        initialContractId: initialContractId,
      );
    },
  );
}

class ActivitiesExportFilterDialog extends ConsumerStatefulWidget {
  const ActivitiesExportFilterDialog({
    super.key,
    required this.projects,
    this.initialProjectId = '',
    this.initialContractId = '',
  });

  final List<ActivitiesExportProject> projects;
  final String initialProjectId;
  final String initialContractId;

  @override
  ConsumerState<ActivitiesExportFilterDialog> createState() =>
      _ActivitiesExportFilterDialogState();
}

class _ActivitiesExportFilterDialogState
    extends ConsumerState<ActivitiesExportFilterDialog> {
  static const int _stepProject = 0;
  static const int _stepContract = 1;

  late int _step;
  late String _projectId;
  late String _contractId;
  List<ActivitiesExportContract> _contracts = const <ActivitiesExportContract>[];
  bool _loadingContracts = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _projectId = widget.initialProjectId.trim();
    _contractId = widget.initialContractId.trim();
    // Resume at contract step when project is already chosen.
    _step = _projectId.isEmpty ? _stepProject : _stepContract;
    if (_projectId.isNotEmpty) {
      Future<void>.microtask(_loadContracts);
    }
  }

  Future<void> _loadContracts() async {
    if (_projectId.isEmpty) {
      setState(() {
        _contracts = const <ActivitiesExportContract>[];
        _contractId = '';
        _loadingContracts = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loadingContracts = true;
      _error = null;
    });
    try {
      final List<ActivitiesExportContract> contracts = await ref
          .read(activitiesExportRemoteDataSourceProvider)
          .fetchContracts(projectId: _projectId);
      if (!mounted) {
        return;
      }
      String contractId = _contractId;
      if (contractId.isNotEmpty &&
          !contracts.any(
            (ActivitiesExportContract item) => item.contractId == contractId,
          )) {
        contractId = '';
      }
      setState(() {
        _contracts = contracts;
        _contractId = contractId;
        _loadingContracts = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingContracts = false;
        _error = error;
      });
    }
  }

  ActivitiesExportProject? get _selectedProject {
    for (final ActivitiesExportProject item in widget.projects) {
      if (item.projectId == _projectId) {
        return item;
      }
    }
    return null;
  }

  ActivitiesExportContract? get _selectedContract {
    for (final ActivitiesExportContract item in _contracts) {
      if (item.contractId == _contractId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _pickProject() async {
    final String? picked = await _showOptions(
      title: 'Select project',
      options: <({String id, String label})>[
        for (final ActivitiesExportProject item in widget.projects)
          (id: item.projectId, label: item.label),
      ],
      selectedId: _projectId,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _projectId = picked;
      _contractId = '';
      _error = null;
    });
    await _loadContracts();
  }

  Future<void> _pickContract() async {
    final String? picked = await _showOptions(
      title: 'Select contract',
      options: <({String id, String label})>[
        for (final ActivitiesExportContract item in _contracts)
          (id: item.contractId, label: item.label),
      ],
      selectedId: _contractId,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _contractId = picked);
  }

  Future<String?> _showOptions({
    required String title,
    required List<({String id, String label})> options,
    required String selectedId,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    title,
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: options.isEmpty
                      ? const Center(child: Text('No options available.'))
                      : ListView.builder(
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ({String id, String label}) option =
                                options[index];
                            final bool selected = option.id == selectedId;
                            return ListTile(
                              title: Text(option.label),
                              trailing: selected
                                  ? Icon(
                                      Icons.check_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    )
                                  : null,
                              onTap: () =>
                                  Navigator.pop(sheetContext, option.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onNext() {
    if (_step == _stepProject) {
      if (_projectId.isEmpty) {
        setState(() => _error = 'Please select a project first.');
        return;
      }
      setState(() {
        _step = _stepContract;
        _error = null;
      });
      if (_contracts.isEmpty && !_loadingContracts) {
        _loadContracts();
      }
      return;
    }
    if (_contractId.isEmpty && _contracts.isNotEmpty) {
      setState(() => _error = 'Please select a contract to continue.');
      return;
    }
    Navigator.pop(context, (projectId: _projectId, contractId: _contractId));
  }

  void _onBack() {
    if (_step == _stepContract) {
      setState(() {
        _step = _stepProject;
        _error = null;
      });
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool projectStep = _step == _stepProject;
    final String? errorText = _error == null
        ? null
        : _error is String
        ? _error as String
        : _error is DioException
        ? userFriendlyErrorMessage(_error! as DioException)
        : _error.toString();

    return AlertDialog(
      title: Text(projectStep ? 'Select project' : 'Select contract'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              projectStep
                  ? 'Choose a project first. Contract options will load next.'
                  : 'Choose a contract under the selected project.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.mutedText),
            ),
            const SizedBox(height: 14),
            _StepDots(step: _step, total: 2),
            const SizedBox(height: 14),
            if (!projectStep) ...<Widget>[
              _ReadOnlyChip(
                label: 'Project',
                value: _selectedProject?.label ?? _projectId,
              ),
              const SizedBox(height: 10),
            ],
            if (projectStep)
              _DialogPicker(
                label: 'Project (${widget.projects.length} available)',
                value: _selectedProject?.label,
                onTap: _pickProject,
              )
            else
              _DialogPicker(
                label: _loadingContracts
                    ? 'Contract (loading...)'
                    : 'Contract (${_contracts.length} available)',
                value: _selectedContract?.label,
                enabled: !_loadingContracts && _contracts.isNotEmpty,
                onTap: _pickContract,
              ),
            if (_loadingContracts) ...<Widget>[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 2),
            ],
            if (errorText != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                errorText,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.error),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _onBack,
          child: Text(projectStep ? 'Cancel' : 'Back'),
        ),
        FilledButton(
          onPressed: _loadingContracts ? null : _onNext,
          child: Text(projectStep ? 'Next' : 'Generate'),
        ),
      ],
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        for (int i = 0; i < total; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= step
                    ? colors.primary
                    : colors.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReadOnlyChip extends StatelessWidget {
  const _ReadOnlyChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: palette.fieldFill,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DialogPicker extends StatelessWidget {
  const _DialogPicker({
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool hasValue = value != null && value!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Material(
          color: palette.fieldFill,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            child: Container(
              constraints: const BoxConstraints(minHeight: AppTheme.fieldHeight),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: palette.borderSubtle),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      hasValue ? value! : 'Select',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasValue
                            ? Theme.of(context).colorScheme.onSurface
                            : palette.mutedText,
                      ),
                    ),
                  ),
                  Icon(Icons.expand_more_rounded, color: palette.mutedText),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
