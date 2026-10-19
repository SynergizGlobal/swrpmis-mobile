import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/design/domain/design_form.dart';
import 'package:swr_pmis_mobile/src/features/design/domain/design_list.dart';
import 'package:swr_pmis_mobile/src/features/design/presentation/providers/design_form_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

class AddDesignFormPage extends ConsumerStatefulWidget {
  const AddDesignFormPage({
    super.key,
    this.designId = '',
    this.prefill = DesignFormPrefill.empty,
  });

  final String designId;
  final DesignFormPrefill prefill;

  static const String routeName = 'add-design-form';
  static const String routePath = '/module/design/add';

  static String location({String designId = ''}) {
    final String id = designId.trim();
    if (id.isEmpty) {
      return routePath;
    }
    return Uri(
      path: routePath,
      queryParameters: <String, String>{'designId': id},
    ).toString();
  }

  static DesignFormPrefill prefillFromExtra(Object? extra) {
    if (extra is DesignFormPrefill) {
      return extra;
    }
    if (extra is DesignRow) {
      return DesignFormPrefill.fromRow(extra);
    }
    return DesignFormPrefill.empty;
  }

  @override
  ConsumerState<AddDesignFormPage> createState() => _AddDesignFormPageState();
}

class _AddDesignFormPageState extends ConsumerState<AddDesignFormPage> {
  static const int _titleMaxChars = 200;
  static const int _remarksMaxChars = 1000;

  final TextEditingController _componentDetail = TextEditingController();
  final TextEditingController _consultant = TextEditingController();
  final TextEditingController _proofConsultant = TextEditingController();
  final TextEditingController _structureText = TextEditingController();
  final TextEditingController _drawingTitle = TextEditingController();
  final TextEditingController _agencyDrawingNo = TextEditingController();
  final TextEditingController _swrDrawingNo = TextEditingController();
  final TextEditingController _divisionalDrawingNo = TextEditingController();
  final TextEditingController _hqDrawingNo = TextEditingController();
  final TextEditingController _remarks = TextEditingController();

  DesignFormMaster _master = DesignFormMaster.empty;
  bool _seeded = false;
  bool _reportedLoadError = false;

  String _projectId = '';
  String _approvingRailwayId = '';
  String _contractId = '';
  String _structureTypeId = '';
  String _structureId = '';
  String _preparedById = '';
  String _drawingTypeId = '';
  String _approvalAuthorityId = '';
  DateTime? _requiredDate;
  DateTime? _gfcReleaseDate;
  bool _showLatest = false;
  List<DesignStatusRowDraft> _statusRows = <DesignStatusRowDraft>[
    const DesignStatusRowDraft(),
  ];

  /// Structures from list prefill only until a structure lookup API exists.
  List<DesignFormOption> _structureOptions = const <DesignFormOption>[];

  String get _designId {
    final String fromWidget = widget.designId.trim();
    if (fromWidget.isNotEmpty) {
      return fromWidget;
    }
    return widget.prefill.designId.trim();
  }

  bool get _editing => _designId.isNotEmpty;

  bool get _structureFromCatalog => _structureOptions.isNotEmpty;

  String get _resolvedStructureId =>
      _structureFromCatalog ? _structureId : _structureText.text.trim();

  @override
  void dispose() {
    _componentDetail.dispose();
    _consultant.dispose();
    _proofConsultant.dispose();
    _structureText.dispose();
    _drawingTitle.dispose();
    _agencyDrawingNo.dispose();
    _swrDrawingNo.dispose();
    _divisionalDrawingNo.dispose();
    _hqDrawingNo.dispose();
    _remarks.dispose();
    super.dispose();
  }

