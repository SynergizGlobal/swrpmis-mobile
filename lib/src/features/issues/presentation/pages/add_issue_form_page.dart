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
import 'package:swr_pmis_mobile/src/features/issues/domain/issue_form.dart';
import 'package:swr_pmis_mobile/src/features/issues/presentation/providers/issue_form_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';

class AddIssueFormPage extends ConsumerStatefulWidget {
  const AddIssueFormPage({super.key, this.issueId = ''});

  final String issueId;

  static const String routeName = 'add-issue-form';
  static const String routePath = '/module/issues/add';

  static String location({String issueId = ''}) {
    final String id = issueId.trim();
    if (id.isEmpty) {
      return routePath;
    }
    return Uri(
      path: routePath,
      queryParameters: <String, String>{'issueId': id},
    ).toString();
  }

  @override
  ConsumerState<AddIssueFormPage> createState() => _AddIssueFormPageState();
}

class _AddIssueFormPageState extends ConsumerState<AddIssueFormPage> {
  static const int _detailMaxChars = 1000;

  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _actionTaken = TextEditingController();
  final TextEditingController _remarks = TextEditingController();
  final TextEditingController _otherName = TextEditingController();
  final TextEditingController _otherDesignation = TextEditingController();

  IssueFormMaster _master = IssueFormMaster.empty;
  bool _seeded = false;
  bool _reportedLoadError = false;

  String _projectId = '';
  String _contractId = '';
  String _structureId = '';
  String _componentId = '';
  String _categoryId = '';
  String _titleId = '';
  String _priorityId = '';
  String _statusId = '';
  String _departmentId = '';
  String _railwayId = '';
  String _reportedById = '';
  String _responsibleId = '';
  String _escalatedId = '';
  String _hodId = '';
  String _otherOrgId = '';
  String _fileTypeId = '';
  DateTime? _date;
  final List<_IssueAttachment> _attachments = <_IssueAttachment>[];

  String get _issueId => widget.issueId.trim();

  bool get _editing => _issueId.isNotEmpty;

  bool get _titlesFromCatalog => _master.titles.isNotEmpty;

  bool get _titlesLinked => _master.titles.any(
    (IssueFormOption option) => option.categoryId.isNotEmpty,
  );

