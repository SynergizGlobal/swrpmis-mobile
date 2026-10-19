import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_checklist_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_details.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_uploaded_by.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_inspection_flow_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/rfi_inspection_errors.dart';

Future<void> showRfiChecklistDialog({
  required BuildContext context,
  required RfiInspectionFlowController controller,
  required RfiInspectionEnclosure enclosure,
  required RfiInspectionDetails details,
  required RfiUserRole role,
}) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _RfiChecklistDialog(
        controller: controller,
        enclosure: enclosure,
        details: details,
        role: role,
      );
    },
  );
}

class _RfiChecklistDialog extends StatefulWidget {
  const _RfiChecklistDialog({
    required this.controller,
    required this.enclosure,
    required this.details,
    required this.role,
  });

  final RfiInspectionFlowController controller;
  final RfiInspectionEnclosure enclosure;
  final RfiInspectionDetails details;
  final RfiUserRole role;

  @override
  State<_RfiChecklistDialog> createState() => _RfiChecklistDialogState();
}

class _RfiChecklistDialogState extends State<_RfiChecklistDialog> {
  static const List<String> _statusOptions = <String>['YES', 'NO', 'N/A'];
  static const List<String> _selectAllOptions = <String>[
    '--Select--',
    'YES',
    'NO',
    'N/A',
    'Clear All',
  ];

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _info = '';
  String _selectAll = '--Select--';
  List<RfiChecklistItem> _items = const <RfiChecklistItem>[];
  late final TextEditingController _gradeController;

  bool get _isContractor => rfiRoleIsContractorSide(widget.role);

