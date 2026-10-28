import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/projects/data/datasources/project_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/projects/domain/project_form.dart';
import 'package:swr_pmis_mobile/src/features/projects/domain/project_list.dart';
import 'package:swr_pmis_mobile/src/features/projects/presentation/providers/project_form_provider.dart';
import 'package:swr_pmis_mobile/src/features/projects/presentation/providers/projects_provider.dart';

class AddProjectFormPage extends ConsumerStatefulWidget {
  const AddProjectFormPage({
    super.key,
    this.projectId = '',
    this.prefill = ProjectFormPrefill.empty,
  });

  final String projectId;
  final ProjectFormPrefill prefill;

  static const String routeName = 'add-project-form';
  static const String routePath = '/module/projects/add';

  static String location({String projectId = ''}) {
    final String id = projectId.trim();
    if (id.isEmpty) {
      return routePath;
    }
    return Uri(
      path: routePath,
      queryParameters: <String, String>{'projectId': id},
    ).toString();
  }

  static ProjectFormPrefill prefillFromExtra(Object? extra) {
    if (extra is ProjectFormPrefill) {
      return extra;
    }
    if (extra is ProjectRow) {
      return ProjectFormPrefill.fromRow(extra);
    }
    return ProjectFormPrefill.empty;
  }

  @override
  ConsumerState<AddProjectFormPage> createState() => _AddProjectFormPageState();
}

class _AddProjectFormPageState extends ConsumerState<AddProjectFormPage> {
  static const int _textMaxChars = 1000;
  static final DateFormat _displayDate = DateFormat('dd/MM/yyyy');

  final TextEditingController _name = TextEditingController();
  final TextEditingController _planHead = TextEditingController();
  final TextEditingController _sanctionedAmount = TextEditingController();
  final TextEditingController _fromChainage = TextEditingController();
  final TextEditingController _toChainage = TextEditingController();
  final TextEditingController _pbItem = TextEditingController();
  final TextEditingController _actualCost = TextEditingController();
  final TextEditingController _proposedLength = TextEditingController();
  final TextEditingController _benefits = TextEditingController();
  final TextEditingController _remarks = TextEditingController();

  final List<_BlockDraft> _blocks = <_BlockDraft>[];
  final List<_CostDraft> _costs = <_CostDraft>[];

  ProjectFormMaster _master = ProjectFormMaster.empty;
  List<ProjectOption> _zoneDivisions = const <ProjectOption>[];
  bool _seeded = false;
  bool _reportedLoadError = false;
  bool _saving = false;
  bool _checkingName = false;
  bool _uploadingKmz = false;
  String? _nameExistsError;
  String _originalName = '';

  String _status = '';
  String _typeId = '';
  String _railwayZone = '';
  String _sanctionedYear = '';
  String _divisionId = '';
  String _sectionId = '';
  DateTime? _sanctionedDate;
  DateTime? _actualCompletionDate;
  String? _pendingKmzPath;
  String? _pendingKmzName;

  String get _projectId => widget.projectId.trim();

  bool get _editing => _projectId.isNotEmpty;

