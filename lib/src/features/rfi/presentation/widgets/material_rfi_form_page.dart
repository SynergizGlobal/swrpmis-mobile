import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/material_rfi_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/material_rfi_form.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/work_rfi_form.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';

class MaterialRfiFormPage extends ConsumerStatefulWidget {
  const MaterialRfiFormPage({
    super.key,
    this.rfiId,
    this.rfiCode = '',
    this.readOnly = false,
  });

  final int? rfiId;
  final String rfiCode;
  final bool readOnly;

  @override
  ConsumerState<MaterialRfiFormPage> createState() =>
      _MaterialRfiFormPageState();
}

class _MaterialRfiFormPageState extends ConsumerState<MaterialRfiFormPage> {
  final TextEditingController _batchLotNo = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _description = TextEditingController();

  List<MaterialRfiOption> _projects = const <MaterialRfiOption>[];
  List<MaterialRfiOption> _contracts = const <MaterialRfiOption>[];
  List<MaterialRfiOption> _inspectionItems = const <MaterialRfiOption>[];
  List<MaterialRfiOption> _inspectionTypes = const <MaterialRfiOption>[];
  List<MaterialRfiMaterial> _materials = const <MaterialRfiMaterial>[];
  List<MaterialRfiMaterial> _selectedMaterials = const <MaterialRfiMaterial>[];
  List<MaterialRfiOption> _representatives = const <MaterialRfiOption>[];
  List<MaterialRfiOption> _rfiDescriptions = const <MaterialRfiOption>[];
  List<MaterialRfiOption> _enclosures = const <MaterialRfiOption>[];
  List<String> _selectedDescriptionIds = <String>[];
  List<String> _selectedEnclosureIds = <String>[];
  List<_QtyRow> _qtyRows = <_QtyRow>[];

  String _projectId = '';
  String _contractId = '';
  String _itemId = '';
  String _typeOfRfi = '';
  // Date of Inspection rule (see workRfiInspectionDateRuleError).
  String _originalTypeOfRfi = '';
  String _originalDateOfInspection = '';
  String _representativeId = '';
  DateTime? _submissionDate;
  DateTime? _inspectionDate;
  TimeOfDay? _inspectionTime;

  bool _ready = false;
  bool _submitting = false;
  bool _loadingContracts = false;
  bool _loadingMaterials = false;
  bool _loadingRepresentatives = false;
  bool _loadingDescriptions = false;
  bool _loadingEnclosures = false;
  String? _bootstrapError;

  bool get _locked => _submitting || widget.readOnly;
  bool get _viewing => widget.rfiId != null && widget.readOnly;
  bool get _busy =>
      !_ready ||
      _submitting ||
      _loadingContracts ||
      _loadingMaterials ||
      _loadingRepresentatives ||
      _loadingDescriptions ||
      _loadingEnclosures;

  MaterialRfiRemoteDataSource get _source =>
      ref.read(materialRfiRemoteDataSourceProvider);

