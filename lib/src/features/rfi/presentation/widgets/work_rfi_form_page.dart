import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/work_rfi_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/work_rfi_form.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';

class WorkRfiFormPage extends ConsumerStatefulWidget {
  const WorkRfiFormPage({super.key, this.rfiId});

  final int? rfiId;

  /// Test / semantics keys for labeled select fields (empty hint is generic).
  static const Key structureFieldKey = ValueKey<String>('work_rfi_structure');
  static const Key componentFieldKey = ValueKey<String>('work_rfi_component');
  static const Key elementFieldKey = ValueKey<String>('work_rfi_element');
  static const Key layerFieldKey = ValueKey<String>('work_rfi_layer');
  static const Key activityFieldKey = ValueKey<String>('work_rfi_activity');
  static const Key descriptionFieldKey = ValueKey<String>(
    'work_rfi_description',
  );

  @override
  ConsumerState<WorkRfiFormPage> createState() => _WorkRfiFormPageState();
}

class _WorkRfiFormPageState extends ConsumerState<WorkRfiFormPage> {
  final TextEditingController _description = TextEditingController();
  final TextEditingController _chainageFrom = TextEditingController();
  final TextEditingController _chainageTo = TextEditingController();
  WorkRfiProjectCatalog _catalog = WorkRfiProjectCatalog.empty;
  List<WorkRfiOption> _projects = <WorkRfiOption>[];
  List<WorkRfiContractOption> _contracts = <WorkRfiContractOption>[];
  List<WorkRfiOption> _structureTypes = <WorkRfiOption>[];
  List<WorkRfiOption> _structures = <WorkRfiOption>[];
  List<WorkRfiOption> _components = <WorkRfiOption>[];
  List<WorkRfiOption> _elements = <WorkRfiOption>[];
  List<WorkRfiOption> _activityOptions = <WorkRfiOption>[];
  List<WorkRfiOption> _selectedActivities = <WorkRfiOption>[];
  List<_MeasureRow> _rows = <_MeasureRow>[];
  List<WorkRfiOption> _descriptionOptions = <WorkRfiOption>[];
  List<String> _descriptionIds = <String>[];
  List<WorkRfiOption> _enclosureOptions = <WorkRfiOption>[];
  List<String> _enclosureIds = <String>[];
  List<WorkRfiOption> _representatives = <WorkRfiOption>[];
  String _projectId = '';
  String _contractId = '';
  String _structureType = '';
  String _structureId = '';
  String _component = '';
  String _element = '';
  String? _chainageFromError;
  String? _chainageToError;
  List<WorkRfiOption> _layers = <WorkRfiOption>[];
  String _layerId = '';
  String _rfiRequired = '';
  String _typeOfRfi = '';
  // Saved values of the RFI being edited; an unchanged pair is exempt from the
  // Date of Inspection rule (see workRfiValidationMessage).
  String _originalTypeOfRfi = '';
  String _originalDateOfInspection = '';
  String _representativeId = '';
  String _representativeName = '';
  DateTime? _submissionDate;
  TimeOfDay? _inspectionTime;
  DateTime? _inspectionDate;
  DateTime? _progressDate;
  bool _ready = false;
  bool _submitting = false;
  bool _loadingContracts = false;
  bool _loadingStructureTypes = false;
  bool _loadingStructures = false;
  bool _loadingComponents = false;
  bool _loadingElements = false;
  bool _loadingActivities = false;
  bool _loadingDescriptions = false;
  bool _loadingEnclosures = false;
  bool _loadingLayers = false;
  int _cascade = 0;
  int _layerTicket = 0;
  int _descriptionTicket = 0;
  int _enclosureTicket = 0;

  bool get _editing => widget.rfiId != null;

  bool get _keepsLocalActivity =>
      !_editing && workRfiIsEarthworkOrBlanketing(_structureType);

  bool get _busy =>
      !_ready ||
      _submitting ||
      _loadingContracts ||
      _loadingStructureTypes ||
      _loadingStructures ||
      _loadingComponents ||
      _loadingElements ||
      _loadingActivities ||
      _loadingDescriptions ||
      _loadingEnclosures ||
      _loadingLayers;

  WorkRfiRemoteDataSource get _source =>
      ref.read(workRfiRemoteDataSourceProvider);