  bool get _componentsNeedStructure => _master.components.any(
    (IssueFormOption option) => option.structureId.isNotEmpty,
  );

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _actionTaken.dispose();
    _remarks.dispose();
    _otherName.dispose();
    _otherDesignation.dispose();
    super.dispose();
  }

  void _seed(IssueFormMaster master, IssueDetail? detail) {
    if (_seeded) {
      return;
    }
    final IssueDetail issue = detail ?? IssueDetail.empty;
    final String projectId = issue.projectIdFk.isNotEmpty
        ? issue.projectIdFk
        : _projectForContract(master, issue.contractIdFk);
    _description.text = issue.description;
    _location.text = issue.location;
    _actionTaken.text = issue.correctiveMeasure;
    _remarks.text = issue.remarks;
    _otherName.text = issue.otherOrgResponsiblePersonName;
    _otherDesignation.text = issue.otherOrgResponsiblePersonDesignation;
    if (master.titles.isEmpty) {
      _title.text = issue.title;
    }
    setState(() {
      _seeded = true;
      _master = master;
      _projectId = _match(master.projects, projectId);
      _contractId = _match(master.contracts, issue.contractIdFk);
      _structureId = _match(master.structures, issue.structure);
      _componentId = _match(master.components, issue.component);
      _categoryId = _match(master.categories, issue.categoryFk);
      _titleId = master.titles.isEmpty
          ? ''
          : _match(master.titles, issue.title);
      _priorityId = _match(master.priorities, issue.priorityFk);
      _statusId = _match(master.statuses, issue.statusFk);
      _departmentId = _match(master.departments, issue.departmentFk);
      _railwayId = _match(master.railways, issue.zonalRailwayFk);
      _reportedById = _match(
        master.reportedBy,
        issue.reportedByUserId.isNotEmpty
            ? issue.reportedByUserId
            : issue.reportedBy,
      );
      _responsibleId = _match(
        master.responsiblePersons,
        issue.responsiblePersonUserId.isNotEmpty
            ? issue.responsiblePersonUserId
            : issue.responsiblePerson,
      );
      _escalatedId = _match(
        master.escalatedTo,
        issue.escalatedToUserId.isNotEmpty
            ? issue.escalatedToUserId
            : issue.escalatedTo,
      );
      _hodId = _match(master.hods, issue.hodUserId);
      _otherOrgId = _match(master.otherOrganizations, issue.otherOrganization);
      _fileTypeId = _match(
        master.fileTypes,
        issue.additional['issue_file_type'] ?? '',
      );
      _date = _parseDate(issue.date);
    });
  }

  String _projectForContract(IssueFormMaster master, String contractId) {
    for (final IssueFormOption contract in master.contracts) {
      if (contract.id == contractId && contract.projectId.isNotEmpty) {
        return contract.projectId;
      }
    }
    return '';
  }

  String _match(List<IssueFormOption> options, String raw) {
    if (raw.isEmpty) {
      return '';
    }
    for (final IssueFormOption option in options) {
      if (option.id == raw || option.label == raw) {
        return option.id;
      }
    }
    return raw;
  }

  DateTime? _parseDate(String raw) {
    final String text = raw.trim();
    if (text.isEmpty) {
      return null;
    }
    final DateTime? parsed = DateTime.tryParse(text);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    for (final String pattern in const <String>['dd/MM/yyyy', 'dd-MM-yyyy']) {
      try {
        final DateTime date = DateFormat(pattern).parseStrict(text);
        return DateTime(date.year, date.month, date.day);
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  void _reportLoadError(Object error) {
    if (!mounted || _reportedLoadError) {
      return;
    }
    _reportedLoadError = true;
    final String message = error is DioException
        ? userFriendlyErrorMessage(error)
        : 'Could not load the issue form. Please try again.';
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
    ref.invalidate(issueFormMasterProvider(_issueId));
    if (_editing) {
      ref.invalidate(issueDetailProvider(_issueId));
    }
  }

  void _selectProject(String id) {
    if (id == _projectId) {
      return;
    }
    setState(() {
      _projectId = id;
      _contractId = '';
      _clearContractChildren();
    });
  }

  void _selectContract(String id) {
    if (id == _contractId) {
      return;
    }
    setState(() {
      _contractId = id;
      _clearContractChildren();
    });
  }

  void _clearContractChildren() {
    _structureId = '';
    _componentId = '';
    if (_scoped(_master.responsiblePersons)) {
      _responsibleId = '';
    }
    if (_scoped(_master.reportedBy)) {
      _reportedById = '';
    }
    if (_scoped(_master.escalatedTo)) {
      _escalatedId = '';
    }
  }

  bool _scoped(List<IssueFormOption> options) {
    return options.any(
      (IssueFormOption option) => option.contractId.isNotEmpty,
    );
  }

  void _selectCategory(String id) {
    if (id == _categoryId) {
      return;
    }
    setState(() {
      _categoryId = id;
      if (_titlesLinked) {
        _titleId = '';
      }
    });
  }

  void _selectStructure(String id) {
    if (id == _structureId) {
      return;
    }
    setState(() {
      _structureId = id;
      _componentId = '';
    });
  }

  void _selectOtherOrg(String id) {
    setState(() {
      if (_otherOrgId != id) {
        _otherName.clear();
        _otherDesignation.clear();
      }
      _otherOrgId = id;
    });
  }

  List<IssueFormOption> get _contractOptions {
    return _withId(
      issueContractsForProject(_master.contracts, _projectId),
      _contractId,
      _master.contracts,
    );
  }

  List<IssueFormOption> get _structureOptions {
    return _withId(
      issueStructuresForContract(_master.structures, _contractId),
      _structureId,
      _master.structures,
    );
  }

  List<IssueFormOption> get _componentOptions {
    return _withId(
      issueComponentsFor(
        _master.components,
        contractId: _contractId,
        structureId: _structureId,
      ),
      _componentId,
      _master.components,
    );
  }

  List<IssueFormOption> get _titleOptions {
    String categoryLabel = '';
    for (final IssueFormOption option in _master.categories) {
      if (option.id == _categoryId) {
        categoryLabel = option.label;
        break;
      }
    }
    return _withId(
      issueTitlesForCategory(
        _master.titles,
        categoryId: _categoryId,
        categoryLabel: categoryLabel,
      ),
      _titleId,
      _master.titles,
    );
  }

  List<IssueFormOption> get _responsibleOptions {
    return _withId(
      issuePeopleForContract(_master.responsiblePersons, _contractId),
      _responsibleId,
      _master.responsiblePersons,
    );
  }

  List<IssueFormOption> get _reportedOptions {
    return _withId(
      issuePeopleForContract(_master.reportedBy, _contractId),
      _reportedById,
      _master.reportedBy,
    );
  }

  List<IssueFormOption> get _escalatedOptions {
    return _withId(
      issuePeopleForContract(_master.escalatedTo, _contractId),
      _escalatedId,
      _master.escalatedTo,
    );
  }

  List<IssueFormOption> _withId(
    List<IssueFormOption> options,
    String id,
    List<IssueFormOption> catalog,
  ) {
    if (id.isEmpty ||
        options.any((IssueFormOption option) => option.id == id)) {
      return options;
    }
    IssueFormOption current = IssueFormOption(id: id, label: id);
    for (final IssueFormOption option in catalog) {
      if (option.id == id) {
        current = option;
        break;
      }
    }
    return <IssueFormOption>[current, ...options];
  }

  String? _validationMessage() {
    if (_projectId.isEmpty) {
      return 'Please select a project.';
    }
    if (_contractId.isEmpty) {
      return 'Please select a contract.';
    }
    if (_categoryId.isEmpty) {
      return 'Please select a category.';
    }
    final String title = _titlesFromCatalog ? _titleId : _title.text.trim();
    if (title.isEmpty) {
      return _titlesFromCatalog
          ? 'Please select a title.'
          : 'Please enter a title.';
    }
    if (_description.text.trim().isEmpty) {
      return 'Please enter a description.';
    }
    if (_date == null) {
      return 'Please select a date.';
    }
    if (_priorityId.isEmpty) {
      return 'Please select a priority.';
    }
    if (_statusId.isEmpty) {
      return 'Please select a status.';
    }
    // Person fields apply only after another organization is chosen.
    if (_otherOrgId.isNotEmpty) {
      if (_otherName.text.trim().isEmpty) {
        return 'Please enter the responsible person name.';
      }
      if (_otherDesignation.text.trim().isEmpty) {
        return 'Please enter the responsible person designation.';
      }
    }
    return null;
  }

  Future<void> _pickAttachments() async {
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }
    final List<_IssueAttachment> next = <_IssueAttachment>[..._attachments];
    final Set<String> existing = <String>{
      for (final _IssueAttachment item in _attachments) item.path,
    };
    for (final PlatformFile file in picked.files) {
      final String? path = file.path;
      if (path == null || path.isEmpty || existing.contains(path)) {
        continue;
      }
      final String name = file.name.trim().isNotEmpty
          ? file.name
          : p.basename(path);
      next.add(_IssueAttachment(path: path, name: name));
      existing.add(path);
    }
    if (next.length == _attachments.length) {
      return;
    }
    setState(() {
      _attachments
        ..clear()
        ..addAll(next);
    });
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _submit() async {
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
    if (!mounted) {
      return;
    }
    // No save API is called. QA and prod stay read-only.
    await AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: _editing ? 'Update' : 'Add',
      message:
          'Save is not yet connected. The form was checked on this device and was not sent to the server.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<IssueFormMaster> masterAsync = ref.watch(
      issueFormMasterProvider(_issueId),
    );
    final AsyncValue<IssueDetail>? detailAsync = _editing
        ? ref.watch(issueDetailProvider(_issueId))
        : null;
    final Object? loadError = masterAsync.hasError
        ? masterAsync.error
        : (detailAsync != null && detailAsync.hasError)
        ? detailAsync.error
        : null;
    final bool ready =
        loadError == null &&
        masterAsync.hasValue &&
        (!_editing || (detailAsync?.hasValue ?? false));
    if (loadError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _reportLoadError(loadError);
        }
      });
    } else if (ready && !_seeded) {
      final IssueFormMaster master = masterAsync.requireValue;
      final IssueDetail? detail = detailAsync?.asData?.value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _seeded) {
          return;
        }
        _seed(master, detail);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit Issue' : 'Add Issue')),
      body: loadError != null
          ? _ErrorBody(onRetry: _retry)
          : !ready || !_seeded
          ? const Center(child: CircularProgressIndicator())
          : _form(),
    );
  }

  Widget _form() {
    final bool showComponent =
        _master.components.isNotEmpty || _componentId.isNotEmpty;
    final bool showHod = _master.hods.isNotEmpty || _hodId.isNotEmpty;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: <Widget>[
              _Section(
                title: 'Location',
                children: <Widget>[
                  _dropdown(
                    label: 'Project *',
                    options: _withId(
                      _master.projects,
                      _projectId,
                      _master.projects,
                    ),
                    selectedId: _projectId,
                    onPick: _selectProject,
                  ),
                  _dropdown(
                    label: 'Contract *',
                    options: _contractOptions,
                    selectedId: _contractId,
                    enabled: _projectId.isNotEmpty,
                    onPick: _selectContract,
                  ),
                  _dropdown(
                    label: 'Structure',
                    options: _structureOptions,
                    selectedId: _structureId,
                    enabled: _contractId.isNotEmpty,
                    onPick: _selectStructure,
                  ),
                  if (showComponent)
                    _dropdown(
                      label: 'Component',
                      options: _componentOptions,
                      selectedId: _componentId,
                      enabled: _componentsNeedStructure
                          ? _structureId.isNotEmpty
                          : _contractId.isNotEmpty,
                      onPick: (String id) => setState(() => _componentId = id),
                    ),
                  _text(_location, label: 'Location'),
                ],
              ),
              _Section(
                title: 'Issue',
                children: <Widget>[
                  _dropdown(
                    label: 'Category *',
                    options: _withId(
                      _master.categories,
                      _categoryId,
                      _master.categories,
                    ),
                    selectedId: _categoryId,
                    onPick: _selectCategory,
                  ),
                  if (_titlesFromCatalog)
                    _dropdown(
                      label: 'Title *',
                      options: _titleOptions,
                      selectedId: _titleId,
                      enabled: !_titlesLinked || _categoryId.isNotEmpty,
                      onPick: (String id) => setState(() => _titleId = id),
                    )
                  else
                    _text(_title, label: 'Title *'),
                  _dropdown(
                    label: 'Priority *',
                    options: _withId(
                      _master.priorities,
                      _priorityId,
                      _master.priorities,
                    ),
                    selectedId: _priorityId,
                    onPick: (String id) => setState(() => _priorityId = id),
                  ),
                  _dropdown(
                    label: 'Status *',
                    options: _withId(
                      _master.statuses,
                      _statusId,
                      _master.statuses,
                    ),
                    selectedId: _statusId,
                    onPick: (String id) => setState(() => _statusId = id),
                  ),
                  _text(
                    _description,
                    label: 'Description *',
                    maxLines: 4,
                    maxLength: _detailMaxChars,
                  ),
                  _dateField(),
                  _text(
                    _actionTaken,
                    label: 'Action taken',
                    maxLines: 3,
                    maxLength: _detailMaxChars,
                  ),
                  _text(
                    _remarks,
                    label: 'Remarks',
                    maxLines: 3,
                    maxLength: _detailMaxChars,
                  ),
                ],
              ),
              _Section(
                title: 'Responsibility',
                children: <Widget>[
                  _dropdown(
                    label: 'Department',
                    options: _withId(
                      _master.departments,
                      _departmentId,
                      _master.departments,
                    ),
                    selectedId: _departmentId,
                    onPick: (String id) => setState(() => _departmentId = id),
                  ),
                  _dropdown(
                    label: 'Zonal railway',
                    options: _withId(
                      _master.railways,
                      _railwayId,
                      _master.railways,
                    ),
                    selectedId: _railwayId,
                    onPick: (String id) => setState(() => _railwayId = id),
                  ),
                  _dropdown(
                    label: 'Reported by',
                    options: _reportedOptions,
                    selectedId: _reportedById,
                    onPick: (String id) => setState(() => _reportedById = id),
                  ),
                  _dropdown(
                    label: 'Responsible person',
                    options: _responsibleOptions,
                    selectedId: _responsibleId,
                    onPick: (String id) => setState(() => _responsibleId = id),
                  ),
                  _dropdown(
                    label: 'Escalated to',
                    options: _escalatedOptions,
                    selectedId: _escalatedId,
                    onPick: (String id) => setState(() => _escalatedId = id),
                  ),
                  if (showHod)
                    _dropdown(
                      label: 'HOD',
                      options: _withId(_master.hods, _hodId, _master.hods),
                      selectedId: _hodId,
                      onPick: (String id) => setState(() => _hodId = id),
                    ),
                  _dropdown(
                    label: 'Other organization',
                    options: _withId(
                      _master.otherOrganizations,
                      _otherOrgId,
                      _master.otherOrganizations,
                    ),
                    selectedId: _otherOrgId,
                    onPick: _selectOtherOrg,
                  ),
                  if (_otherOrgId.isNotEmpty) ...<Widget>[
                    _text(_otherName, label: 'Responsible person name *'),
                    _text(
                      _otherDesignation,
                      label: 'Responsible person designation *',
                    ),
                  ],
                ],
              ),
              _Section(
                title: 'Attachments',
                children: <Widget>[
                  if (_master.fileTypes.isNotEmpty)
                    _dropdown(
                      label: 'File type',
                      options: _withId(
                        _master.fileTypes,
                        _fileTypeId,
                        _master.fileTypes,
                      ),
                      selectedId: _fileTypeId,
                      onPick: (String id) => setState(() => _fileTypeId = id),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _pickAttachments,
                      icon: const Icon(Icons.attach_file_rounded, size: 18),
                      label: const Text('Attach'),
                    ),
                  ),
                  if (_attachments.isEmpty)
                    Text(
                      'No file selected',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    for (int i = 0; i < _attachments.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _attachments[i].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              onPressed: () => _removeAttachment(i),
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ],
                        ),
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
                child: Text(_editing ? 'Update' : 'Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required List<IssueFormOption> options,
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
                for (final IssueFormOption option in options)
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

  String? _labelOf(List<IssueFormOption> options, String id) {
    if (id.isEmpty) {
      return null;
    }
    for (final IssueFormOption option in options) {
      if (option.id == id) {
        return option.label;
      }
    }
    return id;
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

  Widget _dateField() {
    final String text = _date == null
        ? 'Select'
        : DateFormat('dd/MM/yyyy').format(_date!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: () async {
          final DateTime now = DateTime.now();
          final DateTime? picked = await showDatePicker(
            context: context,
            useRootNavigator: true,
            initialDate: _date ?? now,
            firstDate: DateTime(now.year - 10),
            lastDate: DateTime(now.year + 10),
          );
          if (picked != null) {
            setState(() {
              _date = DateTime(picked.year, picked.month, picked.day);
            });
          }
        },
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Date *'),
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

class _IssueAttachment {
  const _IssueAttachment({required this.path, required this.name});

  final String path;
  final String name;
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
              'Could not load the issue form.',
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
