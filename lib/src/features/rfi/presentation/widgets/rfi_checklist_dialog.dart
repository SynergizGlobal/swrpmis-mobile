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
      final List<RfiChecklistItem> items = await widget.controller
          .loadChecklist(widget.enclosure);
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
                        _metaField('Element', rfi.element),
                        _metaField('Activity', rfi.activity),
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
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Text(
                              _isContractor
                                  ? 'Contractor Select All:'
                                  : 'Engineer Select All:',
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                key: ValueKey<String>('all-$_selectAll'),
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
                        const SizedBox(height: 12),
                        _ChecklistTable(
                          items: _items,
                          statusOptions: _statusOptions,
                          contractorEditable: _isContractor && !_saving,
                          engineerEditable: !_isContractor && !_saving,
                          onChanged: (int i, RfiChecklistItem item) {
                            setState(() {
                              _items = List<RfiChecklistItem>.from(_items)
                                ..[i] = item;
                            });
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
                    // The app theme makes filled buttons full width; in this
                    // Row that is infinite and the dialog fails to lay out.
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary,
                      minimumSize: const Size(96, 44),
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
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    // The app theme makes filled buttons full width; in this
                    // Row that is infinite and the dialog fails to lay out.
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary,
                      minimumSize: const Size(96, 44),
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

/// Web-style checklist table: ID, Description, Contractor Status,
/// Engineer Status, Contractor Remark, Engineer Remark. Each side edits only
/// its own two columns; the other side's are read-only text.
class _ChecklistTable extends StatelessWidget {
  const _ChecklistTable({
    required this.items,
    required this.statusOptions,
    required this.contractorEditable,
    required this.engineerEditable,
    required this.onChanged,
  });

  final List<RfiChecklistItem> items;
  final List<String> statusOptions;
  final bool contractorEditable;
  final bool engineerEditable;
  final void Function(int index, RfiChecklistItem item) onChanged;

  static const List<(String, double)> _columns = <(String, double)>[
    ('ID', 44),
    ('Description', 230),
    ('Contractor Status', 130),
    ('Engineer Status', 130),
    ('Contractor Remark', 170),
    ('Engineer Remark', 170),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BorderSide line = BorderSide(color: scheme.outlineVariant);
    Widget cell(double width, Widget child, {Color? color}) => Container(
      width: width,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      alignment: Alignment.centerLeft,
      child: child,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.fromBorderSide(line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                for (final (String label, double width) in _columns)
                  cell(
                    width,
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.brandPrimary,
                      ),
                    ),
                    color: scheme.brightness == Brightness.dark
                        ? const Color(0xFF1B3556)
                        : const Color(0xFFE8F1FB),
                  ),
              ],
            ),
            for (int i = 0; i < items.length; i++)
              DecoratedBox(
                decoration: BoxDecoration(border: Border(top: line)),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      cell(_columns[0].$2, Text('${i + 1}')),
                      cell(_columns[1].$2, Text(items[i].checklistDescription)),
                      cell(
                        _columns[2].$2,
                        _status(
                          context,
                          'c-$i-${items[i].contractorStatus}',
                          items[i].contractorStatus,
                          contractorEditable,
                          (String v) => onChanged(
                            i,
                            items[i].copyWith(contractorStatus: v),
                          ),
                        ),
                      ),
                      cell(
                        _columns[3].$2,
                        _status(
                          context,
                          'e-$i-${items[i].engineerStatus}',
                          items[i].engineerStatus,
                          engineerEditable,
                          (String v) => onChanged(
                            i,
                            items[i].copyWith(engineerStatus: v),
                          ),
                        ),
                      ),
                      cell(
                        _columns[4].$2,
                        _remark(
                          'cr-$i',
                          items[i].contractorRemarks,
                          contractorEditable,
                          (String v) => onChanged(
                            i,
                            items[i].copyWith(contractorRemarks: v),
                          ),
                        ),
                      ),
                      cell(
                        _columns[5].$2,
                        _remark(
                          'er-$i',
                          items[i].engineerRemark,
                          engineerEditable,
                          (String v) => onChanged(
                            i,
                            items[i].copyWith(engineerRemark: v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _status(
    BuildContext context,
    String key,
    String value,
    bool editable,
    ValueChanged<String> onPicked,
  ) {
    final String current = value.toUpperCase();
    if (!editable) {
      return Text(
        current.isEmpty ? 'Not Updated' : current,
        style: const TextStyle(fontWeight: FontWeight.w600),
      );
    }
    return DropdownButtonFormField<String>(
      key: ValueKey<String>(key),
      initialValue: statusOptions.contains(current) ? current : null,
      hint: const Text('Select'),
      isExpanded: true,
      items: statusOptions
          .map((String o) => DropdownMenuItem<String>(value: o, child: Text(o)))
          .toList(),
      onChanged: (String? v) => onPicked(v ?? ''),
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
    );
  }

  Widget _remark(
    String key,
    String value,
    bool editable,
    ValueChanged<String> onEdited,
  ) {
    if (!editable) {
      return Text(value.isEmpty ? '—' : value);
    }
    return TextFormField(
      key: ValueKey<String>(key),
      initialValue: value,
      minLines: 1,
      maxLines: 3,
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'Remark',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      onChanged: onEdited,
    );
  }
}