  void _seed(DesignFormMaster master) {
    if (_seeded) {
      return;
    }
    final DesignFormPrefill seed = widget.prefill;
    final String structureTypeId = _match(master.structureTypes, seed.structureType);
    final String drawingTypeId = _match(master.drawingTypes, seed.drawingType);
    final List<DesignFormOption> structures = <DesignFormOption>[
      if (seed.structure.isNotEmpty)
        DesignFormOption(id: seed.structure, label: seed.structure),
    ];
    _drawingTitle.text = seed.title;
    _structureText.text = seed.structure;
    if (seed.drawingNo.isNotEmpty) {
      _agencyDrawingNo.text = seed.drawingNo;
    }
    setState(() {
      _seeded = true;
      _master = master;
      _structureTypeId = structureTypeId;
      _structureId = seed.structure.isEmpty
          ? ''
          : _match(structures, seed.structure);
      _structureOptions = structures;
      _drawingTypeId = drawingTypeId;
      _statusRows = <DesignStatusRowDraft>[
        DesignStatusRowDraft(
          drawingNo: seed.drawingNo,
          isLatest: true,
        ),
      ];
    });
  }

  String _match(List<DesignFormOption> options, String raw) {
    if (raw.isEmpty) {
      return '';
    }
    for (final DesignFormOption option in options) {
      if (option.id == raw || option.label == raw) {
        return option.id;
      }
    }
    return raw;
  }