  ProjectRow? get _prefillRow {
    final ProjectRow? fromExtra = widget.prefill.row;
    if (fromExtra != null) {
      return fromExtra;
    }
    if (!_editing) {
      return null;
    }
    final List<ProjectRow> rows = ref
        .read(projectsControllerProvider)
        .snapshot
        .rows;
    for (final ProjectRow row in rows) {
      if (row.projectId == _projectId) {
        return row;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _name.dispose();
    _planHead.dispose();
    _sanctionedAmount.dispose();
    _fromChainage.dispose();
    _toChainage.dispose();
    _pbItem.dispose();
    _actualCost.dispose();
    _proposedLength.dispose();
    _benefits.dispose();
    _remarks.dispose();
    for (final _BlockDraft draft in _blocks) {
      draft.dispose();
    }
    for (final _CostDraft draft in _costs) {
      draft.dispose();
    }
    super.dispose();
  }

  String _match(List<ProjectOption> options, String raw) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    for (final ProjectOption option in options) {
      if (option.value == value ||
          option.label.toLowerCase() == value.toLowerCase()) {
        return option.value;
      }
    }
    return value;
  }

  Future<void> _seed(ProjectFormMaster master) async {
    if (_seeded) {
      return;
    }
    _master = master;
    final ProjectRow? row = _prefillRow;
    if (row != null) {
      _originalName = row.projectName;
      _name.text = row.projectName;
      _status = _match(projectStatusOptions, row.projectStatus);
      _typeId = _match(master.projectTypes, row.projectTypeId.isNotEmpty
          ? row.projectTypeId
          : row.projectTypeName);
      _railwayZone = _match(master.railwayZones, row.railwayZone);
      _planHead.text = row.planHeadNumber;
      _sanctionedYear = _match(master.years, row.sanctionedYear);
      _sanctionedAmount.text = row.sanctionedAmount;
      _sanctionedDate = parseProjectFormDate(row.sanctionedCommissioningDate);
      _fromChainage.text = row.fromChainage;
      _toChainage.text = row.toChainage;
      _pbItem.text = row.pbItemNumber;
      _actualCost.text = row.actualCompletionCost;
      _actualCompletionDate = parseProjectFormDate(row.actualCompletionDate);
      _proposedLength.text = row.proposedLength;
      _benefits.text = row.benefits;
      _remarks.text = row.remarks;
      _divisionId = row.divisionId;
      _sectionId = row.sectionId;
      for (final ProjectBlockSectionRow block in row.blockSections) {
        _blocks.add(
          _BlockDraft(
            name: block.name,
            from: block.fromChainage,
            to: block.toChainage,
            commissioningDate: block.commissioningDate,
          ),
        );
      }
      for (final ProjectCompletionCostRow cost in row.completionCosts) {
        _costs.add(
          _CostDraft(
            date: parseProjectFormDate(cost.date),
            estimatedCost: cost.estimatedCost ?? '',
            revisedDate: parseProjectFormDate(cost.revisedDate),
          ),
        );
      }
    }
    if (_blocks.isEmpty) {
      _blocks.add(_BlockDraft());
    }
    if (_costs.isEmpty) {
      _costs.add(_CostDraft());
    }
    _seeded = true;
    if (mounted) {
      setState(() {});
    }
    if (_railwayZone.isNotEmpty) {
      await _loadZoneDivisions(_railwayZone, preserveSelection: true);
    }
  }

  Future<void> _reportLoadError(Object error) async {
    if (_reportedLoadError || !mounted) {
      return;
    }
    _reportedLoadError = true;
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: _editing ? 'Edit Project' : 'Add Project',
      message: error is DioException
          ? userFriendlyErrorMessage(error)
          : error.toString(),
    );
  }

  Future<void> _retry() {
    _reportedLoadError = false;
    ref.invalidate(projectFormMasterProvider);
    return Future<void>.value();
  }

  Future<void> _loadZoneDivisions(
    String zone, {
    required bool preserveSelection,
  }) async {
    final String previousDivision = _divisionId;
    final String previousSection = _sectionId;
    try {
      final List<ProjectOption> divisions = await ref
          .read(projectRemoteDataSourceProvider)
          .fetchDivisionsForZone(zone);
      if (!mounted) {
        return;
      }
      setState(() {
        _zoneDivisions = divisions.isNotEmpty ? divisions : _master.divisions;
        if (preserveSelection) {
          _divisionId = _match(_zoneDivisions, previousDivision);
          _sectionId = previousSection;
        } else {
          _divisionId = '';
          _sectionId = '';
        }
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _zoneDivisions = _master.divisions;
        if (!preserveSelection) {
          _divisionId = '';
          _sectionId = '';
        }
      });
    }
  }

  List<ProjectOption> get _sectionOptions {
    final String divisionId = _divisionId.trim();
    if (divisionId.isEmpty) {
      return _master.sections;
    }
    final List<ProjectOption> filtered = _master.sections
        .where(
          (ProjectOption option) =>
              (option.meta ?? '').isEmpty || option.meta == divisionId,
        )
        .toList(growable: false);
    return filtered.isEmpty ? _master.sections : filtered;
  }