  @override
  void initState() {
    super.initState();
    if (!_editing) {
      _submissionDate = _today();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_bootstrap());
      }
    });
  }

  @override
  void dispose() {
    _description.dispose();
    _chainageFrom.dispose();
    _chainageTo.dispose();
    for (final _MeasureRow row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!_editing) {
      try {
        final List<WorkRfiOption> projects = await _source.fetchProjectNames();
        if (!mounted) {
          return;
        }
        setState(() {
          _projects = projects;
          _ready = true;
        });
      } on Object catch (error) {
        if (!mounted) {
          return;
        }
        setState(() => _ready = true);
        await _showError('Projects unavailable', error);
      }
      unawaited(_loadRepresentatives());
      return;
    }
    unawaited(_loadRepresentatives());
    final WorkRfiDetail? detail = await _guard(
      _source.fetchDetail(widget.rfiId!),
      'Work RFI unavailable',
    );
    if (!mounted) {
      return;
    }
    if (detail == null) {
      Navigator.of(context).pop();
      return;
    }
    final WorkRfiProjectCatalog? catalog = await _guard(
      _source.fetchProjectCatalog(),
      'Projects unavailable',
    );
    if (!mounted) {
      return;
    }
    if (catalog != null) {
      _catalog = catalog;
    }
    _projects = _ensureOption(
      _catalog.projects,
      detail.project,
      detail.project,
    );
    _applyDetail(detail);
    _representatives = _withRepresentative(_representatives);
    await _restore(detail);
    if (!mounted) {
      return;
    }
    setState(() => _ready = true);
  }

  Future<void> _loadRepresentatives() async {
    List<WorkRfiOption> options = const <WorkRfiOption>[];
    try {
      options = await _source.fetchRepresentatives();
    } on Object {
      options = const <WorkRfiOption>[];
    }
    if (!mounted) {
      return;
    }
    setState(() => _representatives = _withRepresentative(options));
  }

  void _applyDetail(WorkRfiDetail detail) {
    _projectId = detail.project;
    _contractId = detail.contract;
    _structureType = detail.structureType;
    _structureId = detail.structure;
    _component = detail.component;
    _element = detail.element;
    _rfiRequired = detail.rfiRequired == 'Yes' || detail.rfiRequired == 'No'
        ? detail.rfiRequired
        : '';
    _typeOfRfi = detail.typeOfRfi;
    _originalTypeOfRfi = detail.typeOfRfi;
    _originalDateOfInspection = detail.dateOfInspection;
    _representativeId = detail.userIdOfRepresentative;
    _representativeName = detail.nameOfRepresentative;
    _submissionDate = parseWorkRfiDate(detail.dateOfSubmission) ?? _today();
    _inspectionDate = parseWorkRfiDate(detail.dateOfInspection);
    _progressDate = parseWorkRfiDate(detail.progressDate);
    _inspectionTime = _timeOf(detail.timeOfInspection);
    _description.text = detail.description;
    _descriptionIds = List<String>.from(detail.rfiDescriptionList);
    _enclosureIds = List<String>.from(detail.enclosuresList);
  }

  Future<void> _restore(WorkRfiDetail detail) async {
    if (detail.project.isEmpty) {
      return;
    }
    final List<WorkRfiContractOption>? contracts = await _guard(
      _contractsFor(detail.project),
      'Contracts unavailable',
    );
    if (!mounted || contracts == null) {
      return;
    }
    _contracts = _ensureContract(contracts, detail.contract, detail.project);
    if (detail.contract.isEmpty) {
      return;
    }
    final List<WorkRfiOption>? types = await _guard(
      _source.fetchStructureTypes(detail.contract),
      'Structure types unavailable',
    );
    if (!mounted || types == null) {
      return;
    }
    _structureTypes = _ensureOption(
      types,
      detail.structureType,
      detail.structureType,
    );
    if (detail.structureType.isEmpty) {
      return;
    }
    if (workRfiIsEarthworkOrBlanketing(detail.structureType)) {
      final WorkRfiLayerRange? range = await _readLayerRange(
        detail.structureType,
      );
      if (!mounted) {
        return;
      }
      if (range != null) {
        _layers = workRfiLayerOptions(
          minLayer: range.minLayer,
          maxLayer: range.maxLayer,
        );
      }
    }
    final List<WorkRfiOption>? structures = await _guard(
      _source.fetchStructures(
        contractId: detail.contract,
        structureType: detail.structureType,
      ),
      'Structures unavailable',
    );
    if (!mounted || structures == null) {
      return;
    }
    _structures = _ensureOption(structures, detail.structure, detail.structure);
    if (detail.structure.isEmpty) {
      return;
    }
    final List<WorkRfiOption>? components = await _guard(
      _source.fetchComponents(
        contractId: detail.contract,
        structureId: detail.structure,
        structureType: detail.structureType,
      ),
      'Components unavailable',
    );
    if (!mounted || components == null) {
      return;
    }
    _components = _ensureOption(components, detail.component, detail.component);
    if (detail.component.isEmpty) {
      return;
    }
    final List<WorkRfiOption>? elements = await _guard(
      _source.fetchElements(
        contractId: detail.contract,
        structureId: detail.structure,
        component: detail.component,
        structureType: detail.structureType,
      ),
      'Elements unavailable',
    );
    if (!mounted || elements == null) {
      return;
    }
    _elements = _ensureOption(elements, detail.element, detail.element);
    if (detail.element.isEmpty) {
      return;
    }
    final List<WorkRfiOption>? activities = await _guard(
      _source.fetchActivities(
        contractId: detail.contract,
        structureId: detail.structure,
        structureType: detail.structureType,
        component: detail.component,
        element: detail.element,
      ),
      'Activities unavailable',
    );
    if (!mounted || activities == null) {
      return;
    }
    final WorkRfiEditActivities resolved = resolveWorkRfiEditActivities(
      options: activities,
      activityList: detail.activityList,
      activityId: detail.activity,
      measurements: detail.measurements,
    );
    _activityOptions = _dedupe(<WorkRfiOption>[
      ...activities,
      ...resolved.selected,
    ]);
    _selectedActivities = resolved.selected;
    _replaceRows(resolved.rows);
    _descriptionIds = List<String>.from(detail.rfiDescriptionList);
    _enclosureIds = List<String>.from(detail.enclosuresList);
    await _refreshDescriptions(keep: detail.rfiDescriptionList);
  }

  Future<List<WorkRfiContractOption>> _contractsFor(String projectId) {
    final List<WorkRfiContractOption> local = workRfiContractsForProject(
      _catalog.contracts,
      projectId,
    );
    if (local.isNotEmpty) {
      return Future<List<WorkRfiContractOption>>.value(local);
    }
    return _source.fetchContracts(projectId);
  }

  Future<void> _selectProject(String id) async {
    if (id == _projectId) {
      return;
    }
    final int ticket = _bump();
    setState(() {
      _projectId = id;
      _clearContracts();
      _loadingContracts = true;
    });
    final List<WorkRfiContractOption>? contracts = await _guard(
      _editing ? _contractsFor(id) : _source.fetchContractNames(id),
      'Contracts unavailable',
    );
    if (!mounted || ticket != _cascade) {
      return;
    }
    setState(() {
      _loadingContracts = false;
      if (contracts != null) {
        _contracts = contracts;
      }
    });
  }

  Future<void> _selectContract(String id) async {
    if (id == _contractId) {
      return;
    }
    final int ticket = _bump();
    setState(() {
      _contractId = id;
      _clearStructureTypes();
      _loadingStructureTypes = true;
    });
    final List<WorkRfiOption>? options = await _guard(
      _source.fetchStructureTypes(id),
      'Structure types unavailable',
    );
    if (!mounted || ticket != _cascade) {
      return;
    }
    setState(() {
      _loadingStructureTypes = false;
      if (options != null) {
        _structureTypes = options;
      }
    });
  }

  Future<void> _selectStructureType(String id) async {
    if (id == _structureType) {
      return;
    }
    final int ticket = _bump();
    setState(() {
      _structureType = id;
      _clearStructures();
      _clearChainageFields();
      if (!_editing) {
        _applyCreateActivity(id);
      }
      _loadingStructures = true;
    });
    if (!_editing && _selectedActivities.isNotEmpty) {
      unawaited(_refreshDescriptions());
    }
    unawaited(_loadLayers(id));
    final List<WorkRfiOption>? options = await _guard(
      _source.fetchStructures(contractId: _contractId, structureType: id),
      'Structures unavailable',
    );
    if (!mounted || ticket != _cascade) {
      return;
    }
    setState(() {
      _loadingStructures = false;
      if (options != null) {
        _structures = options;
      }
    });
  }

  Future<void> _selectStructure(String id) async {
    if (id == _structureId) {
      return;
    }
    final bool keepLocalActivity = _keepsLocalActivity;
    final int ticket = _bump(resetDescriptions: !keepLocalActivity);
    setState(() {
      _structureId = id;
      _clearComponents(preserveCreateActivity: keepLocalActivity);
      _loadingComponents = true;
    });
    final List<WorkRfiOption>? options = await _guard(
      _source.fetchComponents(
        contractId: _contractId,
        structureId: id,
        structureType: _structureType,
      ),
      'Components unavailable',
    );
    if (!mounted || ticket != _cascade) {
      return;
    }
    setState(() {
      _loadingComponents = false;
      if (options != null) {
        _components = options;
      }
    });
  }

  Future<void> _selectComponent(String id) async {
    if (id == _component) {
      return;
    }
    final bool keepLocalActivity = _keepsLocalActivity;
    final int ticket = _bump(resetDescriptions: !keepLocalActivity);
    setState(() {
      _component = id;
      _clearElements(preserveCreateActivity: keepLocalActivity);
      _loadingElements = true;
    });
    final List<WorkRfiOption>? options = await _guard(
      _source.fetchElements(
        contractId: _contractId,
        structureId: _structureId,
        component: id,
        structureType: _structureType,
      ),
      'Elements unavailable',
    );
    if (!mounted || ticket != _cascade) {
      return;
    }
    setState(() {
      _loadingElements = false;
      if (options != null) {
        _elements = options;
      }
    });
  }

  Future<void> _selectElement(String id) async {
    if (id == _element) {
      return;
    }
    if (_keepsLocalActivity) {
      setState(() => _element = id);
      return;
    }
    final int ticket = _bump();
    setState(() {
      _element = id;
      _clearActivities();
      _loadingActivities = true;
    });
    final List<WorkRfiOption>? options = await _guard(
      _source.fetchActivities(
        contractId: _contractId,
        structureId: _structureId,
        structureType: _structureType,
        component: _component,
        element: id,
      ),
      'Activities unavailable',
    );
    if (!mounted || ticket != _cascade) {
      return;
    }
    setState(() {
      _loadingActivities = false;
      if (options != null) {
        _activityOptions = options;
      }
    });
  }

  Future<void> _setActivities(List<WorkRfiOption> selected) async {
    final Map<String, _MeasureRow> existing = <String, _MeasureRow>{
      for (final _MeasureRow row in _rows) row.activityId: row,
    };
    final List<_MeasureRow> next = <_MeasureRow>[];
    for (final WorkRfiOption option in selected) {
      final _MeasureRow? row = existing.remove(option.id);
      if (row == null) {
        next.add(
          _MeasureRow(
            WorkRfiMeasurementDraft(
              activityId: option.id,
              activityName: option.label,
            ),
          ),
        );
      } else {
        row.activityName = option.label;
        next.add(row);
      }
    }
    final List<_MeasureRow> removed = existing.values.toList(growable: false);
    setState(() {
      _selectedActivities = selected;
      _rows = next;
    });
    _dropRows(removed);
    await _refreshDescriptions();
  }

  Future<void> _refreshDescriptions({List<String>? keep}) async {
    final int ticket = ++_descriptionTicket;
    final List<String> names = <String>[];
    final Set<String> seen = <String>{};
    for (final WorkRfiOption option in _selectedActivities) {
      final String name = option.label.trim();
      if (name.isNotEmpty && seen.add(name)) {
        names.add(name);
      }
    }
    if (names.isEmpty) {
      if (!mounted || ticket != _descriptionTicket) {
        return;
      }
      setState(() {
        _descriptionOptions = <WorkRfiOption>[];
        _descriptionIds = <String>[];
        _loadingDescriptions = false;
        _clearEnclosures();
      });
      return;
    }
    setState(() => _loadingDescriptions = true);
    try {
      final List<List<WorkRfiOption>> lists = await Future.wait(
        <Future<List<WorkRfiOption>>>[
          for (final String name in names) _source.fetchDescriptions(name),
        ],
      );
      if (!mounted || ticket != _descriptionTicket) {
        return;
      }
      final List<WorkRfiOption> merged = _dedupe(<WorkRfiOption>[
        for (final List<WorkRfiOption> list in lists) ...list,
      ]);
      final List<String> wanted = keep ?? _descriptionIds;
      setState(() {
        _descriptionOptions = merged;
        _descriptionIds = <String>[
          for (final String id in wanted)
            if (merged.any((WorkRfiOption option) => option.id == id)) id,
        ];
        _loadingDescriptions = false;
      });
      await _refreshEnclosures();
    } on Object catch (error) {
      if (!mounted || ticket != _descriptionTicket) {
        return;
      }
      setState(() => _loadingDescriptions = false);
      await _showError('RFI descriptions unavailable', error);
    }
  }

  Future<void> _refreshEnclosures() async {
    final int ticket = ++_enclosureTicket;
    final List<String> labels = <String>[];
    final Set<String> seen = <String>{};
    for (final String id in _descriptionIds) {
      final String? label = _knownLabel(_descriptionOptions, id);
      if (label != null && label.isNotEmpty && seen.add(label)) {
        labels.add(label);
      }
    }
    if (labels.isEmpty) {
      if (!mounted || ticket != _enclosureTicket) {
        return;
      }
      setState(_clearEnclosures);
      return;
    }
    setState(() => _loadingEnclosures = true);
    try {
      final List<List<WorkRfiOption>> lists = await Future.wait(
        <Future<List<WorkRfiOption>>>[
          for (final String label in labels) _source.fetchEnclosures(label),
        ],
      );
      if (!mounted || ticket != _enclosureTicket) {
        return;
      }
      final List<WorkRfiOption> merged = _dedupe(<WorkRfiOption>[
        for (final List<WorkRfiOption> list in lists) ...list,
      ]);
      setState(() {
        _enclosureOptions = merged;
        _enclosureIds = <String>[
          for (final String id in _enclosureIds)
            if (merged.any((WorkRfiOption option) => option.id == id)) id,
        ];
        _loadingEnclosures = false;
      });
    } on Object catch (error) {
      if (!mounted || ticket != _enclosureTicket) {
        return;
      }
      setState(() => _loadingEnclosures = false);
      await _showError('Enclosures unavailable', error);
    }
  }

  Future<void> _submit() async {
    final WorkRfiSubmitDraft draft = _draft();
    final String? missing = workRfiValidationMessage(draft);
    if (missing != null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Missing details',
        message: missing,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final Map<String, dynamic> body = buildWorkRfiPayload(draft);
      final int? id = widget.rfiId;
      if (id == null) {
        await _source.create(body);
      } else {
        await _source.update(id, body);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      await _showError(_editing ? 'Update failed' : 'Create failed', error);
    }
  }

  WorkRfiSubmitDraft _draft() {
    return WorkRfiSubmitDraft(
      project: _projectId,
      contract: _contractId,
      structureType: _structureType,
      structure: _structureId,
      component: _component,
      element: _element,
      activities: <WorkRfiMeasurementDraft>[
        for (final _MeasureRow row in _rows) row.toDraft(),
      ],
      descriptionIds: _descriptionIds,
      rfiRequired: _rfiRequired,
      typeOfRfi: _typeOfRfi,
      contractorRepresentative: _representativeId,
      progressDate: _progressDate == null
          ? ''
          : workRfiFormatApiDate(_progressDate!),
      dateOfSubmission: _submissionDate == null
          ? ''
          : workRfiFormatApiDate(_submissionDate!),
      timeOfInspection: _inspectionTime == null
          ? ''
          : _apiTime(_inspectionTime!),
      dateOfInspection: _inspectionDate == null
          ? ''
          : workRfiFormatApiDate(_inspectionDate!),
      enclosureIds: _enclosureIds,
      description: _description.text.trim(),
      chainageFrom: _chainageFrom.text,
      chainageTo: _chainageTo.text,
      layer: _layerId,
      today: _today(),
      originalTypeOfRfi: _originalTypeOfRfi,
      originalDateOfInspection: _originalDateOfInspection,
      editing: _editing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editing ? 'Edit Works RFI' : 'Create Works RFI'),
        ),
        body: Column(
          children: <Widget>[
            RfiContentLoader(loading: _busy),
            Expanded(
              child: _ready
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: <Widget>[
                        _locationCard(),
                        _activityCard(),
                        _measurementCard(),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            if (_ready) _actions(),
          ],
        ),
      ),
    );
  }

  Widget _locationCard() {
    final bool chainage = workRfiIsEarthworkOrBlanketing(_structureType);
    return _section(
      title: 'LOCATION',
      children: <Widget>[
        _labeled(
          'Project',
          child: _selectBox(
            hint: 'Select...',
            value: _optionLabel(_projects, _projectId),
            enabled: !_submitting,
            onTap: () => _pickSingle(
              title: 'Project',
              options: _projects,
              selectedId: _projectId,
              emptyMessage: 'No projects',
              onPicked: _selectProject,
            ),
          ),
        ),
        _labeled(
          'Contract',
          child: _selectBox(
            hint: 'Select...',
            value: _contractLabel(_contractId),
            enabled: _projectId.isNotEmpty && !_submitting,
            onTap: () => _pickSingle(
              title: 'Contract',
              options: <WorkRfiOption>[
                for (final WorkRfiContractOption contract in _contracts)
                  contract.toOption(),
              ],
              selectedId: _contractId,
              emptyMessage: 'No contracts',
              onPicked: _selectContract,
            ),
          ),
        ),
        _labeled(
          'Structure Type',
          child: _selectBox(
            hint: 'Select...',
            value: _optionLabel(_structureTypes, _structureType),
            enabled: _contractId.isNotEmpty && !_submitting,
            onTap: () => _pickSingle(
              title: 'Structure Type',
              options: _structureTypes,
              selectedId: _structureType,
              emptyMessage: 'No structure types',
              onPicked: _selectStructureType,
            ),
          ),
        ),
        _labeled(
          'Structure',
          child: _selectBox(
            key: WorkRfiFormPage.structureFieldKey,
            hint: 'Select...',
            value: _optionLabel(_structures, _structureId),
            enabled: _structureType.isNotEmpty && !_submitting,
            onTap: () => _pickSingle(
              title: 'Structure',
              options: _structures,
              selectedId: _structureId,
              emptyMessage: 'No structures',
              onPicked: _selectStructure,
            ),
          ),
        ),
        _labeled(
          'Component',
          child: _selectBox(
            key: WorkRfiFormPage.componentFieldKey,
            hint: 'Select...',
            value: _optionLabel(_components, _component),
            enabled: _structureId.isNotEmpty && !_submitting,
            onTap: () => _pickSingle(
              title: 'Component',
              options: _components,
              selectedId: _component,
              emptyMessage: 'No components',
              onPicked: _selectComponent,
            ),
          ),
        ),
        _labeled(
          'Element',
          child: _selectBox(
            key: WorkRfiFormPage.elementFieldKey,
            hint: 'Select...',
            value: _optionLabel(_elements, _element),
            enabled: _component.isNotEmpty && !_submitting,
            onTap: () => _pickSingle(
              title: 'Element',
              options: _elements,
              selectedId: _element,
              emptyMessage: 'No elements',
              onPicked: _selectElement,
            ),
          ),
        ),
        if (chainage) _chainageGroup(),
      ],
    );
  }

  Widget _chainageGroup() {
    final Color outline = Theme.of(context).colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: outline),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _labeled(
                'Chainage From',
                error: _chainageFromError,
                child: _WorkRfiTextField(
                  controller: _chainageFrom,
                  hint: 'e.g. 12+500',
                  enabled: !_submitting,
                  keyboardType: TextInputType.text,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+.]')),
                  ],
                  onChanged: (_) => _onChainageChanged(),
                  onUnfocus: () =>
                      _alertChainage('Chainage From', _chainageFrom.text),
                ),
              ),
              _labeled(
                'Chainage To',
                error: _chainageToError,
                child: _WorkRfiTextField(
                  controller: _chainageTo,
                  hint: 'e.g. 13+000',
                  enabled: !_submitting,
                  keyboardType: TextInputType.text,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+.]')),
                  ],
                  onChanged: (_) => _onChainageChanged(),
                  onUnfocus: () =>
                      _alertChainage('Chainage To', _chainageTo.text),
                ),
              ),
              _labeled(
                'Layer',
                child: _selectBox(
                  key: WorkRfiFormPage.layerFieldKey,
                  hint: 'Select...',
                  value: _optionLabel(_layers, _layerId),
                  enabled: _layers.isNotEmpty && !_submitting,
                  onTap: () => _pickSingle(
                    title: 'Layer',
                    options: _layers,
                    selectedId: _layerId,
                    emptyMessage: 'No layers',
                    onPicked: (String id) async {
                      setState(() => _layerId = id);
                    },
                  ),
                ),
              ),
              Text(
                workRfiChainageRule,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityCard() {
    if (!_editing) {
      return _createActivityCard();
    }
    final bool yes = _rfiRequired == 'Yes';
    final bool no = _rfiRequired == 'No';
    return _section(
      title: 'ACTIVITY & DESCRIPTION',
      badge: _selectedActivities.isEmpty
          ? null
          : _countBadge(_selectedActivities.length),
      children: <Widget>[
        _labeled(
          'Activity',
          child: _multiBox(
            key: WorkRfiFormPage.activityFieldKey,
            hint: 'Select...',
            selected: _selectedActivities,
            enabled: _element.isNotEmpty && !_submitting,
            onTap: _pickActivities,
            onRemove: (WorkRfiOption option) {
              unawaited(
                _setActivities(
                  _selectedActivities
                      .where((WorkRfiOption item) => item.id != option.id)
                      .toList(growable: false),
                ),
              );
            },
            onClear: _selectedActivities.isEmpty
                ? null
                : () => unawaited(_setActivities(const <WorkRfiOption>[])),
          ),
        ),
        _labeled(
          'RFI Description',
          child: _multiBox(
            key: WorkRfiFormPage.descriptionFieldKey,
            hint: 'Select...',
            selected: _optionsFor(_descriptionOptions, _descriptionIds),
            enabled: _selectedActivities.isNotEmpty && !_submitting,
            onTap: _pickDescriptions,
            onRemove: (WorkRfiOption option) {
              unawaited(
                _setDescriptions(
                  _descriptionIds
                      .where((String id) => id != option.id)
                      .toList(growable: false),
                ),
              );
            },
            onClear: _descriptionIds.isEmpty
                ? null
                : () => unawaited(_setDescriptions(const <String>[])),
          ),
        ),
        _labeled('RFI Required', child: _requiredRadio()),
        if (yes) ...<Widget>[
          _labeled(
            'Action',
            child: _selectBox(
              hint: workRfiFixedAction,
              value: workRfiFixedAction,
              enabled: false,
              onTap: null,
            ),
          ),
          _labeled(
            'Type of RFI',
            child: _selectBox(
              hint: 'Select...',
              value: _typeOfRfi.isEmpty ? null : _typeOfRfi,
              enabled: !_submitting,
              onTap: _pickTypeOfRfi,
            ),
          ),
          _labeled(
            "Name of Contractor's Representative",
            child: _selectBox(
              hint: 'Select...',
              value: _optionLabel(_representatives, _representativeId),
              enabled: !_submitting,
              onTap: _pickRepresentative,
            ),
          ),
          _labeled(
            'Date of Submission of RFI',
            child: _iconBox(
              text: _submissionDate == null
                  ? null
                  : workRfiFormatDisplayDate(_submissionDate!),
              hint: 'dd/mm/yyyy',
              icon: Icons.calendar_today_outlined,
              enabled: false,
              onTap: null,
            ),
          ),
          _labeled(
            'Time of Inspection',
            child: _iconBox(
              text: _inspectionTime == null
                  ? null
                  : workRfiDisplayTime(_apiTime(_inspectionTime!)),
              hint: '--:-- --',
              icon: Icons.schedule_rounded,
              enabled: !_submitting,
              onTap: _pickTime,
            ),
          ),
          _labeled(
            'Date of Inspection',
            child: _iconBox(
              text: _inspectionDate == null
                  ? null
                  : workRfiFormatDisplayDate(_inspectionDate!),
              hint: 'dd/mm/yyyy',
              icon: Icons.calendar_today_outlined,
              enabled: !_submitting,
              onTap: _pickInspectionDate,
            ),
          ),
          _labeled(
            'Enclosures',
            child: _multiBox(
              hint: 'Select...',
              selected: _optionsFor(_enclosureOptions, _enclosureIds),
              enabled: _descriptionIds.isNotEmpty && !_submitting,
              onTap: _pickEnclosures,
              onRemove: (WorkRfiOption option) {
                unawaited(
                  _setEnclosures(
                    _enclosureIds
                        .where((String id) => id != option.id)
                        .toList(growable: false),
                  ),
                );
              },
              onClear: _enclosureIds.isEmpty
                  ? null
                  : () => unawaited(_setEnclosures(const <String>[])),
            ),
          ),
        ],
        if (no)
          _labeled(
            'Progress Date',
            child: _iconBox(
              text: _progressDate == null
                  ? null
                  : workRfiFormatDisplayDate(_progressDate!),
              hint: 'dd/mm/yyyy',
              icon: Icons.calendar_today_outlined,
              enabled: !_submitting,
              onTap: () => _pickDate(
                current: _progressDate,
                onPicked: (DateTime date) =>
                    setState(() => _progressDate = date),
              ),
            ),
          ),
        _labeled(
          'Description',
          required: false,
          child: _WorkRfiTextField(
            controller: _description,
            hint: 'Add Description',
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
          ),
        ),
      ],
    );
  }

  Widget _createActivityCard() {
    final bool chainage = workRfiIsEarthworkOrBlanketing(_structureType);
    final bool yes = _rfiRequired == 'Yes';
    final bool no = _rfiRequired == 'No';
    final bool activityChosen = _selectedActivities.isNotEmpty;
    final String? activityLabel = activityChosen
        ? _selectedActivities.first.label
        : null;
    return _section(
      title: 'ACTIVITY & DESCRIPTION',
      children: <Widget>[
        _labeled(
          'Activity',
          child: _selectBox(
            key: WorkRfiFormPage.activityFieldKey,
            hint: 'Select...',
            value: activityLabel,
            enabled:
                (chainage
                    ? activityChosen
                    : _element.isNotEmpty && !_loadingActivities) &&
                !_submitting,
            onTap: () => _pickSingle(
              title: 'Activity',
              options: _activityOptions,
              selectedId: activityChosen ? _selectedActivities.first.id : '',
              emptyMessage: 'No activities',
              onPicked: _selectCreateActivity,
            ),
          ),
        ),
        _labeled(
          'RFI Description',
          child: _selectBox(
            key: WorkRfiFormPage.descriptionFieldKey,
            hint: 'Select...',
            value: _descriptionIds.isEmpty
                ? null
                : <String>[
                    for (final String id in _descriptionIds)
                      _optionLabel(_descriptionOptions, id) ?? id,
                  ].join(', '),
            enabled: _descriptionOptions.isNotEmpty && !_submitting,
            onTap: _descriptionOptions.isEmpty
                ? null
                : () => _pickSingle(
                    title: 'RFI Description',
                    options: _descriptionOptions,
                    selectedId: _descriptionIds.isEmpty
                        ? ''
                        : _descriptionIds.first,
                    emptyMessage: 'No RFI descriptions',
                    onPicked: _selectCreateDescription,
                  ),
          ),
        ),
        _labeled('RFI Required', child: _requiredRadio()),
        if (yes) ...<Widget>[
          _labeled(
            'Action',
            child: _selectBox(
              hint: workRfiFixedAction,
              value: workRfiFixedAction,
              enabled: false,
              onTap: null,
            ),
          ),
          _labeled(
            'Type of RFI',
            child: _selectBox(
              hint: 'Select...',
              value: _typeOfRfi.isEmpty ? null : _typeOfRfi,
              enabled: !_submitting,
              onTap: _pickTypeOfRfi,
            ),
          ),
          _labeled(
            "Name of Contractor's Representative",
            child: _selectBox(
              hint: 'Select...',
              value: _optionLabel(_representatives, _representativeId),
              enabled: !_submitting,
              onTap: _pickRepresentative,
            ),
          ),
          _labeled(
            'Time of Inspection',
            child: _iconBox(
              text: _inspectionTime == null
                  ? null
                  : workRfiDisplayTime(_apiTime(_inspectionTime!)),
              hint: '--:-- --',
              icon: Icons.schedule_rounded,
              enabled: !_submitting,
              onTap: _pickTime,
            ),
          ),
          _labeled(
            'Date of Inspection',
            child: _iconBox(
              text: _inspectionDate == null
                  ? null
                  : workRfiFormatDisplayDate(_inspectionDate!),
              hint: 'dd/mm/yyyy',
              icon: Icons.calendar_today_outlined,
              enabled: !_submitting,
              onTap: _pickInspectionDate,
            ),
          ),
          _labeled(
            'Date of Submission of RFI',
            child: _iconBox(
              text: _submissionDate == null
                  ? null
                  : workRfiFormatDisplayDate(_submissionDate!),
              hint: 'dd/mm/yyyy',
              icon: Icons.calendar_today_outlined,
              enabled: false,
              onTap: null,
            ),
          ),
          _labeled(
            'Enclosures',
            child: _multiBox(
              hint: 'Select...',
              selected: _optionsFor(_enclosureOptions, _enclosureIds),
              enabled: _descriptionIds.isNotEmpty && !_submitting,
              onTap: _pickEnclosures,
              onRemove: (WorkRfiOption option) {
                unawaited(
                  _setEnclosures(
                    _enclosureIds
                        .where((String id) => id != option.id)
                        .toList(growable: false),
                  ),
                );
              },
              onClear: _enclosureIds.isEmpty
                  ? null
                  : () => unawaited(_setEnclosures(const <String>[])),
            ),
          ),
        ],
        if (no)
          _labeled(
            'Progress Date',
            child: _iconBox(
              text: _progressDate == null
                  ? null
                  : workRfiFormatDisplayDate(_progressDate!),
              hint: 'dd/mm/yyyy',
              icon: Icons.calendar_today_outlined,
              enabled: !_submitting,
              onTap: () => _pickDate(
                current: _progressDate,
                onPicked: (DateTime date) =>
                    setState(() => _progressDate = date),
              ),
            ),
          ),
        _labeled(
          'Description',
          required: false,
          child: _WorkRfiTextField(
            controller: _description,
            hint: 'Add Description',
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
          ),
        ),
      ],
    );
  }

  Widget _measurementCard() {
    return _section(
      title: 'MEASUREMENT',
      children: <Widget>[_measurementTable()],
    );
  }

  Widget _measurementTable() {
    const double headerHeight = 48;
    const double rowHeight = 68;
    final double width = _measureWidths.fold<double>(
      0,
      (double total, double value) => total + value,
    );
    final double bodyHeight = _rows.isEmpty ? 0 : _rows.length * rowHeight;
    final Color outline = Theme.of(context).colorScheme.outlineVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: headerHeight + bodyHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  width: width,
                  child: Column(
                    children: <Widget>[
                      _measureHeader(),
                      for (var i = 0; i < _rows.length; i++)
                        _measureDataRow(_rows[i], i),
                    ],
                  ),
                ),
              ),
            ),
            if (_rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                child: Text(
                  'Select one or more activities above — one measurement row will be created for each activity',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _measureHeader() {
    return ColoredBox(
      color: AppTheme.brandPrimary,
      child: SizedBox(
        height: 48,
        child: Row(
          children: <Widget>[
            for (var i = 0; i < _measureLabels.length; i++)
              SizedBox(
                width: _measureWidths[i],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Align(
                    alignment: i == 0 ? Alignment.center : Alignment.centerLeft,
                    child: Text(
                      _measureLabels[i],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _measureDataRow(_MeasureRow row, int index) {
    final WorkRfiMeasureFields fields = workRfiFieldsFor(row.measurementType);
    final List<String> units = workRfiUnitsFor(row.measurementType);
    return SizedBox(
      height: 68,
      child: Row(
        children: <Widget>[
          _fixedCell(0, Center(child: Text('${index + 1}'))),
          _fixedCell(
            1,
            Text(
              row.activityName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _fixedCell(
            2,
            _tablePicker(
              text: row.measurementType,
              hint: 'Select',
              onTap: _submitting ? null : () => _pickMeasureType(row),
            ),
          ),
          _fixedCell(
            3,
            _tablePicker(
              text: row.units,
              hint: 'Select',
              onTap: _submitting || units.isEmpty
                  ? null
                  : () => _pickMeasureUnits(row, units),
            ),
          ),
          _fixedCell(4, _numberCell(row.length, enabled: fields.length)),
          _fixedCell(5, _numberCell(row.breadth, enabled: fields.breadth)),
          _fixedCell(6, _numberCell(row.height, enabled: fields.height)),
          _fixedCell(7, _numberCell(row.weight, enabled: fields.weight)),
          _fixedCell(8, _numberCell(row.no, enabled: fields.no)),
          _fixedCell(9, _totalCell(row)),
          SizedBox(
            width: _measureWidths[10],
            child: IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              onPressed: _submitting
                  ? null
                  : () => unawaited(
                      _setActivities(
                        _selectedActivities
                            .where(
                              (WorkRfiOption option) =>
                                  option.id != row.activityId,
                            )
                            .toList(growable: false),
                      ),
                    ),
              icon: Icon(
                Icons.close_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fixedCell(int index, Widget child) {
    return SizedBox(
      width: _measureWidths[index],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: child,
      ),
    );
  }

  Widget _tablePicker({
    required String text,
    required String hint,
    required Future<void> Function()? onTap,
  }) {
    final bool hasValue = text.isNotEmpty;
    return _WorkRfiBox(
      enabled: onTap != null,
      selected: hasValue,
      onTap: onTap,
      radius: 8,
      minHeight: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        hasValue ? text : hint,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: _fieldText(
            context,
            enabled: onTap != null,
            hasValue: hasValue,
          ),
          fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _numberCell(
    TextEditingController controller, {
    required bool enabled,
  }) {
    if (!enabled) {
      final _FieldTone tone = _fieldTone(
        context,
        enabled: false,
        focused: false,
        selected: false,
      );
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: tone.fill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tone.border, width: tone.width),
        ),
      );
    }
    return _WorkRfiTextField(
      controller: controller,
      enabled: !_submitting,
      dense: true,
      radius: 8,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _totalCell(_MeasureRow row) {
    final num? total = workRfiTotalQty(
      measurementType: row.measurementType,
      length: row.length.text,
      breadth: row.breadth.text,
      height: row.height.text,
      weight: row.weight.text,
      no: row.no.text,
    );
    final _FieldTone tone = _fieldTone(
      context,
      enabled: true,
      focused: false,
      selected: false,
    );
    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: tone.fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tone.border, width: tone.width),
      ),
      child: Text(
        total == null ? '' : '$total',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _valueColor(context),
        ),
      ),
    );
  }

  Widget _actions() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            OutlinedButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(minimumSize: const Size(96, 40)),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(96, 40),
                backgroundColor: AppTheme.brandPrimary,
                foregroundColor: Colors.white,
              ),
              child: Text(_editing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    Widget? badge,
    required List<Widget> children,
  }) {
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
          Row(
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: palette.mutedText,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              if (badge != null) ...<Widget>[const SizedBox(width: 8), badge],
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _countBadge(int count) {
    final Color color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count selected',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _labeled(
    String label, {
    bool required = true,
    String? error,
    required Widget child,
  }) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text.rich(
            TextSpan(
              text: label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: palette.mutedText,
                fontWeight: FontWeight.w700,
              ),
              children: required
                  ? const <InlineSpan>[
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Color(0xFFDC2626)),
                      ),
                    ]
                  : const <InlineSpan>[],
            ),
          ),
          const SizedBox(height: 6),
          child,
          if (error != null && error.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              error,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _selectBox({
    Key? key,
    required String hint,
    required String? value,
    required bool enabled,
    required Future<void> Function()? onTap,
  }) {
    final bool hasValue = value != null && value.isNotEmpty;
    return _WorkRfiBox(
      key: key,
      enabled: enabled,
      selected: hasValue,
      onTap: onTap,
      child: Text(
        hasValue ? value : hint,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _fieldText(context, enabled: enabled, hasValue: hasValue),
          fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _multiBox({
    Key? key,
    required String hint,
    required List<WorkRfiOption> selected,
    required bool enabled,
    required Future<void> Function()? onTap,
    required ValueChanged<WorkRfiOption> onRemove,
    required VoidCallback? onClear,
  }) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color chipFill = dark
        ? const Color(0xFF9DC0F0)
        : AppTheme.brandPrimary;
    final Color chipText = dark ? const Color(0xFF071422) : Colors.white;
    return _WorkRfiBox(
      key: key,
      enabled: enabled,
      selected: selected.isNotEmpty,
      onTap: onTap,
      onClear: onClear,
      child: selected.isEmpty
          ? Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _fieldText(context, enabled: enabled, hasValue: false),
                fontWeight: FontWeight.w500,
              ),
            )
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final WorkRfiOption option in selected)
                  Chip(
                    label: Text(option.label),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: chipFill,
                    side: BorderSide(color: chipFill, width: 1.5),
                    labelStyle: TextStyle(
                      color: chipText,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    deleteIconColor: chipText,
                    deleteIcon: const Icon(Icons.close_rounded, size: 16),
                    onDeleted: enabled ? () => onRemove(option) : null,
                  ),
              ],
            ),
    );
  }

  Widget _iconBox({
    required String? text,
    required String hint,
    required IconData icon,
    required bool enabled,
    required Future<void> Function()? onTap,
  }) {
    final bool hasValue = text != null && text.isNotEmpty;
    return _WorkRfiBox(
      enabled: enabled,
      selected: hasValue,
      onTap: onTap,
      trailing: Icon(icon, size: 18),
      child: Text(
        hasValue ? text : hint,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _fieldText(context, enabled: enabled, hasValue: hasValue),
          fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _requiredRadio() {
    final bool chosen = _rfiRequired == 'Yes' || _rfiRequired == 'No';
    final _FieldTone tone = _fieldTone(
      context,
      enabled: !_submitting,
      focused: false,
      selected: chosen,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.fill,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: tone.border, width: tone.width),
        ),
        child: RadioGroup<String>(
          groupValue: _rfiRequired.isEmpty ? null : _rfiRequired,
          onChanged: _setRfiRequired,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _radioChoice('Yes'),
              _radioChoice('No'),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _radioChoice(String value) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool selected = _rfiRequired == value;
    final Color mark = dark ? const Color(0xFF9DC0F0) : AppTheme.brandPrimary;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? mark.withValues(alpha: dark ? 0.22 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? mark : Colors.transparent,
            width: selected ? 1.5 : 0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Radio<String>(
              value: value,
              visualDensity: VisualDensity.compact,
              fillColor: WidgetStateProperty.resolveWith((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return mark;
                }
                return dark ? const Color(0xFFB7C7DC) : const Color(0xFF64748B);
              }),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? mark : _valueColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickActivities() async {
    final List<String>? picked = await _pickMany(
      title: 'Activity',
      options: _activityOptions,
      selectedIds: <String>[
        for (final WorkRfiOption option in _selectedActivities) option.id,
      ],
      emptyMessage: 'No activities',
    );
    if (picked == null || !mounted) {
      return;
    }
    final Map<String, WorkRfiOption> byId = <String, WorkRfiOption>{
      for (final WorkRfiOption option in _activityOptions) option.id: option,
    };
    final List<WorkRfiOption> next = <WorkRfiOption>[];
    final Set<String> seen = <String>{};
    for (final WorkRfiOption option in _selectedActivities) {
      if (picked.contains(option.id) && seen.add(option.id)) {
        next.add(byId[option.id] ?? option);
      }
    }
    for (final String id in picked) {
      final WorkRfiOption? option = byId[id];
      if (option != null && seen.add(id)) {
        next.add(option);
      }
    }
    await _setActivities(next);
  }

  Future<void> _pickDescriptions() async {
    final List<String>? picked = await _pickMany(
      title: 'RFI Description',
      options: _descriptionOptions,
      selectedIds: _descriptionIds,
      emptyMessage: 'No descriptions',
    );
    if (picked == null || !mounted) {
      return;
    }
    await _setDescriptions(picked);
  }

  Future<void> _setDescriptions(List<String> ids) async {
    setState(() => _descriptionIds = ids);
    await _refreshEnclosures();
  }

  Future<void> _pickEnclosures() async {
    final List<String>? picked = await _pickMany(
      title: 'Enclosures',
      options: _enclosureOptions,
      selectedIds: _enclosureIds,
      emptyMessage: 'No enclosures',
    );
    if (picked == null || !mounted) {
      return;
    }
    await _setEnclosures(picked);
  }

  Future<void> _setEnclosures(List<String> ids) async {
    setState(() => _enclosureIds = ids);
  }

  Future<void> _pickTypeOfRfi() async {
    final List<WorkRfiOption> options =
        _typeOfRfi.isNotEmpty &&
            workRfiTypeOptions.every(
              (WorkRfiOption option) => option.id != _typeOfRfi,
            )
        ? <WorkRfiOption>[
            WorkRfiOption(id: _typeOfRfi, label: _typeOfRfi),
            ...workRfiTypeOptions,
          ]
        : workRfiTypeOptions;
    final String? picked = await _pickOne(
      title: 'Type of RFI',
      options: options,
      selectedId: _typeOfRfi,
      emptyMessage: 'No types',
    );
    if (picked == null || !mounted) {
      return;
    }
    final DateTime? previousDate = _inspectionDate;
    final DateTime? keptDate = workRfiInspectionDateAfterTypeChange(
      newType: picked,
      current: previousDate,
      today: _today(),
    );
    final bool cleared = previousDate != null && keptDate == null;
    setState(() {
      _typeOfRfi = picked;
      _inspectionDate = keptDate;
    });
    if (cleared) {
      final String rule =
          workRfiInspectionDateRuleError(
            typeOfRfi: picked,
            date: previousDate,
            today: _today(),
          ) ??
          'The chosen Date of Inspection does not fit this Type of RFI.';
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Date of Inspection cleared',
        message: '$rule Please choose the date again.',
      );
    }
  }

  Future<void> _pickInspectionDate() async {
    final DateTime today = _today();
    final DateTime? earliest = workRfiEarliestInspectionDate(
      typeOfRfi: _typeOfRfi,
      today: today,
    );
    if (earliest == null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Type of RFI',
        message: workRfiChooseTypeFirstMessage,
      );
      return;
    }
    final DateTime? current = _inspectionDate;
    // An unchanged saved past date on edit may sit before firstDate; open the
    // picker at the earliest allowed date instead of that stale value.
    final DateTime initial = current == null || current.isBefore(earliest)
        ? earliest
        : current;
    final DateTime? picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: initial,
      firstDate: earliest,
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _inspectionDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickRepresentative() async {
    final String? picked = await _pickOne(
      title: "Name of Contractor's Representative",
      options: _representatives,
      selectedId: _representativeId,
      emptyMessage: 'No representatives',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _representativeId = picked;
      _representativeName = _optionLabel(_representatives, picked) ?? picked;
    });
  }

  Future<void> _pickMeasureType(_MeasureRow row) async {
    final String? picked = await _pickOne(
      title: 'Type of Measurement',
      options: <WorkRfiOption>[
        for (final String type in workRfiMeasurementTypes)
          WorkRfiOption(id: type, label: type),
      ],
      selectedId: row.measurementType,
      emptyMessage: 'No types',
    );
    if (picked == null || !mounted) {
      return;
    }
    final List<String> units = workRfiUnitsFor(picked);
    final WorkRfiMeasureFields fields = workRfiFieldsFor(picked);
    setState(() {
      row.measurementType = picked;
      if (!units.contains(row.units)) {
        row.units = units.length == 1 ? units.first : '';
      }
      if (!fields.length) {
        row.length.clear();
      }
      if (!fields.breadth) {
        row.breadth.clear();
      }
      if (!fields.height) {
        row.height.clear();
      }
      if (!fields.weight) {
        row.weight.clear();
      }
      if (!fields.no) {
        row.no.clear();
      }
    });
  }

  Future<void> _pickMeasureUnits(_MeasureRow row, List<String> units) async {
    final String? picked = await _pickOne(
      title: 'Units',
      options: <WorkRfiOption>[
        for (final String unit in units) WorkRfiOption(id: unit, label: unit),
      ],
      selectedId: row.units,
      emptyMessage: 'No units',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => row.units = picked);
  }

  Future<void> _pickSingle({
    required String title,
    required List<WorkRfiOption> options,
    required String selectedId,
    required String emptyMessage,
    required Future<void> Function(String id) onPicked,
  }) async {
    final String? picked = await _pickOne(
      title: title,
      options: options,
      selectedId: selectedId,
      emptyMessage: emptyMessage,
    );
    if (picked == null || !mounted) {
      return;
    }
    await onPicked(picked);
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: current ?? _today(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    onPicked(DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: _inspectionTime ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _inspectionTime = picked);
  }

  Future<String?> _pickOne({
    required String title,
    required List<WorkRfiOption> options,
    required String selectedId,
    required String emptyMessage,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return _OptionPicker(
          title: title,
          options: options,
          selectedId: selectedId,
          emptyMessage: emptyMessage,
        );
      },
    );
  }

  Future<List<String>?> _pickMany({
    required String title,
    required List<WorkRfiOption> options,
    required List<String> selectedIds,
    required String emptyMessage,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return _MultiPicker(
          title: title,
          options: options,
          selectedIds: selectedIds,
          emptyMessage: emptyMessage,
        );
      },
    );
  }

  Future<WorkRfiLayerRange?> _readLayerRange(String structureType) async {
    try {
      return await _source.fetchLayerRange(structureType);
    } on Object catch (error) {
      if (!mounted) {
        return null;
      }
      await _showError('Layers unavailable', error);
      return null;
    }
  }

  Future<T?> _guard<T>(Future<T> future, String title) async {
    try {
      return await future;
    } on Object catch (error) {
      if (!mounted) {
        return null;
      }
      await _showError(title, error);
      return null;
    }
  }

  Future<void> _showError(String title, Object error) {
    return AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: title,
      message: error is DioException
          ? userFriendlyErrorMessage(error)
          : error.toString(),
    );
  }

  bool _chainageAlertOpen = false;

  void _onChainageChanged() {
    final String? fromError = workRfiChainageError(
      _chainageFrom.text,
      fieldLabel: 'Chainage From',
    );
    final String? toError = workRfiChainageError(
      _chainageTo.text,
      fieldLabel: 'Chainage To',
    );
    if (fromError == _chainageFromError && toError == _chainageToError) {
      return;
    }
    setState(() {
      _chainageFromError = fromError;
      _chainageToError = toError;
    });
  }

  Future<void> _alertChainage(String fieldLabel, String raw) async {
    final String? message = workRfiChainageError(raw, fieldLabel: fieldLabel);
    if (message == null || _chainageAlertOpen || !mounted) {
      return;
    }
    _chainageAlertOpen = true;
    await AppDialog.show(
      context,
      variant: AppDialogVariant.warning,
      title: fieldLabel,
      message: message,
    );
    _chainageAlertOpen = false;
  }

  void _setRfiRequired(String? value) {
    if (value == null || value == _rfiRequired || _submitting) {
      return;
    }
    setState(() => _rfiRequired = value);
    if (value == 'Yes' && _representatives.isEmpty) {
      unawaited(_loadRepresentatives());
    }
    if (value == 'Yes' && _descriptionIds.isNotEmpty) {
      unawaited(_refreshEnclosures());
    }
  }

  Future<void> _selectCreateDescription(String id) async {
    if (_descriptionIds.length == 1 && _descriptionIds.single == id) {
      return;
    }
    setState(() => _descriptionIds = <String>[id]);
    await _refreshEnclosures();
  }

  Future<void> _selectCreateActivity(String id) async {
    WorkRfiOption? match;
    for (final WorkRfiOption option in _activityOptions) {
      if (option.id == id) {
        match = option;
        break;
      }
    }
    if (match == null) {
      return;
    }
    final WorkRfiOption selected = match;
    if (_selectedActivities.length == 1 &&
        _selectedActivities.single.id == selected.id) {
      return;
    }
    await _setActivities(<WorkRfiOption>[selected]);
  }

  void _applyCreateActivity(String structureType) {
    _clearDescriptions();
    if (!workRfiIsEarthworkOrBlanketing(structureType)) {
      _activityOptions = <WorkRfiOption>[];
      _selectedActivities = <WorkRfiOption>[];
      return;
    }
    final String label =
        _optionLabel(_structureTypes, structureType) ?? structureType;
    final WorkRfiOption option = WorkRfiOption(id: structureType, label: label);
    _activityOptions = <WorkRfiOption>[option];
    _selectedActivities = <WorkRfiOption>[option];
    _replaceRows(<WorkRfiMeasurementDraft>[
      WorkRfiMeasurementDraft(
        activityId: option.id,
        activityName: option.label,
      ),
    ]);
  }

  Future<void> _loadLayers(String structureType) async {
    final int ticket = ++_layerTicket;
    if (!workRfiIsEarthworkOrBlanketing(structureType)) {
      if (!mounted || ticket != _layerTicket) {
        return;
      }
      setState(() {
        _layers = <WorkRfiOption>[];
        _layerId = '';
        _loadingLayers = false;
      });
      return;
    }
    if (mounted) {
      setState(() => _loadingLayers = true);
    }
    final WorkRfiLayerRange? range = await _readLayerRange(structureType);
    if (!mounted || ticket != _layerTicket) {
      return;
    }
    setState(() {
      _loadingLayers = false;
      _layers = range == null
          ? <WorkRfiOption>[]
          : workRfiLayerOptions(
              minLayer: range.minLayer,
              maxLayer: range.maxLayer,
            );
      if (!_layers.any((WorkRfiOption option) => option.id == _layerId)) {
        _layerId = '';
      }
    });
  }

  int _bump({bool resetDescriptions = true}) {
    if (resetDescriptions) {
      _descriptionTicket++;
      _enclosureTicket++;
    }
    return ++_cascade;
  }

  void _clearContracts() {
    _contractId = '';
    _contracts = <WorkRfiContractOption>[];
    _loadingContracts = false;
    _clearStructureTypes();
  }

  void _clearStructureTypes() {
    _structureType = '';
    _structureTypes = <WorkRfiOption>[];
    _loadingStructureTypes = false;
    _clearStructures();
    _clearChainageFields();
  }

  void _clearStructures() {
    _structureId = '';
    _structures = <WorkRfiOption>[];
    _loadingStructures = false;
    _clearComponents();
  }

  void _clearChainageFields() {
    _layerTicket++;
    _chainageFrom.clear();
    _chainageTo.clear();
    _chainageFromError = null;
    _chainageToError = null;
    _layerId = '';
    _layers = <WorkRfiOption>[];
    _loadingLayers = false;
  }

  void _clearComponents({bool preserveCreateActivity = false}) {
    _component = '';
    _components = <WorkRfiOption>[];
    _loadingComponents = false;
    _clearElements(preserveCreateActivity: preserveCreateActivity);
  }

  void _clearElements({bool preserveCreateActivity = false}) {
    _element = '';
    _elements = <WorkRfiOption>[];
    _loadingElements = false;
    if (preserveCreateActivity) {
      return;
    }
    _clearActivities();
  }

  void _clearActivities() {
    _activityOptions = <WorkRfiOption>[];
    _selectedActivities = <WorkRfiOption>[];
    _loadingActivities = false;
    _replaceRows(const <WorkRfiMeasurementDraft>[]);
    _clearDescriptions();
  }

  void _clearDescriptions() {
    _descriptionOptions = <WorkRfiOption>[];
    _descriptionIds = <String>[];
    _loadingDescriptions = false;
    _clearEnclosures();
  }

  void _clearEnclosures() {
    _enclosureOptions = <WorkRfiOption>[];
    _enclosureIds = <String>[];
    _loadingEnclosures = false;
  }

  void _replaceRows(List<WorkRfiMeasurementDraft> drafts) {
    final List<_MeasureRow> previous = _rows;
    _rows = <_MeasureRow>[
      for (final WorkRfiMeasurementDraft draft in drafts) _MeasureRow(draft),
    ];
    _dropRows(previous);
  }

  void _dropRows(List<_MeasureRow> rows) {
    if (rows.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final _MeasureRow row in rows) {
        row.dispose();
      }
    });
  }

  List<WorkRfiOption> _withRepresentative(List<WorkRfiOption> options) {
    if (_representativeId.isEmpty ||
        options.any((WorkRfiOption option) => option.id == _representativeId)) {
      return options;
    }
    return <WorkRfiOption>[
      WorkRfiOption(
        id: _representativeId,
        label: _representativeName.isEmpty
            ? _representativeId
            : _representativeName,
      ),
      ...options,
    ];
  }

  String? _contractLabel(String id) {
    for (final WorkRfiContractOption contract in _contracts) {
      if (contract.id == id) {
        return contract.label;
      }
    }
    return id.isEmpty ? null : id;
  }
}

const List<String> _measureLabels = <String>[
  'S. No.',
  'Activity',
  'Type of Measurement',
  'Units',
  'Length',
  'Breadth',
  'Height',
  'Weight',
  'No.',
  'Total Qty',
  '',
];

const List<double> _measureWidths = <double>[
  56,
  120,
  148,
  88,
  76,
  76,
  76,
  76,
  68,
  88,
  48,
];

class _MeasureRow {
  _MeasureRow(WorkRfiMeasurementDraft draft)
    : activityId = draft.activityId,
      activityName = draft.activityName,
      measurementType = workRfiMeasurementTypes.contains(draft.measurementType)
          ? draft.measurementType
          : '',
      units = _initialUnits(draft),
      length = TextEditingController(
        text: _shown(
          draft.measurementType,
          enabled: workRfiFieldsFor(draft.measurementType).length,
          raw: draft.length,
        ),
      ),
      breadth = TextEditingController(
        text: _shown(
          draft.measurementType,
          enabled: workRfiFieldsFor(draft.measurementType).breadth,
          raw: draft.breadth,
        ),
      ),
      height = TextEditingController(
        text: _shown(
          draft.measurementType,
          enabled: workRfiFieldsFor(draft.measurementType).height,
          raw: draft.height,
        ),
      ),
      weight = TextEditingController(
        text: _shown(
          draft.measurementType,
          enabled: workRfiFieldsFor(draft.measurementType).weight,
          raw: draft.weight,
        ),
      ),
      no = TextEditingController(
        text: _shown(
          draft.measurementType,
          enabled: workRfiFieldsFor(draft.measurementType).no,
          raw: draft.no,
        ),
      );

  final String activityId;
  String activityName;
  String measurementType;
  String units;
  final TextEditingController length;
  final TextEditingController breadth;
  final TextEditingController height;
  final TextEditingController weight;
  final TextEditingController no;
  bool _disposed = false;

  WorkRfiMeasurementDraft toDraft() {
    return WorkRfiMeasurementDraft(
      activityId: activityId,
      activityName: activityName,
      measurementType: measurementType,
      units: units,
      length: length.text,
      breadth: breadth.text,
      height: height.text,
      weight: weight.text,
      no: no.text,
    );
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    length.dispose();
    breadth.dispose();
    height.dispose();
    weight.dispose();
    no.dispose();
  }

  static String _initialUnits(WorkRfiMeasurementDraft draft) {
    final List<String> units = workRfiUnitsFor(draft.measurementType);
    if (units.contains(draft.units)) {
      return draft.units;
    }
    if (units.length == 1) {
      return units.first;
    }
    return '';
  }

  static String _shown(
    String type, {
    required bool enabled,
    required String raw,
  }) {
    if (!workRfiMeasurementTypes.contains(type) || !enabled) {
      return '';
    }
    return raw;
  }
}

String? _knownLabel(List<WorkRfiOption> options, String id) {
  for (final WorkRfiOption option in options) {
    if (option.id == id) {
      return option.label;
    }
  }
  return null;
}

String? _optionLabel(List<WorkRfiOption> options, String id) {
  return _knownLabel(options, id) ?? (id.isEmpty ? null : id);
}

List<WorkRfiOption> _optionsFor(List<WorkRfiOption> options, List<String> ids) {
  return <WorkRfiOption>[
    for (final String id in ids)
      WorkRfiOption(id: id, label: _optionLabel(options, id) ?? id),
  ];
}

List<WorkRfiOption> _ensureOption(
  List<WorkRfiOption> options,
  String id,
  String label,
) {
  if (id.isEmpty || options.any((WorkRfiOption option) => option.id == id)) {
    return options;
  }
  return <WorkRfiOption>[
    WorkRfiOption(id: id, label: label.isEmpty ? id : label),
    ...options,
  ];
}

List<WorkRfiContractOption> _ensureContract(
  List<WorkRfiContractOption> options,
  String id,
  String projectId,
) {
  if (id.isEmpty ||
      options.any((WorkRfiContractOption option) => option.id == id)) {
    return options;
  }
  return <WorkRfiContractOption>[
    WorkRfiContractOption(id: id, label: id, projectId: projectId),
    ...options,
  ];
}

List<WorkRfiOption> _dedupe(List<WorkRfiOption> options) {
  final Set<String> seen = <String>{};
  return <WorkRfiOption>[
    for (final WorkRfiOption option in options)
      if (option.id.isNotEmpty && seen.add(option.id)) option,
  ];
}

DateTime _today() {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

TimeOfDay? _timeOf(String raw) {
  final String api = workRfiApiTime(raw);
  if (api.isEmpty) {
    return null;
  }
  final List<String> parts = api.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

String _apiTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class _OptionPicker extends StatefulWidget {
  const _OptionPicker({
    required this.title,
    required this.options,
    required this.selectedId,
    required this.emptyMessage,
  });

  final String title;
  final List<WorkRfiOption> options;
  final String selectedId;
  final String emptyMessage;

  @override
  State<_OptionPicker> createState() => _OptionPickerState();
}

class _OptionPickerState extends State<_OptionPicker> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _search.text.trim().toLowerCase();
    final List<WorkRfiOption> visible = <WorkRfiOption>[
      for (final WorkRfiOption option in widget.options)
        if (query.isEmpty || option.label.toLowerCase().contains(query)) option,
    ];
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.55;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (widget.options.length > 8)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _WorkRfiTextField(
                controller: _search,
                hint: 'Search',
                dense: true,
                prefixIcon: Icons.search_rounded,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: visible.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.options.isEmpty
                          ? widget.emptyMessage
                          : 'No matches',
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      for (final WorkRfiOption option in visible)
                        ListTile(
                          selected: option.id == widget.selectedId,
                          selectedTileColor: _menuSelectedFill(context),
                          selectedColor: _menuSelectedInk(context),
                          title: Text(
                            option.label,
                            style: TextStyle(
                              fontWeight: option.id == widget.selectedId
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: option.id == widget.selectedId
                                  ? _menuSelectedInk(context)
                                  : _valueColor(context),
                            ),
                          ),
                          trailing: option.id == widget.selectedId
                              ? Icon(
                                  Icons.check_rounded,
                                  color: _menuSelectedInk(context),
                                )
                              : null,
                          onTap: () => Navigator.pop(context, option.id),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MultiPicker extends StatefulWidget {
  const _MultiPicker({
    required this.title,
    required this.options,
    required this.selectedIds,
    required this.emptyMessage,
  });

  final String title;
  final List<WorkRfiOption> options;
  final List<String> selectedIds;
  final String emptyMessage;

  @override
  State<_MultiPicker> createState() => _MultiPickerState();
}

class _MultiPickerState extends State<_MultiPicker> {
  final TextEditingController _search = TextEditingController();
  late final List<String> _selected = List<String>.from(widget.selectedIds);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _search.text.trim().toLowerCase();
    final List<WorkRfiOption> visible = <WorkRfiOption>[
      for (final WorkRfiOption option in widget.options)
        if (query.isEmpty || option.label.toLowerCase().contains(query)) option,
    ];
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                widget.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (widget.options.length > 8)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _WorkRfiTextField(
                  controller: _search,
                  hint: 'Search',
                  dense: true,
                  prefixIcon: Icons.search_rounded,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            Expanded(
              child: visible.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.options.isEmpty
                            ? widget.emptyMessage
                            : 'No matches',
                      ),
                    )
                  : Theme(
                      data: _menuCheckboxTheme(context),
                      child: ListView(
                        children: <Widget>[
                          for (final WorkRfiOption option in visible)
                            CheckboxListTile(
                              value: _selected.contains(option.id),
                              selected: _selected.contains(option.id),
                              selectedTileColor: _menuSelectedFill(context),
                              activeColor: _menuSelectedInk(context),
                              checkColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF071422)
                                  : Colors.white,
                              title: Text(
                                option.label,
                                style: TextStyle(
                                  fontWeight: _selected.contains(option.id)
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: _selected.contains(option.id)
                                      ? _menuSelectedInk(context)
                                      : _valueColor(context),
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (bool? checked) {
                                setState(() {
                                  if (checked ?? false) {
                                    if (!_selected.contains(option.id)) {
                                      _selected.add(option.id);
                                    }
                                  } else {
                                    _selected.remove(option.id);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(96, 40),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(96, 40),
                      backgroundColor: AppTheme.brandPrimary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldTone {
  const _FieldTone({
    required this.fill,
    required this.border,
    required this.width,
    required this.foreground,
  });

  final Color fill;
  final Color border;
  final double width;
  final Color foreground;
}

_FieldTone _fieldTone(
  BuildContext context, {
  required bool enabled,
  required bool focused,
  required bool selected,
}) {
  final bool dark = Theme.of(context).brightness == Brightness.dark;
  if (!enabled) {
    return dark
        ? const _FieldTone(
            fill: Color(0xFF102033),
            border: Color(0xFF3E5878),
            width: 1,
            foreground: Color(0xFFB7C7DC),
          )
        : const _FieldTone(
            fill: Color(0xFFE7EDF4),
            border: Color(0xFFC9D4E3),
            width: 1,
            foreground: Color(0xFF475569),
          );
  }
  if (focused) {
    return dark
        ? const _FieldTone(
            fill: Color(0xFF0E2A4A),
            border: Color(0xFF9DC0F0),
            width: 2,
            foreground: Color(0xFFF2F6FC),
          )
        : const _FieldTone(
            fill: Color(0xFFE7F0FA),
            border: Color(0xFF0B2F63),
            width: 2,
            foreground: Color(0xFF0F172A),
          );
  }
  if (selected) {
    return dark
        ? const _FieldTone(
            fill: Color(0xFF123055),
            border: Color(0xFF9DC0F0),
            width: 1.5,
            foreground: Color(0xFFF2F6FC),
          )
        : const _FieldTone(
            fill: Color(0xFFFFFFFF),
            border: Color(0xFF1E4F8A),
            width: 1.5,
            foreground: Color(0xFF0F172A),
          );
  }
  return dark
      ? const _FieldTone(
          fill: Color(0xFF10243C),
          border: Color(0xFF7A9CC4),
          width: 1,
          foreground: Color(0xFFB7C7DC),
        )
      : const _FieldTone(
          fill: Color(0xFFFFFFFF),
          border: Color(0xFFC5D2E2),
          width: 1,
          foreground: Color(0xFF64748B),
        );
}

Color _valueColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFF2F6FC)
      : const Color(0xFF0F172A);
}

Color _hintColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFB7C7DC)
      : const Color(0xFF64748B);
}

Color _fieldText(
  BuildContext context, {
  required bool enabled,
  required bool hasValue,
}) {
  if (!enabled) {
    return _fieldTone(
      context,
      enabled: false,
      focused: false,
      selected: false,
    ).foreground;
  }
  return hasValue ? _valueColor(context) : _hintColor(context);
}

Color _menuSelectedInk(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF9DC0F0)
      : AppTheme.brandPrimary;
}

Color _menuSelectedFill(BuildContext context) {
  final bool dark = Theme.of(context).brightness == Brightness.dark;
  return _menuSelectedInk(context).withValues(alpha: dark ? 0.22 : 0.1);
}

ThemeData _menuCheckboxTheme(BuildContext context) {
  final bool dark = Theme.of(context).brightness == Brightness.dark;
  final Color mark = _menuSelectedInk(context);
  return Theme.of(context).copyWith(
    checkboxTheme: CheckboxThemeData(
      side: BorderSide(color: mark, width: 1.5),
      checkColor: WidgetStatePropertyAll<Color>(
        dark ? const Color(0xFF071422) : Colors.white,
      ),
      fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return mark;
        }
        return Colors.transparent;
      }),
    ),
  );
}

class _WorkRfiBox extends StatefulWidget {
  const _WorkRfiBox({
    super.key,
    required this.enabled,
    required this.selected,
    required this.onTap,
    required this.child,
    this.onClear,
    this.trailing,
    this.radius = AppTheme.cardRadius,
    this.minHeight = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  final bool enabled;
  final bool selected;
  final Future<void> Function()? onTap;
  final Widget child;
  final VoidCallback? onClear;
  final Widget? trailing;
  final double radius;
  final double minHeight;
  final EdgeInsets padding;

  @override
  State<_WorkRfiBox> createState() => _WorkRfiBoxState();
}

class _WorkRfiBoxState extends State<_WorkRfiBox> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
  }

  @override
  void dispose() {
    _focus.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool focused = widget.enabled && _focus.hasFocus;
    final _FieldTone tone = _fieldTone(
      context,
      enabled: widget.enabled,
      focused: focused,
      selected: widget.selected,
    );
    final Color iconColor = !widget.enabled
        ? tone.foreground
        : focused
        ? tone.border
        : widget.selected
        ? _valueColor(context)
        : _hintColor(context);
    return Focus(
      focusNode: _focus,
      child: Material(
        color: tone.fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.radius),
          side: BorderSide(color: tone.border, width: tone.width),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.radius),
          onTap: widget.enabled && widget.onTap != null
              ? () async {
                  _focus.requestFocus();
                  await widget.onTap!();
                  if (mounted) {
                    _focus.requestFocus();
                  }
                }
              : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.minHeight),
            child: Padding(
              padding: widget.padding,
              child: IconTheme(
                data: IconThemeData(color: iconColor, size: 18),
                child: Row(
                  children: <Widget>[
                    Expanded(child: widget.child),
                    if (widget.onClear != null)
                      IconButton(
                        tooltip: 'Clear',
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.enabled ? widget.onClear : null,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: iconColor,
                        ),
                      ),
                    widget.trailing ??
                        Icon(Icons.arrow_drop_down_rounded, color: iconColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkRfiTextField extends StatefulWidget {
  const _WorkRfiTextField({
    required this.controller,
    this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.enabled = true,
    this.dense = false,
    this.radius = 12,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onUnfocus,
    this.prefixIcon,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? hint;
  final int minLines;
  final int maxLines;
  final bool enabled;
  final bool dense;
  final double radius;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onUnfocus;
  final IconData? prefixIcon;
  final TextInputAction? textInputAction;

  @override
  State<_WorkRfiTextField> createState() => _WorkRfiTextFieldState();
}

class _WorkRfiTextFieldState extends State<_WorkRfiTextField> {
  final FocusNode _focus = FocusNode();

  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(_WorkRfiTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  void _onFocus() {
    final bool hasFocus = _focus.hasFocus;
    final bool lostFocus = _focused && !hasFocus;
    _focused = hasFocus;
    _rebuild();
    if (lostFocus) {
      widget.onUnfocus?.call();
    }
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool focused = widget.enabled && _focus.hasFocus;
    final bool selected = widget.controller.text.trim().isNotEmpty;
    final _FieldTone tone = _fieldTone(
      context,
      enabled: widget.enabled,
      focused: focused,
      selected: selected,
    );
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      borderSide: BorderSide(color: tone.border, width: tone.width),
    );
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      enabled: widget.enabled,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction,
      style: TextStyle(
        fontSize: widget.dense ? 13 : null,
        color: _valueColor(context),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: _hintColor(context),
          fontWeight: FontWeight.w500,
          fontSize: widget.dense ? 13 : null,
        ),
        filled: true,
        fillColor: tone.fill,
        isDense: widget.dense,
        contentPadding: widget.dense
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(
                widget.prefixIcon,
                color: focused ? tone.border : _hintColor(context),
              ),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        disabledBorder: border,
      ),
      onChanged: widget.onChanged,
    );
  }
}