  void _reportLoadError(Object error) {
    if (!mounted || _reportedLoadError) {
      return;
    }
    _reportedLoadError = true;
    final String message = error is DioException
        ? userFriendlyErrorMessage(error)
        : 'Could not load the design form. Please try again.';
    AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: 'Load Failed',
      message: message,
    );
  }

  void _retry() {
    setState(() {
      _reportedLoadError = false;
      _seeded = false;
    });
    ref.invalidate(designFormMasterProvider);
  }

  void _selectStructureType(String id) {
    if (id == _structureTypeId) {
      return;
    }
    setState(() {
      _structureTypeId = id;
      // Structure lookup API not wired; clear selection when type changes.
      _structureId = '';
      _structureText.clear();
      _structureOptions = const <DesignFormOption>[];
    });
  }

  List<DesignFormOption> _withId(
    List<DesignFormOption> options,
    String id,
  ) {
    if (id.isEmpty ||
        options.any((DesignFormOption option) => option.id == id)) {
      return options;
    }
    return <DesignFormOption>[
      DesignFormOption(id: id, label: id),
      ...options,
    ];
  }

  String? _labelOf(List<DesignFormOption> options, String id) {
    if (id.isEmpty) {
      return null;
    }
    for (final DesignFormOption option in options) {
      if (option.id == id) {
        return option.label;
      }
    }
    return id;
  }

  Future<void> _submit() async {
    final String? message = validateDesignForm(
      projectId: _projectId,
      approvingRailwayId: _approvingRailwayId,
      structureTypeId: _structureTypeId,
      structureId: _resolvedStructureId,
      drawingTypeId: _drawingTypeId,
      approvalAuthorityId: _approvalAuthorityId,
      drawingTitle: _drawingTitle.text,
      statusRows: _statusRows,
    );
    if (message != null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: 'Required',
        message: message,
      );
      return;
    }
    if (!mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: _editing ? 'Update' : 'Add',
      message:
          'Save is not yet connected. The form was checked on this device and was not sent to the server.',
    );
  }

  void _addStatusRow() {
    setState(() {
      _statusRows = <DesignStatusRowDraft>[
        ..._statusRows,
        const DesignStatusRowDraft(),
      ];
    });
  }

  void _removeStatusRow(int index) {
    if (_statusRows.length <= 1) {
      setState(() {
        _statusRows = <DesignStatusRowDraft>[const DesignStatusRowDraft()];
      });
      return;
    }
    setState(() {
      _statusRows = <DesignStatusRowDraft>[
        for (int i = 0; i < _statusRows.length; i++)
          if (i != index) _statusRows[i],
      ];
    });
  }

  void _updateStatusRow(int index, DesignStatusRowDraft row) {
    setState(() {
      _statusRows = <DesignStatusRowDraft>[
        for (int i = 0; i < _statusRows.length; i++)
          if (i == index) row else _statusRows[i],
      ];
    });
  }

  Future<void> _pickStatusFile(int index) async {
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
    );
    final PlatformFile? file = picked?.files.single;
    final String? path = file?.path;
    if (path == null || path.isEmpty) {
      return;
    }
    final String name = (file?.name.trim().isNotEmpty ?? false)
        ? file!.name
        : p.basename(path);
    _updateStatusRow(
      index,
      _statusRows[index].copyWith(localFilePath: path, localFileName: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<DesignFormMaster> masterAsync = ref.watch(
      designFormMasterProvider,
    );
    final Object? loadError = masterAsync.hasError ? masterAsync.error : null;
    final bool ready = loadError == null && masterAsync.hasValue;
    if (loadError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _reportLoadError(loadError);
        }
      });
    } else if (ready && !_seeded) {
      final DesignFormMaster master = masterAsync.requireValue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _seeded) {
          return;
        }
        _seed(master);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit Design & Drawing' : 'Add Design & Drawing'),
      ),
      body: loadError != null
          ? _ErrorBody(onRetry: _retry)
          : !ready || !_seeded
          ? const Center(child: CircularProgressIndicator())
          : _form(),
    );
  }

  Widget _form() {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: <Widget>[
              _Section(
                title: 'Work Details',
                children: <Widget>[
                  _dropdown(
                    label: 'Project *',
                    options: _withId(_master.projects, _projectId),
                    selectedId: _projectId,
                    onPick: (String id) => setState(() => _projectId = id),
                  ),
                  _dropdown(
                    label: 'Approving Railway *',
                    options: _withId(
                      designApprovingRailways,
                      _approvingRailwayId,
                    ),
                    selectedId: _approvingRailwayId,
                    onPick: (String id) =>
                        setState(() => _approvingRailwayId = id),
                  ),
                  _dropdown(
                    label: 'Contract',
                    options: _withId(_master.contracts, _contractId),
                    selectedId: _contractId,
                    onPick: (String id) => setState(() => _contractId = id),
                  ),
                  _dropdown(
                    label: 'Structure Type *',
                    options: _withId(_master.structureTypes, _structureTypeId),
                    selectedId: _structureTypeId,
                    onPick: _selectStructureType,
                  ),
                  if (_structureFromCatalog)
                    _dropdown(
                      label: 'Structure *',
                      options: _withId(_structureOptions, _structureId),
                      selectedId: _structureId,
                      enabled: _structureTypeId.isNotEmpty,
                      onPick: (String id) => setState(() => _structureId = id),
                    )
                  else
                    IgnorePointer(
                      ignoring: _structureTypeId.isEmpty,
                      child: Opacity(
                        opacity: _structureTypeId.isEmpty ? 0.5 : 1,
                        child: _text(
                          _structureText,
                          label: 'Structure *',
                        ),
                      ),
                    ),
                  _text(_componentDetail, label: 'Component Detail'),
                  _dropdown(
                    label: 'Prepared By',
                    options: _withId(designPreparedByOptions, _preparedById),
                    selectedId: _preparedById,
                    onPick: (String id) => setState(() => _preparedById = id),
                  ),
                  _text(_consultant, label: 'Consultant'),
                  _text(_proofConsultant, label: 'Proof Consultant'),
                  _dropdown(
                    label: 'Drawing Type *',
                    options: _withId(_master.drawingTypes, _drawingTypeId),
                    selectedId: _drawingTypeId,
                    onPick: (String id) => setState(() => _drawingTypeId = id),
                  ),
                  _dropdown(
                    label: 'Approval Authority *',
                    options: _withId(
                      designApprovalAuthorities,
                      _approvalAuthorityId,
                    ),
                    selectedId: _approvalAuthorityId,
                    onPick: (String id) =>
                        setState(() => _approvalAuthorityId = id),
                  ),
                  _dateField(
                    label: 'Required Date',
                    value: _requiredDate,
                    onPick: (DateTime? date) =>
                        setState(() => _requiredDate = date),
                  ),
                  _dateField(
                    label: 'GFC Release Date',
                    value: _gfcReleaseDate,
                    onPick: (DateTime? date) =>
                        setState(() => _gfcReleaseDate = date),
                  ),
                ],
              ),
              _Section(
                title: 'Drawing Details',
                children: <Widget>[
                  _text(
                    _drawingTitle,
                    label: 'Drawing Title *',
                    maxLines: 3,
                    maxLength: _titleMaxChars,
                  ),
                  _text(_agencyDrawingNo, label: 'Agency Drawing No'),
                  _text(_swrDrawingNo, label: 'SWR Drawing No'),
                  _text(_divisionalDrawingNo, label: 'Divisional Drawing No'),
                  _text(_hqDrawingNo, label: 'HQ Drawing No'),
                ],
              ),
              _Section(
                title: 'Drawing Status',
                children: <Widget>[
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _showLatest,
                    onChanged: (bool? value) {
                      setState(() => _showLatest = value ?? false);
                    },
                    title: const Text('Show Latest'),
                  ),
                  for (int i = 0; i < _statusRows.length; i++)
                    _StatusRowCard(
                      index: i,
                      row: _statusRows[i],
                      canDelete: _statusRows.length > 1,
                      onChanged: (DesignStatusRowDraft row) =>
                          _updateStatusRow(i, row),
                      onDelete: () => _removeStatusRow(i),
                      onPickFile: () => _pickStatusFile(i),
                      onClearFile: () {
                        _updateStatusRow(
                          i,
                          _statusRows[i].copyWith(
                            localFilePath: '',
                            localFileName: '',
                          ),
                        );
                      },
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addStatusRow,
                      icon: Icon(
                        Icons.add_circle_rounded,
                        color: AppPalette.of(context).success,
                      ),
                      label: Text(
                        'Add row',
                        style: TextStyle(color: AppPalette.of(context).success),
                      ),
                    ),
                  ),
                  _text(
                    _remarks,
                    label: 'Remarks',
                    maxLines: 4,
                    maxLength: _remarksMaxChars,
                  ),
                ],
              ),
            ],
          ),
        ),
        _actions(),
      ],
    );
  }

  Widget _actions() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _submit,
                child: Text(_editing ? 'Update' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required List<DesignFormOption> options,
    required String selectedId,
    required ValueChanged<String> onPick,
    bool enabled = true,
  }) {
    final String? value = _labelOf(options, selectedId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 56,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: RfiFilterField(
              label: label,
              emptyLabel: 'Select',
              value: value,
              options: <RfiFilterOption>[
                for (final DesignFormOption option in options)
                  RfiFilterOption(id: option.id, label: option.label),
              ],
              selectedId: selectedId.isEmpty ? null : selectedId,
              onClear: !enabled || selectedId.isEmpty ? null : () => onPick(''),
              onPick: (RfiFilterOption option) => onPick(option.id),
            ),
          ),
        ),
      ),
    );
  }

  Widget _text(
    TextEditingController controller, {
    required String label,
    String? hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        textInputAction: maxLines == 1
            ? TextInputAction.next
            : TextInputAction.newline,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onPick,
  }) {
    final String text = value == null
        ? 'Select'
        : DateFormat('dd/MM/yyyy').format(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: () async {
          final DateTime now = DateTime.now();
          final DateTime? picked = await showDatePicker(
            context: context,
            useRootNavigator: true,
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 15),
            lastDate: DateTime(now.year + 15),
          );
          if (picked != null) {
            onPick(DateTime(picked.year, picked.month, picked.day));
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: value == null
                ? const Icon(Icons.calendar_today_outlined, size: 18)
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: () => onPick(null),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
          ),
          child: Text(text),
        ),
      ),
    );
  }
}