  Future<void> _onNameBlur() async {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameExistsError = null);
      return;
    }
    if (_editing &&
        name.toLowerCase() == _originalName.trim().toLowerCase()) {
      setState(() => _nameExistsError = null);
      return;
    }
    setState(() => _checkingName = true);
    try {
      final bool exists = await ref
          .read(projectRemoteDataSourceProvider)
          .checkProjectName(name);
      if (!mounted) {
        return;
      }
      setState(() {
        _nameExistsError = exists ? 'Project name already exists.' : null;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _nameExistsError = null);
    } finally {
      if (mounted) {
        setState(() => _checkingName = false);
      }
    }
  }

  String? _validationMessage() {
    if (_name.text.trim().isEmpty) {
      return 'Please enter a project name.';
    }
    if (_nameExistsError != null) {
      return _nameExistsError;
    }
    if (_status.trim().isEmpty) {
      return 'Please select a project status.';
    }
    if (_typeId.trim().isEmpty) {
      return 'Please select a project type.';
    }
    if (_railwayZone.trim().isEmpty) {
      return 'Please select a railway zone.';
    }
    if (_planHead.text.trim().isEmpty) {
      return 'Please enter a plan head number.';
    }
    if (_sanctionedYear.trim().isEmpty) {
      return 'Please select a sanctioned year.';
    }
    if (parseProjectNumber(_sanctionedAmount.text) == null) {
      return 'Please enter a valid sanctioned amount.';
    }
    if (_sanctionedDate == null) {
      return 'Please select a sanctioned commissioning date.';
    }
    return null;
  }

  Map<String, dynamic> _buildPayload() {
    final List<String> blockNames = <String>[];
    final List<String> blockFrom = <String>[];
    final List<String> blockTo = <String>[];
    final List<dynamic> blockDates = <dynamic>[];
    for (final _BlockDraft draft in _blocks) {
      final String name = draft.name.text.trim();
      final String from = draft.from.text.trim();
      final String to = draft.to.text.trim();
      if (name.isEmpty && from.isEmpty && to.isEmpty) {
        continue;
      }
      blockNames.add(name);
      blockFrom.add(from);
      blockTo.add(to);
      blockDates.add(draft.commissioningDate);
    }
    final List<dynamic> completionDates = <dynamic>[];
    final List<dynamic> estimatedCosts = <dynamic>[];
    final List<dynamic> revisedDates = <dynamic>[];
    for (final _CostDraft draft in _costs) {
      final String cost = draft.estimatedCost.text.trim();
      if (draft.date == null && cost.isEmpty && draft.revisedDate == null) {
        continue;
      }
      completionDates.add(
        draft.date == null ? null : formatProjectApiDate(draft.date),
      );
      estimatedCosts.add(parseProjectNumber(cost));
      revisedDates.add(
        draft.revisedDate == null
            ? null
            : formatProjectApiDate(draft.revisedDate),
      );
    }
    if (completionDates.isEmpty) {
      completionDates.add(null);
      estimatedCosts.add(null);
      revisedDates.add(null);
    }
    final Map<String, dynamic> body = <String, dynamic>{
      'project_name': _name.text.trim(),
      'plan_head_number': _planHead.text.trim(),
      'project_status': _status.trim(),
      'project_type_id': _typeId.trim(),
      'railway_zone': _railwayZone.trim(),
      'pb_item_number': _nullableString(_pbItem.text),
      'sanctioned_year': _sanctionedYear.trim(),
      'sanctioned_amount': parseProjectNumber(_sanctionedAmount.text),
      'sanctioned_commissioning_date': formatProjectApiDate(_sanctionedDate),
      'actual_completion_cost': parseProjectNumber(_actualCost.text),
      'actual_completion_date': _actualCompletionDate == null
          ? null
          : formatProjectApiDate(_actualCompletionDate),
      'benefits': _nullableString(_benefits.text),
      'remarks': _nullableString(_remarks.text),
      'division_id': _nullableString(_divisionId),
      'section_id': _nullableString(_sectionId),
      'from_chainage': parseProjectNumber(_fromChainage.text),
      'to_chainage': parseProjectNumber(_toChainage.text),
      'proposed_length': _nullableString(_proposedLength.text),
      'block_section_names': blockNames,
      'block_from_chainages': blockFrom,
      'block_to_chainages': blockTo,
      'block_commissioning_dates': blockDates.isEmpty
          ? <dynamic>[null]
          : blockDates,
      'completion_dates': completionDates,
      'estimated_completion_costs': estimatedCosts,
      'revised_completion_dates': revisedDates,
      'financial_years': <dynamic>[null],
      'railways': <dynamic>[null],
      'pink_book_item_numbers': <dynamic>[null],
    };
    if (_editing) {
      body['project_id'] = _projectId;
    }
    return body;
  }

  String? _nullableString(String raw) {
    final String text = raw.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    if (_saving || _uploadingKmz) {
      return;
    }
    await _onNameBlur();
    if (!mounted) {
      return;
    }
    final String? message = _validationMessage();
    if (message != null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: 'Required',
        message: message,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final ProjectRemoteDataSource remote = ref.read(
        projectRemoteDataSourceProvider,
      );
      final Map<String, dynamic> body = _buildPayload();
      final String result = _editing
          ? await remote.updateProject(projectId: _projectId, body: body)
          : await remote.addProject(body);
      if (_editing &&
          _pendingKmzPath != null &&
          _pendingKmzPath!.isNotEmpty) {
        await remote.uploadChainages(
          projectId: _projectId,
          filePath: _pendingKmzPath!,
        );
      }
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: _editing ? 'Update Project' : 'Add Project',
        message: result,
      );
      if (!mounted) {
        return;
      }
      context.pop(true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: _editing ? 'Update Project' : 'Add Project',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error is StateError
            ? error.message
            : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _downloadKmzTemplate() async {
    await AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: 'Download Template',
      message:
          'KMZ / chainage template download API is not available yet.',
    );
  }

  Future<void> _uploadKmz() async {
    if (_uploadingKmz || _saving) {
      return;
    }
    if (!_editing) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: 'Upload',
        message:
            'Save the project first, then open Edit to upload a KMZ / chainage file.',
      );
      return;
    }
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['kmz', 'kml', 'xlsx', 'xls', 'csv'],
      withData: false,
    );
    final String? path = picked?.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }
    final String name = (picked?.files.single.name.trim().isNotEmpty ?? false)
        ? picked!.files.single.name
        : p.basename(path);
    setState(() {
      _pendingKmzPath = path;
      _pendingKmzName = name;
      _uploadingKmz = true;
    });
    try {
      final String message = await ref
          .read(projectRemoteDataSourceProvider)
          .uploadChainages(projectId: _projectId, filePath: path);
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Upload',
        message: message,
      );
      setState(() {
        _pendingKmzPath = null;
        _pendingKmzName = null;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Upload',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : error is StateError
            ? error.message
            : error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingKmz = false);
      }
    }
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: current ?? now,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 40),
    );
    if (picked == null) {
      return;
    }
    onPicked(DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProjectFormMaster> masterAsync = ref.watch(
      projectFormMasterProvider,
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
      final ProjectFormMaster master = masterAsync.requireValue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _seeded) {
          return;
        }
        _seed(master);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit Project' : 'Add Project')),
      body: loadError != null
          ? _ErrorBody(onRetry: _retry)
          : !ready || !_seeded
          ? const Center(child: CircularProgressIndicator())
          : _form(),
    );
  }

  Widget _form() {
    final bool busy = _saving || _uploadingKmz;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: <Widget>[
              _fieldGrid(<Widget>[
                _text(
                  _name,
                  label: 'Project Name *',
                  hint: 'Enter Value',
                  errorText: _nameExistsError,
                  onEditingComplete: _onNameBlur,
                  suffix: _checkingName
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                _dropdown(
                  label: 'Project Status *',
                  options: projectStatusOptions,
                  selectedId: _status,
                  onPick: (String id) => setState(() => _status = id),
                ),
                _dropdown(
                  label: 'Project Type *',
                  options: _master.projectTypes,
                  selectedId: _typeId,
                  onPick: (String id) => setState(() => _typeId = id),
                ),
                _dropdown(
                  label: 'Railway Zone *',
                  options: _master.railwayZones,
                  selectedId: _railwayZone,
                  onPick: (String id) async {
                    setState(() => _railwayZone = id);
                    await _loadZoneDivisions(id, preserveSelection: false);
                  },
                ),
                _text(
                  _planHead,
                  label: 'Plan Head Number *',
                  hint: 'Enter Value',
                ),
                _dropdown(
                  label: 'Sanctioned Year *',
                  options: _master.years,
                  selectedId: _sanctionedYear,
                  onPick: (String id) => setState(() => _sanctionedYear = id),
                ),
                _text(
                  _sanctionedAmount,
                  label: 'Sanctioned Amount *',
                  hint: 'Enter Value',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                _dateField(
                  label: 'Sanctioned Commissioning Date *',
                  value: _sanctionedDate,
                  onChanged: (DateTime? value) {
                    setState(() => _sanctionedDate = value);
                  },
                ),
                _text(
                  _fromChainage,
                  label: 'From Chainage',
                  hint: 'Enter From Chainage',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                _text(
                  _toChainage,
                  label: 'To Chainage',
                  hint: 'Enter To Chainage',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                _text(_pbItem, label: 'PB Item No', hint: 'Enter Value'),
                _text(
                  _actualCost,
                  label: 'Actual Completion Cost',
                  hint: 'Enter Value',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                _dateField(
                  label: 'Actual Completion Date',
                  value: _actualCompletionDate,
                  onChanged: (DateTime? value) {
                    setState(() => _actualCompletionDate = value);
                  },
                ),
                _text(
                  _proposedLength,
                  label: 'Proposed Length (km)',
                  hint: 'Enter Proposed Length',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                if (_zoneDivisions.isNotEmpty || _divisionId.isNotEmpty)
                  _dropdown(
                    label: 'Division',
                    options: _zoneDivisions.isNotEmpty
                        ? _zoneDivisions
                        : _master.divisions,
                    selectedId: _divisionId,
                    onPick: (String id) {
                      setState(() {
                        _divisionId = id;
                        _sectionId = '';
                      });
                    },
                  ),
                if (_master.sections.isNotEmpty || _sectionId.isNotEmpty)
                  _dropdown(
                    label: 'Section',
                    options: _sectionOptions,
                    selectedId: _sectionId,
                    onPick: (String id) => setState(() => _sectionId = id),
                  ),
              ]),
              const SizedBox(height: 8),
              _text(
                _benefits,
                label: 'Benefits',
                hint: 'Enter Benefits',
                maxLines: 4,
                maxLength: _textMaxChars,
              ),
              _text(
                _remarks,
                label: 'Remarks',
                hint: 'Enter Remarks',
                maxLines: 4,
                maxLength: _textMaxChars,
              ),
              const SizedBox(height: 8),
              _sectionTitle('Block Section Details'),
              _blockTable(),
              const SizedBox(height: 16),
              _sectionTitle('Completion Costs'),
              _costTable(),
              const SizedBox(height: 20),
              Text(
                'KMZ file / Chainage-wise Coordinates Upload',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_pendingKmzName != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Selected: $_pendingKmzName',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton(
                    onPressed: busy ? null : _downloadKmzTemplate,
                    child: const Text('Download Template'),
                  ),
                  FilledButton(
                    onPressed: busy ? null : _uploadKmz,
                    child: _uploadingKmz
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Upload'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_editing ? 'Update' : 'Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => context.pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.brandPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _fieldGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final int columns = maxWidth >= 900
            ? 3
            : maxWidth >= 560
            ? 2
            : 1;
        const double gap = 12;
        final double width = columns == 1
            ? maxWidth
            : (maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: 4,
          children: <Widget>[
            for (final Widget child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }

  Widget _text(
    TextEditingController controller, {
    required String label,
    String? hint,
    String? errorText,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    VoidCallback? onEditingComplete,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: keyboardType == null
            ? null
            : <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
              ],
        textInputAction: maxLines == 1
            ? TextInputAction.next
            : TextInputAction.newline,
        onEditingComplete: onEditingComplete,
        onChanged: (_) {
          if (errorText != null) {
            setState(() => _nameExistsError = null);
          }
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          alignLabelWithHint: maxLines > 1,
          suffixIcon: suffix == null
              ? null
              : Padding(padding: const EdgeInsets.all(12), child: suffix),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required List<ProjectOption> options,
    required String selectedId,
    required ValueChanged<String> onPick,
  }) {
    final String? value = selectedId.isEmpty
        ? null
        : options.any((ProjectOption option) => option.value == selectedId)
        ? selectedId
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey<String>('$label|$selectedId|${options.length}'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, hintText: 'Select'),
        items: <DropdownMenuItem<String>>[
          for (final ProjectOption option in options)
            DropdownMenuItem<String>(
              value: option.value,
              child: Text(option.label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (String? next) {
          if (next == null) {
            return;
          }
          onPick(next);
        },
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    final String text = value == null ? 'dd/mm/yyyy' : _displayDate.format(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: () => _pickDate(current: value, onPicked: onChanged),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: value == null
                  ? AppPalette.of(context).mutedText
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _blockTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _tableHeader(const <String>[
          'Block Section Name',
          'From Chainage (m)',
          'To Chainage (m)',
          'Action',
        ]),
        for (int i = 0; i < _blocks.length; i++)
          _tableRow(
            children: <Widget>[
              TextField(
                controller: _blocks[i].name,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Name',
                ),
              ),
              TextField(
                controller: _blocks[i].from,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'From',
                ),
              ),
              TextField(
                controller: _blocks[i].to,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'To',
                ),
              ),
              _deleteRowButton(() {
                setState(() {
                  _blocks[i].dispose();
                  _blocks.removeAt(i);
                  if (_blocks.isEmpty) {
                    _blocks.add(_BlockDraft());
                  }
                });
              }),
            ],
          ),
        const SizedBox(height: 8),
        Center(
          child: _addRowButton(() {
            setState(() => _blocks.add(_BlockDraft()));
          }),
        ),
      ],
    );
  }

  Widget _costTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _tableHeader(const <String>[
          'Date',
          'Estimated Completion Cost',
          'Revised Completion Date',
          'Action',
        ]),
        for (int i = 0; i < _costs.length; i++)
          _tableRow(
            children: <Widget>[
              _inlineDate(
                value: _costs[i].date,
                onChanged: (DateTime? value) {
                  setState(() => _costs[i].date = value);
                },
              ),
              TextField(
                controller: _costs[i].estimatedCost,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Estimated Cost',
                ),
              ),
              _inlineDate(
                value: _costs[i].revisedDate,
                onChanged: (DateTime? value) {
                  setState(() => _costs[i].revisedDate = value);
                },
              ),
              _deleteRowButton(() {
                setState(() {
                  _costs[i].dispose();
                  _costs.removeAt(i);
                  if (_costs.isEmpty) {
                    _costs.add(_CostDraft());
                  }
                });
              }),
            ],
          ),
        const SizedBox(height: 8),
        Center(
          child: _addRowButton(() {
            setState(() => _costs.add(_CostDraft()));
          }),
        ),
      ],
    );
  }

  Widget _tableHeader(List<String> labels) {
    return Container(
      color: AppTheme.brandPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++)
            Expanded(
              flex: i == labels.length - 1 ? 1 : 3,
              child: Text(
                labels[i],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableRow({required List<Widget> children}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppPalette.of(context).borderSubtle),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            for (int i = 0; i < children.length; i++)
              Expanded(
                flex: i == children.length - 1 ? 1 : 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: children[i],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _inlineDate({
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return InkWell(
      onTap: () => _pickDate(current: value, onPicked: onChanged),
      child: InputDecorator(
        decoration: const InputDecoration(
          isDense: true,
          suffixIcon: Icon(Icons.calendar_today_rounded, size: 16),
        ),
        child: Text(
          value == null ? 'dd/mm/yyyy' : _displayDate.format(value),
          style: TextStyle(
            fontSize: 13,
            color: value == null
                ? AppPalette.of(context).mutedText
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _deleteRowButton(VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: 'Remove',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFC1121F),
          foregroundColor: Colors.white,
          minimumSize: const Size(36, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: const Icon(Icons.delete_outline_rounded, size: 18),
      ),
    );
  }

  Widget _addRowButton(VoidCallback onPressed) {
    return IconButton(
      tooltip: 'Add row',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppPalette.of(context).success,
        foregroundColor: Colors.white,
        minimumSize: const Size(40, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.playlist_add_rounded),
    );
  }
}

class _BlockDraft {
  _BlockDraft({
    String name = '',
    String from = '',
    String to = '',
    this.commissioningDate,
  }) : name = TextEditingController(text: name),
       from = TextEditingController(text: from),
       to = TextEditingController(text: to);

  final TextEditingController name;
  final TextEditingController from;
  final TextEditingController to;
  final String? commissioningDate;

  void dispose() {
    name.dispose();
    from.dispose();
    to.dispose();
  }
}

class _CostDraft {
  _CostDraft({
    this.date,
    String estimatedCost = '',
    this.revisedDate,
  }) : estimatedCost = TextEditingController(text: estimatedCost);

  DateTime? date;
  final TextEditingController estimatedCost;
  DateTime? revisedDate;

  void dispose() {
    estimatedCost.dispose();
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
              'Could not load the project form.',
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