  @override
  void initState() {
    super.initState();
    _gradeController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<RfiChecklistItem> items =
          await widget.controller.loadChecklist(widget.enclosure);
      final String grade = items
          .map((RfiChecklistItem item) => item.gradeOfConcrete)
          .firstWhere((String value) => value.isNotEmpty, orElse: () => '');
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _gradeController.text = grade;
        _info = items.isEmpty
            ? 'No checklist items found.'
            : 'Loaded existing checklist data.';
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = rfiInspectionErrorMessage(error);
      });
    }
  }

  void _applySelectAll(String? value) {
    if (value == null || value == '--Select--') {
      setState(() => _selectAll = '--Select--');
      return;
    }
    if (value == 'Clear All') {
      setState(() {
        _selectAll = '--Select--';
        _items = _items
            .map(
              (RfiChecklistItem item) => _isContractor
                  ? item.copyWith(contractorStatus: '')
                  : item.copyWith(engineerStatus: ''),
            )
            .toList();
      });
      return;
    }
    setState(() {
      _selectAll = value;
      _items = _items
          .map(
            (RfiChecklistItem item) => _isContractor
                ? item.copyWith(contractorStatus: value)
                : item.copyWith(engineerStatus: value),
          )
          .toList();
    });
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final String message = await widget.controller.saveChecklist(
        enclosure: widget.enclosure,
        items: _items,
        gradeOfConcrete: _gradeController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Checklist saved',
        message: message,
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Checklist save failed',
        message: rfiInspectionErrorMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final RfiInspectionDetailRfi rfi = widget.details.rfi;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              color: const Color(0xFFD6E4F5),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.enclosure.enclosureName.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.brandPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (_info.isNotEmpty)
              Container(
                width: double.infinity,
                color: const Color(0xFFE8F1FB),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(_info, style: theme.textTheme.bodyMedium),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_error!),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: <Widget>[
                            _metaField('Name of Contract', rfi.contract),
                            _metaField('Date', rfi.dateOfInspection),
                            _metaField('Structure Type', rfi.structureType),
                            _metaField('Component', rfi.component),
                            _metaField('RFI No', rfi.rfiId),
                            const SizedBox(height: 8),
                            Text(
                              'Grade of Concrete/Steel',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _gradeController,
                              enabled: _isContractor && !_saving,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              color: AppTheme.brandPrimary,
                              child: Text(
                                widget.enclosure.enclosureName.toUpperCase(),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (_isContractor) ...<Widget>[
                              const SizedBox(height: 12),
                              Row(
                                children: <Widget>[
                                  const Text('Contractor Select All:'),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectAll,
                                      items: _selectAllOptions
                                          .map(
                                            (String option) =>
                                                DropdownMenuItem<String>(
                                              value: option,
                                              child: Text(option),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: _saving ? null : _applySelectAll,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            for (int i = 0; i < _items.length; i++)
                              _ChecklistRowCard(
                                index: i + 1,
                                item: _items[i],
                                statusOptions: _statusOptions,
                                contractorEditable: _isContractor && !_saving,
                                engineerEditable:
                                    !_isContractor && !_saving,
                                onContractorStatus: (String? value) {
                                  setState(() {
                                    _items = List<RfiChecklistItem>.from(
                                      _items,
                                    );
                                    _items[i] = _items[i].copyWith(
                                      contractorStatus: value ?? '',
                                    );
                                  });
                                },
                                onEngineerStatus: (String? value) {
                                  setState(() {
                                    _items = List<RfiChecklistItem>.from(
                                      _items,
                                    );
                                    _items[i] = _items[i].copyWith(
                                      engineerStatus: value ?? '',
                                    );
                                  });
                                },
                                onContractorRemark: (String value) {
                                  _items = List<RfiChecklistItem>.from(_items);
                                  _items[i] = _items[i].copyWith(
                                    contractorRemarks: value,
                                  );
                                },
                                onEngineerRemark: (String value) {
                                  _items = List<RfiChecklistItem>.from(_items);
                                  _items[i] = _items[i].copyWith(
                                    engineerRemark: value,
                                  );
                                },
                              ),
                          ],
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FilledButton(
                    onPressed: _saving || _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary,
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value.isEmpty ? '—' : value),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

class _ChecklistRowCard extends StatelessWidget {
  const _ChecklistRowCard({
    required this.index,
    required this.item,
    required this.statusOptions,
    required this.contractorEditable,
    required this.engineerEditable,
    required this.onContractorStatus,
    required this.onEngineerStatus,
    required this.onContractorRemark,
    required this.onEngineerRemark,
  });

  final int index;
  final RfiChecklistItem item;
  final List<String> statusOptions;
  final bool contractorEditable;
  final bool engineerEditable;
  final ValueChanged<String?> onContractorStatus;
  final ValueChanged<String?> onEngineerStatus;
  final ValueChanged<String> onContractorRemark;
  final ValueChanged<String> onEngineerRemark;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '$index. ${item.checklistDescription}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text('Contractor Status', style: Theme.of(context).textTheme.labelMedium),
            Wrap(
              spacing: 4,
              children: statusOptions
                  .map(
                    (String option) => ChoiceChip(
                      label: Text(option),
                      selected:
                          item.contractorStatus.toUpperCase() == option,
                      onSelected: contractorEditable
                          ? (bool selected) =>
                              onContractorStatus(selected ? option : '')
                          : null,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            Text('Engineer Status', style: Theme.of(context).textTheme.labelMedium),
            Wrap(
              spacing: 4,
              children: statusOptions
                  .map(
                    (String option) => ChoiceChip(
                      label: Text(option),
                      selected: item.engineerStatus.toUpperCase() == option,
                      onSelected: engineerEditable
                          ? (bool selected) =>
                              onEngineerStatus(selected ? option : '')
                          : null,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              enabled: contractorEditable,
              initialValue: item.contractorRemarks,
              decoration: const InputDecoration(
                labelText: 'Contractor Remark',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: onContractorRemark,
            ),
            const SizedBox(height: 8),
            TextFormField(
              enabled: engineerEditable,
              initialValue: item.engineerRemark,
              decoration: const InputDecoration(
                labelText: 'Engineer Remark',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: onEngineerRemark,
            ),
          ],
        ),
      ),
    );
  }
}