  @override
  void initState() {
    super.initState();
    if (widget.rfiId == null) {
      _submissionDate = DateTime.now();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_bootstrap());
      }
    });
  }

  @override
  void dispose() {
    _batchLotNo.dispose();
    _location.dispose();
    _description.dispose();
    for (final _QtyRow row in _qtyRows) {
      row.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_viewing) {
      await _loadDetail();
      return;
    }
    setState(() {
      _bootstrapError = null;
      _ready = false;
    });
    try {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _source.fetchProjects(),
        _source.fetchInspectionItems(),
        _source.fetchInspectionTypes(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _projects = results[0] as List<MaterialRfiOption>;
        _inspectionItems = results[1] as List<MaterialRfiOption>;
        _inspectionTypes = results[2] as List<MaterialRfiOption>;
        _bootstrapError = null;
        _ready = true;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ready = false;
        _bootstrapError = error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString();
      });
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _bootstrapError = null;
      _ready = false;
    });
    try {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _source.fetchDetail(widget.rfiId!),
        _source.fetchProjects(),
        _source.fetchInspectionItems(),
        _source.fetchInspectionTypes(),
      ]);
      if (!mounted) {
        return;
      }
      final MaterialRfiDetail detail = results[0] as MaterialRfiDetail;
      _projects = results[1] as List<MaterialRfiOption>;
      _inspectionItems = results[2] as List<MaterialRfiOption>;
      _inspectionTypes = results[3] as List<MaterialRfiOption>;

      _projectId = detail.projectId;
      _contractId = detail.contractId;
      _itemId = detail.itemId > 0 ? detail.itemId.toString() : '';
      _batchLotNo.text = detail.batchLotNo;
      _location.text = detail.location;
      _typeOfRfi = detail.typeOfRfi;
      _originalTypeOfRfi = detail.typeOfRfi;
      _originalDateOfInspection = detail.dateOfInspection;
      _representativeId = detail.representativeId;
      _description.text = detail.description;
      _submissionDate = _parseDate(detail.dateOfSubmission);
      _inspectionDate = _parseDate(detail.dateOfInspection);
      _inspectionTime = _parseTime(detail.timeOfInspection);
      _selectedDescriptionIds = List<String>.from(detail.rfiDescriptionList);
      _selectedEnclosureIds = List<String>.from(detail.enclosuresList);

      if (detail.representativeId.isNotEmpty) {
        _representatives = <MaterialRfiOption>[
          MaterialRfiOption(
            id: detail.representativeId,
            label: detail.representativeName.isEmpty
                ? detail.representativeId
                : detail.representativeName,
          ),
        ];
      }

      final List<Object> extra = await Future.wait(<Future<Object>>[
        if (detail.projectId.isNotEmpty)
          _source.fetchContracts(detail.projectId)
        else
          Future<List<MaterialRfiOption>>.value(const <MaterialRfiOption>[]),
        if (detail.itemId > 0)
          _source.fetchMaterials(detail.itemId)
        else
          Future<List<MaterialRfiMaterial>>.value(
            const <MaterialRfiMaterial>[],
          ),
      ]);
      if (!mounted) {
        return;
      }
      _contracts = extra[0] as List<MaterialRfiOption>;
      final List<MaterialRfiMaterial> allMats =
          extra[1] as List<MaterialRfiMaterial>;
      _materials = allMats;

      _resolveDetailMaterials(detail, allMats);
      await _resolveDetailDescriptionsAndEnclosures();

      setState(() {
        _bootstrapError = null;
        _ready = true;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ready = false;
        _bootstrapError = error is DioException
            ? userFriendlyErrorMessage(error)
            : error.toString();
      });
    }
  }

  void _resolveDetailMaterials(
    MaterialRfiDetail detail,
    List<MaterialRfiMaterial> allMats,
  ) {
    final Map<int, String> nameMap = <int, String>{
      for (final MaterialRfiMaterial m in allMats) m.id: m.name,
    };

    _selectedMaterials = detail.materials.map((MaterialRfiMaterial m) {
      final String name = nameMap[m.id] ?? 'Material ${m.id}';
      return MaterialRfiMaterial(id: m.id, name: name);
    }).toList();

    for (final _QtyRow row in _qtyRows) {
      row.controller.dispose();
    }
    _qtyRows = detail.materialQuantities.map((MaterialRfiQuantityRow q) {
      final String name = nameMap[q.materialId] ?? 'Material ${q.materialId}';
      return _QtyRow(
        materialId: q.materialId,
        materialName: name,
        controller: TextEditingController(text: q.quantity),
      );
    }).toList();
  }

  Future<void> _resolveDetailDescriptionsAndEnclosures() async {
    if (_selectedMaterials.isEmpty) {
      return;
    }
    try {
      final Set<String> seen = <String>{};
      final List<MaterialRfiOption> allDescs = <MaterialRfiOption>[];
      for (final MaterialRfiMaterial mat in _selectedMaterials) {
        final List<MaterialRfiOption> descs =
            await _source.fetchDescriptions(mat.id);
        for (final MaterialRfiOption d in descs) {
          if (seen.add(d.id)) {
            allDescs.add(d);
          }
        }
      }
      _rfiDescriptions = allDescs;

      final List<String> selectedLabels = allDescs
          .where((MaterialRfiOption o) =>
              _selectedDescriptionIds.contains(o.id))
          .map((MaterialRfiOption o) => o.label)
          .toList();
      if (selectedLabels.isNotEmpty) {
        _enclosures = await _source.fetchEnclosures(selectedLabels);
      }
    } on Object {
      // best-effort for view mode
    }
  }

  Future<void> _onProjectChanged(String? projectId) async {
    if (projectId == null || projectId == _projectId) {
      return;
    }
    setState(() {
      _projectId = projectId;
      _contractId = '';
      _contracts = const <MaterialRfiOption>[];
      _representatives = const <MaterialRfiOption>[];
      _representativeId = '';
      _loadingContracts = true;
    });
    try {
      final List<MaterialRfiOption> contracts =
          await _source.fetchContracts(projectId);
      if (!mounted || projectId != _projectId) {
        return;
      }
      setState(() {
        _contracts = contracts;
        _loadingContracts = false;
      });
    } on Object {
      if (mounted) {
        setState(() => _loadingContracts = false);
      }
    }
  }

  Future<void> _onContractChanged(String? contractId) async {
    if (contractId == null || contractId == _contractId) {
      return;
    }
    setState(() {
      _contractId = contractId;
      _representativeId = '';
      _representatives = const <MaterialRfiOption>[];
      _loadingRepresentatives = true;
    });
    try {
      final List<MaterialRfiOption> reps =
          await _source.fetchRepresentatives(contractId);
      if (!mounted || contractId != _contractId) {
        return;
      }
      setState(() {
        _representatives = reps;
        _loadingRepresentatives = false;
      });
    } on Object {
      if (mounted) {
        setState(() => _loadingRepresentatives = false);
      }
    }
  }

  Future<void> _onItemChanged(String? itemId) async {
    if (itemId == null || itemId == _itemId) {
      return;
    }
    setState(() {
      _itemId = itemId;
      _selectedMaterials = const <MaterialRfiMaterial>[];
      _materials = const <MaterialRfiMaterial>[];
      _rfiDescriptions = const <MaterialRfiOption>[];
      _selectedDescriptionIds = <String>[];
      _enclosures = const <MaterialRfiOption>[];
      _selectedEnclosureIds = <String>[];
      _clearQtyRows();
      _loadingMaterials = true;
    });
    try {
      final List<MaterialRfiMaterial> mats =
          await _source.fetchMaterials(int.parse(itemId));
      if (!mounted || itemId != _itemId) {
        return;
      }
      setState(() {
        _materials = mats;
        _loadingMaterials = false;
      });
    } on Object {
      if (mounted) {
        setState(() => _loadingMaterials = false);
      }
    }
  }

  void _onMaterialsChanged(List<MaterialRfiMaterial> selected) {
    setState(() {
      _selectedMaterials = selected;
      _rebuildQtyRows();
    });
    unawaited(_loadDescriptionsForMaterials());
  }

  Future<void> _loadDescriptionsForMaterials() async {
    if (_selectedMaterials.isEmpty) {
      setState(() {
        _rfiDescriptions = const <MaterialRfiOption>[];
        _selectedDescriptionIds = <String>[];
        _enclosures = const <MaterialRfiOption>[];
        _selectedEnclosureIds = <String>[];
      });
      return;
    }
    setState(() => _loadingDescriptions = true);
    try {
      final Set<String> seen = <String>{};
      final List<MaterialRfiOption> all = <MaterialRfiOption>[];
      for (final MaterialRfiMaterial mat in _selectedMaterials) {
        final List<MaterialRfiOption> descs =
            await _source.fetchDescriptions(mat.id);
        for (final MaterialRfiOption d in descs) {
          if (seen.add(d.id)) {
            all.add(d);
          }
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _rfiDescriptions = all;
        _selectedDescriptionIds = _selectedDescriptionIds
            .where((String id) => all.any((MaterialRfiOption o) => o.id == id))
            .toList();
        _loadingDescriptions = false;
      });
      await _loadEnclosures();
    } on Object {
      if (mounted) {
        setState(() => _loadingDescriptions = false);
      }
    }
  }

  Future<void> _loadEnclosures() async {
    if (_selectedDescriptionIds.isEmpty) {
      setState(() {
        _enclosures = const <MaterialRfiOption>[];
        _selectedEnclosureIds = <String>[];
      });
      return;
    }
    setState(() => _loadingEnclosures = true);
    try {
      final List<String> descriptionLabels = _rfiDescriptions
          .where((MaterialRfiOption o) =>
              _selectedDescriptionIds.contains(o.id))
          .map((MaterialRfiOption o) => o.label)
          .toList();
      final List<MaterialRfiOption> enc =
          await _source.fetchEnclosures(descriptionLabels);
      if (!mounted) {
        return;
      }
      setState(() {
        _enclosures = enc;
        _selectedEnclosureIds = _selectedEnclosureIds
            .where((String id) => enc.any((MaterialRfiOption o) => o.id == id))
            .toList();
        _loadingEnclosures = false;
      });
    } on Object {
      if (mounted) {
        setState(() => _loadingEnclosures = false);
      }
    }
  }

  void _rebuildQtyRows() {
    final Map<int, TextEditingController> existing =
        <int, TextEditingController>{};
    for (final _QtyRow row in _qtyRows) {
      existing[row.materialId] = row.controller;
    }
    _qtyRows = _selectedMaterials.map((MaterialRfiMaterial mat) {
      final TextEditingController controller =
          existing.remove(mat.id) ?? TextEditingController();
      return _QtyRow(
        materialId: mat.id,
        materialName: mat.name,
        controller: controller,
      );
    }).toList();
    for (final TextEditingController c in existing.values) {
      c.dispose();
    }
  }

  void _clearQtyRows() {
    for (final _QtyRow row in _qtyRows) {
      row.controller.dispose();
    }
    _qtyRows = <_QtyRow>[];
  }

  DateTime _today() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _onTypeOfRfiChanged(String picked) async {
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
    if (!cleared || !mounted) {
      return;
    }
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

  Future<void> _pickDate() async {
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
      initialDate: initial,
      firstDate: earliest,
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _inspectionDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _inspectionTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _inspectionTime = picked);
    }
  }

  String? _validate() {
    if (_projectId.isEmpty) {
      return 'Please select a Project.';
    }
    if (_contractId.isEmpty) {
      return 'Please select a Contract.';
    }
    if (_itemId.isEmpty) {
      return 'Please select an Item.';
    }
    if (_selectedMaterials.isEmpty) {
      return 'Please select at least one Material.';
    }
    if (_batchLotNo.text.trim().isEmpty) {
      return 'Please enter Batch/Lot No.';
    }
    if (_representativeId.isEmpty) {
      return "Please select Contractor's Representative.";
    }
    if (_inspectionDate == null) {
      return 'Please select Date of Inspection.';
    }
    final DateTime? original = _parseDate(_originalDateOfInspection);
    final bool unchangedSavedDate =
        original != null &&
        workRfiDateOnly(original) == workRfiDateOnly(_inspectionDate!) &&
        _originalTypeOfRfi.trim() == _typeOfRfi.trim();
    if (!unchangedSavedDate) {
      final String? dateRule = workRfiInspectionDateRuleError(
        typeOfRfi: _typeOfRfi,
        date: _inspectionDate,
        today: _today(),
      );
      if (dateRule != null) {
        return dateRule;
      }
    }
    if (_inspectionTime == null) {
      return 'Please select Time of Inspection.';
    }
    if (_selectedDescriptionIds.isEmpty) {
      return 'Please select at least one RFI Description.';
    }
    if (_selectedEnclosureIds.isEmpty) {
      return 'Please select at least one Enclosure.';
    }
    if (_description.text.trim().isEmpty) {
      return 'Please enter a Description.';
    }
    for (final _QtyRow row in _qtyRows) {
      if (row.controller.text.trim().isEmpty) {
        return 'Please enter Inspection Quantity for ${row.materialName}.';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final String? error = _validate();
    if (error != null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Validation',
        message: error,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final DateFormat dateFmt = DateFormat('dd-MM-yyyy');
      final String inspTime =
          '${_inspectionTime!.hour.toString().padLeft(2, '0')}:${_inspectionTime!.minute.toString().padLeft(2, '0')}';
      final Map<String, dynamic> body = <String, dynamic>{
        'projectId': _projectId,
        'contractId': _contractId,
        'itemId': int.parse(_itemId),
        'materials': _selectedMaterials.map((MaterialRfiMaterial m) {
          final _QtyRow? row = _qtyRows
              .cast<_QtyRow?>()
              .firstWhere(
                (_QtyRow? r) => r!.materialId == m.id,
                orElse: () => null,
              );
          return <String, dynamic>{
            'materialId': m.id,
            'materialName': m.name,
            'inspectionQty': row?.controller.text.trim() ?? '',
          };
        }).toList(),
        'batchLotNo': _batchLotNo.text.trim(),
        'location': _location.text.trim(),
        'action': 'Create',
        'typeOfRfi': _typeOfRfi,
        'representativeId': _representativeId,
        'dateOfSubmission': dateFmt.format(_submissionDate ?? DateTime.now()),
        'dateOfInspection': dateFmt.format(_inspectionDate!),
        'timeOfInspection': inspTime,
        'rfiDescriptionList': _selectedDescriptionIds,
        'enclosuresList': _selectedEnclosureIds,
        'description': _description.text.trim(),
      };
      await _source.create(body);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      await _showError('Create failed', error);
    }
  }

  Future<void> _showError(String title, Object error) async {
    final String message = error is DioException
        ? userFriendlyErrorMessage(error)
        : error.toString();
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: title,
      message: message,
    );
  }

  String _titleText() {
    if (_viewing) {
      final String code = widget.rfiCode.trim();
      return code.isEmpty ? 'View Material RFI' : 'View Material RFI ($code)';
    }
    return 'Material RFI';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_titleText())),
      body: Column(
        children: <Widget>[
          RfiContentLoader(loading: _busy && _bootstrapError == null),
          Expanded(child: _buildBody(palette)),
        ],
      ),
    );
  }

  Widget _buildBody(AppPalette palette) {
    if (_bootstrapError != null && !_ready) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _bootstrapError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => unawaited(_bootstrap()),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _sectionLabel('Project *'),
            _dropdown(
              fieldId: 'project',
              value: _projectId,
              items: _projects,
              hint: 'Select',
              onChanged: _locked ? null : _onProjectChanged,
            ),
            const SizedBox(height: 16),
            _sectionLabel('Contract *'),
            _dropdown(
              fieldId: 'contract',
              value: _contractId,
              items: _contracts,
              hint: _loadingContracts ? 'Loading...' : 'Select',
              onChanged: _locked ? null : _onContractChanged,
            ),
            const SizedBox(height: 16),
            _sectionLabel('Item *'),
            _dropdown(
              fieldId: 'item',
              value: _itemId,
              items: _inspectionItems,
              hint: 'Select',
              onChanged: _locked ? null : _onItemChanged,
            ),
            const SizedBox(height: 16),
            _sectionLabel('Material *'),
            _multiSelectChips<MaterialRfiMaterial>(
              options: _materials,
              selected: _selectedMaterials,
              labelOf: (MaterialRfiMaterial m) => m.name,
              hint: _loadingMaterials ? 'Loading...' : 'Select material(s)...',
              onChanged: _locked ? null : _onMaterialsChanged,
            ),
            const SizedBox(height: 16),
            _sectionLabel('Batch/Lot No. *'),
            TextField(
              controller: _batchLotNo,
              enabled: !_locked,
              decoration: const InputDecoration(
                hintText: 'Enter batch/lot number',
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Location'),
            TextField(
              controller: _location,
              enabled: !_locked,
              decoration: const InputDecoration(
                hintText: 'Location',
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Action *'),
            _readOnlyField('Create'),
            const SizedBox(height: 16),
            _sectionLabel('Type of RFI'),
            _dropdown(
              fieldId: 'typeOfRfi',
              value: _typeOfRfi,
              items: _inspectionTypes,
              hint: 'Select...',
              onChanged: _locked
                  ? null
                  : (String? v) {
                      if (v != null) {
                        _onTypeOfRfiChanged(v);
                      }
                    },
            ),
            const SizedBox(height: 16),
            _sectionLabel("Name of Contractor's Representative *"),
            _dropdown(
              fieldId: 'representative',
              value: _representativeId,
              items: _representatives,
              hint: _loadingRepresentatives
                  ? 'Loading...'
                  : 'Select Representative...',
              onChanged: _locked
                  ? null
                  : (String? v) {
                      if (v != null) {
                        setState(() => _representativeId = v);
                      }
                    },
            ),
            const SizedBox(height: 16),
            _sectionLabel('Date of Submission of RFI *'),
            _readOnlyField(
              _submissionDate != null
                  ? DateFormat('dd/MM/yyyy').format(_submissionDate!)
                  : '',
            ),
            const SizedBox(height: 16),
            _sectionLabel('Date of Inspection *'),
            _dateTile(
              value: _inspectionDate,
              hint: 'dd/mm/yyyy',
              onTap: _locked ? null : _pickDate,
            ),
            const SizedBox(height: 16),
            _sectionLabel('Time of Inspection *'),
            _timeTile(
              value: _inspectionTime,
              hint: '--:-- --',
              onTap: _locked ? null : _pickTime,
            ),
            const SizedBox(height: 16),
            _sectionLabel('RFI Description *'),
            _multiSelectChips<MaterialRfiOption>(
              options: _rfiDescriptions,
              selected: _rfiDescriptions
                  .where(
                    (MaterialRfiOption o) =>
                        _selectedDescriptionIds.contains(o.id),
                  )
                  .toList(),
              labelOf: (MaterialRfiOption o) => o.label,
              hint: _loadingDescriptions
                  ? 'Loading...'
                  : 'Select RFI description(s)...',
              onChanged: _locked
                  ? null
                  : (List<MaterialRfiOption> sel) {
                      setState(() {
                        _selectedDescriptionIds =
                            sel.map((MaterialRfiOption o) => o.id).toList();
                      });
                      unawaited(_loadEnclosures());
                    },
            ),
            const SizedBox(height: 16),
            _sectionLabel('Enclosures *'),
            _multiSelectChips<MaterialRfiOption>(
              options: _enclosures,
              selected: _enclosures
                  .where(
                    (MaterialRfiOption o) =>
                        _selectedEnclosureIds.contains(o.id),
                  )
                  .toList(),
              labelOf: (MaterialRfiOption o) => o.label,
              hint:
                  _loadingEnclosures ? 'Loading...' : 'Select enclosures...',
              onChanged: _locked
                  ? null
                  : (List<MaterialRfiOption> sel) {
                      setState(() {
                        _selectedEnclosureIds =
                            sel.map((MaterialRfiOption o) => o.id).toList();
                      });
                    },
            ),
            const SizedBox(height: 16),
            _sectionLabel('Description *'),
            TextField(
              controller: _description,
              enabled: !_locked,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter description',
                isDense: true,
              ),
            ),
            const SizedBox(height: 24),
            _materialQuantityTable(palette),
            if (!widget.readOnly) ...<Widget>[
              const SizedBox(height: 24),
              // AppTheme uses Size.fromHeight (infinite width). Inside a Row
              // that forces unbounded max-width and blanks the form — override.
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(120, 40),
                      ),
                      child: const Text('Create'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(120, 40),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.readOnly) ...<Widget>[
              const SizedBox(height: 24),
              Center(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 40),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final bool required = text.endsWith('*');
    final String plain = required ? text.substring(0, text.length - 2) : text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: plain,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          children: <InlineSpan>[
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppTheme.railwayRed),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String fieldId,
    required String value,
    required List<MaterialRfiOption> items,
    required String hint,
    required void Function(String?)? onChanged,
  }) {
    final List<MaterialRfiOption> unique = _uniqueDropdownOptions(items);
    final bool hasValue =
        value.isNotEmpty && unique.any((MaterialRfiOption o) => o.id == value);
    // Remount when the selected value or option set changes so
    // DropdownButtonFormField.initialValue stays in sync (Flutter 3.35+).
    return DropdownButtonFormField<String>(
      key: ValueKey<String>(
        'material-$fieldId-${hasValue ? value : 'none'}-${unique.length}',
      ),
      initialValue: hasValue ? value : null,
      isExpanded: true,
      decoration: const InputDecoration(isDense: true),
      hint: Text(hint),
      items: unique
          .map(
            (MaterialRfiOption o) => DropdownMenuItem<String>(
              value: o.id,
              child: Text(o.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  static List<MaterialRfiOption> _uniqueDropdownOptions(
    List<MaterialRfiOption> items,
  ) {
    final Set<String> seen = <String>{};
    return <MaterialRfiOption>[
      for (final MaterialRfiOption option in items)
        if (option.id.isNotEmpty && seen.add(option.id)) option,
    ];
  }

  Widget _readOnlyField(String text) {
    return InputDecorator(
      decoration: const InputDecoration(isDense: true, enabled: false),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _dateTile({
    required DateTime? value,
    required String hint,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
          enabled: onTap != null,
        ),
        child: Text(
          value != null ? DateFormat('dd/MM/yyyy').format(value) : hint,
          style: TextStyle(
            color: value != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _timeTile({
    required TimeOfDay? value,
    required String hint,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          suffixIcon: const Icon(Icons.access_time, size: 18),
          enabled: onTap != null,
        ),
        child: Text(
          value != null ? value.format(context) : hint,
          style: TextStyle(
            color: value != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _multiSelectChips<T>({
    required List<T> options,
    required List<T> selected,
    required String Function(T) labelOf,
    required String hint,
    required void Function(List<T>)? onChanged,
  }) {
    return InkWell(
      onTap: onChanged == null || options.isEmpty
          ? null
          : () async {
              final List<T> result = await showDialog<List<T>>(
                    context: context,
                    builder: (BuildContext ctx) {
                      return _MultiSelectDialog<T>(
                        options: options,
                        selected: List<T>.from(selected),
                        labelOf: labelOf,
                      );
                    },
                  ) ??
                  selected;
              onChanged(result);
            },
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
          enabled: onChanged != null,
        ),
        child: selected.isEmpty
            ? Text(
                hint,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              )
            : Wrap(
                spacing: 6,
                runSpacing: 4,
                children: selected.map((T item) {
                  return Chip(
                    label: Text(labelOf(item),
                        style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: onChanged == null
                        ? null
                        : () {
                            final List<T> updated = List<T>.from(selected)
                              ..remove(item);
                            onChanged(updated);
                          },
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _materialQuantityTable(AppPalette palette) {
    if (_selectedMaterials.isEmpty && _qtyRows.isEmpty) {
      return Column(
        children: <Widget>[
          _tableHeader(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Text(
              'Select Material',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.mutedText),
            ),
          ),
        ],
      );
    }
    return Column(
      children: <Widget>[
        _tableHeader(),
        for (int i = 0; i < _qtyRows.length; i++)
          _tableRow(i, _qtyRows[i], palette),
      ],
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: const BoxDecoration(color: AppTheme.brandPrimary),
      child: const Row(
        children: <Widget>[
          SizedBox(
            width: 50,
            child: Text(
              'S.No.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Material',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text.rich(
              TextSpan(
                text: 'Inspection Quantity ',
                children: <InlineSpan>[
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: AppTheme.railwayRed),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
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

  Widget _tableRow(int index, _QtyRow row, AppPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: palette.borderSubtle),
          right: BorderSide(color: palette.borderSubtle),
          bottom: BorderSide(color: palette.borderSubtle),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 50,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.materialName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.controller,
              enabled: !_locked,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static DateTime? _parseDate(String text) {
    if (text.isEmpty) {
      return null;
    }
    for (final String pattern in <String>[
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'dd/MM/yyyy',
    ]) {
      try {
        return DateFormat(pattern).parseStrict(text);
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  static TimeOfDay? _parseTime(String text) {
    if (text.isEmpty) {
      return null;
    }
    final List<String> parts = text.split(':');
    if (parts.length < 2) {
      return null;
    }
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }
}

class _QtyRow {
  _QtyRow({
    required this.materialId,
    required this.materialName,
    required this.controller,
  });

  final int materialId;
  final String materialName;
  final TextEditingController controller;
}

class _MultiSelectDialog<T> extends StatefulWidget {
  const _MultiSelectDialog({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
  });

  final List<T> options;
  final List<T> selected;
  final String Function(T) labelOf;

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late List<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<T>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.options.length,
          itemBuilder: (BuildContext context, int index) {
            final T item = widget.options[index];
            final bool checked = _selected.contains(item);
            return CheckboxListTile(
              value: checked,
              title: Text(widget.labelOf(item)),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selected.add(item);
                  } else {
                    _selected.remove(item);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(widget.selected),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