class _StatusRowCard extends StatelessWidget {
  const _StatusRowCard({
    required this.index,
    required this.row,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
    required this.onPickFile,
    required this.onClearFile,
  });

  final int index;
  final DesignStatusRowDraft row;
  final bool canDelete;
  final ValueChanged<DesignStatusRowDraft> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Status row ${index + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Delete row',
                onPressed: canDelete ? onDelete : null,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: canDelete ? AppTheme.railwayRed : palette.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _StatusTextField(
            label: 'Drawing No *',
            value: row.drawingNo,
            onChanged: (String value) => onChanged(row.copyWith(drawingNo: value)),
          ),
          _StatusDropdown(
            label: 'Stage',
            options: designStageOptions,
            selectedId: row.stageId,
            onPick: (String id) => onChanged(row.copyWith(stageId: id)),
          ),
          Text(
            'Submitted By',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          _StatusTextField(
            label: 'Organisation',
            value: row.submittedByOrg,
            onChanged: (String value) =>
                onChanged(row.copyWith(submittedByOrg: value)),
          ),
          _StatusTextField(
            label: 'Department',
            value: row.submittedByDept,
            onChanged: (String value) =>
                onChanged(row.copyWith(submittedByDept: value)),
          ),
          _StatusTextField(
            label: 'Official',
            value: row.submittedByOfficial,
            onChanged: (String value) =>
                onChanged(row.copyWith(submittedByOfficial: value)),
          ),
          Text(
            'Submitted To',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          _StatusTextField(
            label: 'Organisation',
            value: row.submittedToOrg,
            onChanged: (String value) =>
                onChanged(row.copyWith(submittedToOrg: value)),
          ),
          _StatusTextField(
            label: 'Department',
            value: row.submittedToDept,
            onChanged: (String value) =>
                onChanged(row.copyWith(submittedToDept: value)),
          ),
          _StatusTextField(
            label: 'Official',
            value: row.submittedToOfficial,
            onChanged: (String value) =>
                onChanged(row.copyWith(submittedToOfficial: value)),
          ),
          _StatusTextField(
            label: 'Purpose of Submission',
            value: row.purpose,
            onChanged: (String value) => onChanged(row.copyWith(purpose: value)),
          ),
          _StatusTextField(
            label: 'Correspondence',
            value: row.correspondence,
            onChanged: (String value) =>
                onChanged(row.copyWith(correspondence: value)),
          ),
          _StatusTextField(
            label: 'Remarks',
            value: row.remarks,
            maxLines: 2,
            onChanged: (String value) => onChanged(row.copyWith(remarks: value)),
          ),
          _StatusDateField(
            label: 'Submitted Date',
            value: row.submittedDate,
            onPick: (DateTime? date) {
              onChanged(
                date == null
                    ? row.copyWith(clearSubmittedDate: true)
                    : row.copyWith(submittedDate: date),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    row.localFileName.isEmpty
                        ? 'No file selected'
                        : row.localFileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (row.localFileName.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear file',
                    onPressed: onClearFile,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                TextButton.icon(
                  onPressed: onPickFile,
                  icon: const Icon(Icons.attach_file_rounded, size: 18),
                  label: const Text('Upload File'),
                ),
              ],
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: row.isLatest,
            onChanged: (bool? value) {
              onChanged(row.copyWith(isLatest: value ?? false));
            },
            title: const Text('Latest'),
          ),
        ],
      ),
    );
  }
}

class _StatusTextField extends StatefulWidget {
  const _StatusTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  State<_StatusTextField> createState() => _StatusTextFieldState();
}

class _StatusTextFieldState extends State<_StatusTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _StatusTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _controller,
        maxLines: widget.maxLines,
        onChanged: widget.onChanged,
        decoration: InputDecoration(labelText: widget.label),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.label,
    required this.options,
    required this.selectedId,
    required this.onPick,
  });

  final String label;
  final List<DesignFormOption> options;
  final String selectedId;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    String? value;
    for (final DesignFormOption option in options) {
      if (option.id == selectedId) {
        value = option.label;
        break;
      }
    }
    value ??= selectedId.isEmpty ? null : selectedId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 56,
        child: RfiFilterField(
          label: label,
          emptyLabel: 'Select',
          value: value,
          options: <RfiFilterOption>[
            for (final DesignFormOption option in options)
              RfiFilterOption(id: option.id, label: option.label),
          ],
          selectedId: selectedId.isEmpty ? null : selectedId,
          onClear: selectedId.isEmpty ? null : () => onPick(''),
          onPick: (RfiFilterOption option) => onPick(option.id),
        ),
      ),
    );
  }
}

class _StatusDateField extends StatelessWidget {
  const _StatusDateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPick;

  @override
  Widget build(BuildContext context) {
    final String text = value == null
        ? 'Select'
        : DateFormat('dd/MM/yyyy').format(value!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: () async {
          final DateTime now = DateTime.now();
          final DateTime? picked = await showDatePicker(
            context: context,
            useRootNavigator: true,
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 15),
            lastDate: DateTime(now.year + 15),
          );
          if (picked != null) {
            onPick(DateTime(picked.year, picked.month, picked.day));
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: value == null
                ? const Icon(Icons.calendar_today_outlined, size: 18)
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: () => onPick(null),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
          ),
          child: Text(text),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.mutedText,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Could not load the design form.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
