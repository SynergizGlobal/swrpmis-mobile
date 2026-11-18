import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_button_lottie.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/quality_rfi_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/quality_rfi_form.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/work_rfi_form.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';

class QualityRfiFormPage extends ConsumerStatefulWidget {
  const QualityRfiFormPage({
    super.key,
    this.rfiId,
    this.rfiCode = '',
    this.readOnly = false,
  });

  final int? rfiId;
  final String rfiCode;
  final bool readOnly;

  @override
  ConsumerState<QualityRfiFormPage> createState() => _QualityRfiFormPageState();
}

class _QualityRfiFormPageState extends ConsumerState<QualityRfiFormPage> {
  final TextEditingController _description = TextEditingController();

  List<QualityRfiOption> _projects = const <QualityRfiOption>[];
  List<QualityRfiOption> _contracts = const <QualityRfiOption>[];
  List<QualityRfiOption> _structureTypes = const <QualityRfiOption>[];
  List<QualityRfiOption> _structures = const <QualityRfiOption>[];
  List<QualityRfiOption> _representatives = const <QualityRfiOption>[];
  List<QualityRfiOption> _rfiDescriptions = const <QualityRfiOption>[];
  List<QualityRfiOption> _enclosures = const <QualityRfiOption>[];
  List<String> _selectedDescriptionIds = <String>[];
  List<String> _selectedEnclosureIds = <String>[];

  String _projectId = '';
  String _contractId = '';
  String _structureType = '';
  String _structureId = '';
  String _action = qualityRfiFixedAction;
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
  bool _submitSuccess = false;
  bool _loadingContracts = false;
  bool _loadingStructureTypes = false;
  bool _loadingStructures = false;
  bool _loadingRepresentatives = false;
  bool _loadingEnclosures = false;
  String? _bootstrapError;

  int _contractTicket = 0;
  int _structureTypeTicket = 0;
  int _structureTicket = 0;
  int _repTicket = 0;
  int _enclosureTicket = 0;

  bool get _editing => widget.rfiId != null && !widget.readOnly;
  bool get _viewing => widget.rfiId != null && widget.readOnly;
  bool get _locked => _submitting || widget.readOnly;
  bool get _hierarchyLocked => _locked || _editing;
  bool get _typeLocked => _locked || _editing;
  bool get _representativeLocked =>
      _locked ||
      (_editing && !qualityRfiActionUnlocksRepresentative(_action));
  bool get _scheduleLocked =>
      _locked || (_editing && !qualityRfiActionUnlocksSchedule(_action));
  bool get _descriptionsLocked =>
      _locked ||
      (_editing && !qualityRfiActionUnlocksDescriptions(_action));
  bool get _descriptionTextLocked =>
      _locked ||
      (_editing && !qualityRfiActionUnlocksDescriptionText(_action));

  bool get _busy =>
      !_ready ||
      _submitting ||
      _loadingContracts ||
      _loadingStructureTypes ||
      _loadingStructures ||
      _loadingRepresentatives ||
      _loadingEnclosures;

  QualityRfiRemoteDataSource get _source =>
      ref.read(qualityRfiRemoteDataSourceProvider);

  @override
  void initState() {
    super.initState();
    if (widget.rfiId == null) {
      _submissionDate = DateTime.now();
      _action = qualityRfiFixedAction;
    } else if (_editing) {
      _action = qualityRfiDefaultEditAction;
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
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() {
        _bootstrapError = null;
        _ready = false;
      });
    }
    try {
      if (widget.rfiId != null) {
        await _loadDetail();
        return;
      }
      final List<Object> results = await Future.wait(<Future<Object>>[
        _source.fetchProjects(),
        _source.fetchDescriptions(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _projects = results[0] as List<QualityRfiOption>;
        _rfiDescriptions = results[1] as List<QualityRfiOption>;
        _bootstrapError = null;
        _ready = true;
      });
    } on Object catch (error, stackTrace) {
      debugPrint('Quality RFI bootstrap failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      setState(() {
        _bootstrapError = _errorMessage(error);
        _ready = false;
      });
    }
  }

  Future<void> _loadDetail() async {
    final List<Object> results = await Future.wait(<Future<Object>>[
      _source.fetchDetail(widget.rfiId!),
      _source.fetchProjects(),
      _source.fetchDescriptions(),
    ]);
    if (!mounted) {
      return;
    }
    final QualityRfiDetail detail = results[0] as QualityRfiDetail;
    _projects = results[1] as List<QualityRfiOption>;
    _rfiDescriptions = results[2] as List<QualityRfiOption>;

    _projectId = detail.project;
    _contractId = detail.contract;
    _structureType = detail.structureType;
    // Dropdown values must use structureId when the API also sends a label.
    _structureId = detail.structureId.isNotEmpty
        ? detail.structureId
        : detail.structure;
    _typeOfRfi = detail.typeOfRfi;
    _originalTypeOfRfi = detail.typeOfRfi;
    _originalDateOfInspection = detail.dateOfInspection;
    _representativeId = detail.userIdOfRepresentative;
    _description.text = detail.description;
    _submissionDate = parseWorkRfiDate(detail.dateOfSubmission);
    _inspectionDate = parseWorkRfiDate(detail.dateOfInspection);
    _inspectionTime = _parseTime(detail.timeOfInspection);
    _selectedDescriptionIds = List<String>.from(detail.rfiDescriptionList);
    _selectedEnclosureIds = List<String>.from(detail.enclosuresList);
    if (_editing) {
      _action = qualityRfiDefaultEditAction;
    } else {
      _action = detail.action.isEmpty ? qualityRfiFixedAction : detail.action;
    }

    if (detail.userIdOfRepresentative.isNotEmpty) {
      _representatives = <QualityRfiOption>[
        QualityRfiOption(
          id: detail.userIdOfRepresentative,
          label: detail.nameOfRepresentative.isEmpty
              ? detail.userIdOfRepresentative
              : detail.nameOfRepresentative,
        ),
      ];
    }

    if (_projectId.isNotEmpty) {
      try {
        _contracts = await _source.fetchContracts(_projectId);
      } on Object catch (error, stackTrace) {
        debugPrint('Quality RFI contracts failed: $error\n$stackTrace');
        _contracts = _ensureOption(
          const <QualityRfiOption>[],
          _contractId,
          _contractId,
        );
      }
    }
    if (_contractId.isNotEmpty) {
      try {
        final List<Object> extras = await Future.wait(<Future<Object>>[
          _source.fetchStructureTypes(_contractId),
          _source.fetchRepresentatives(_contractId),
        ]);
        _structureTypes = extras[0] as List<QualityRfiOption>;
        final List<QualityRfiOption> reps = extras[1] as List<QualityRfiOption>;
        if (reps.isNotEmpty) {
          _representatives = reps;
        }
      } on Object catch (error, stackTrace) {
        debugPrint('Quality RFI contract extras failed: $error\n$stackTrace');
        _structureTypes = _ensureOption(
          _structureTypes,
          _structureType,
          _structureType,
        );
      }
    }
    if (_contractId.isNotEmpty && _structureType.isNotEmpty) {
      try {
        _structures = await _source.fetchStructures(
          contractId: _contractId,
          structureType: _structureType,
        );
      } on Object catch (error, stackTrace) {
        debugPrint('Quality RFI structures failed: $error\n$stackTrace');
        _structures = const <QualityRfiOption>[];
      }
      _ensureStructureOption(detail);
    }
    await _loadEnclosures(keepSelection: true);

    if (!mounted) {
      return;
    }
    setState(() {
      _bootstrapError = null;
      _ready = true;
    });
  }

  List<QualityRfiOption> _ensureOption(
    List<QualityRfiOption> options,
    String id,
    String label,
  ) {
    if (id.isEmpty) {
      return options;
    }
    if (options.any((QualityRfiOption o) => o.id == id)) {
      return options;
    }
    return <QualityRfiOption>[
      ...options,
      QualityRfiOption(id: id, label: label.isEmpty ? id : label),
    ];
  }

  void _ensureStructureOption(QualityRfiDetail detail) {
    final String label = detail.structure.isNotEmpty &&
            detail.structure != _structureId
        ? detail.structure
        : _structureId;
    _structures = _ensureOption(_structures, _structureId, label);
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      return userFriendlyErrorMessage(error);
    }
    return error.toString();
  }

  Future<void> _onProjectChanged(String? projectId) async {
    if (projectId == null || projectId == _projectId || _hierarchyLocked) {
      return;
    }
    final int ticket = ++_contractTicket;
    setState(() {
      _projectId = projectId;
      _contractId = '';
      _structureType = '';
      _structureId = '';
      _representativeId = '';
      _contracts = const <QualityRfiOption>[];
      _structureTypes = const <QualityRfiOption>[];
      _structures = const <QualityRfiOption>[];
      _representatives = const <QualityRfiOption>[];
      _loadingContracts = true;
    });
    try {
      final List<QualityRfiOption> contracts =
          await _source.fetchContracts(projectId);
      if (!mounted || ticket != _contractTicket || projectId != _projectId) {
        return;
      }
      setState(() {
        _contracts = contracts;
        _loadingContracts = false;
      });
    } on Object catch (error) {
      if (!mounted || ticket != _contractTicket) {
        return;
      }
      setState(() => _loadingContracts = false);
      await _showError('Contracts unavailable', error);
    }
  }

  Future<void> _onContractChanged(String? contractId) async {
    if (contractId == null || contractId == _contractId || _hierarchyLocked) {
      return;
    }
    final int typeTicket = ++_structureTypeTicket;
    final int repTicket = ++_repTicket;
    setState(() {
      _contractId = contractId;
      _structureType = '';
      _structureId = '';
      _representativeId = '';
      _structureTypes = const <QualityRfiOption>[];
      _structures = const <QualityRfiOption>[];
      _representatives = const <QualityRfiOption>[];
      _loadingStructureTypes = true;
      _loadingRepresentatives = true;
    });
    try {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _source.fetchStructureTypes(contractId),
        _source.fetchRepresentatives(contractId),
      ]);
      if (!mounted || contractId != _contractId) {
        return;
      }
      if (typeTicket == _structureTypeTicket) {
        _structureTypes = results[0] as List<QualityRfiOption>;
        _loadingStructureTypes = false;
      }
      if (repTicket == _repTicket) {
        _representatives = results[1] as List<QualityRfiOption>;
        _loadingRepresentatives = false;
      }
      setState(() {});
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (typeTicket == _structureTypeTicket) {
          _loadingStructureTypes = false;
        }
        if (repTicket == _repTicket) {
          _loadingRepresentatives = false;
        }
      });
      await _showError('Contract details unavailable', error);
    }
  }

  Future<void> _onStructureTypeChanged(String? structureType) async {
    if (structureType == null ||
        structureType == _structureType ||
        _hierarchyLocked) {
      return;
    }
    final int ticket = ++_structureTicket;
    setState(() {
      _structureType = structureType;
      _structureId = '';
      _structures = const <QualityRfiOption>[];
      _loadingStructures = true;
    });
    try {
      final List<QualityRfiOption> structures = await _source.fetchStructures(
        contractId: _contractId,
        structureType: structureType,
      );
      if (!mounted ||
          ticket != _structureTicket ||
          structureType != _structureType) {
        return;
      }
      setState(() {
        _structures = structures;
        _loadingStructures = false;
      });
    } on Object catch (error) {
      if (!mounted || ticket != _structureTicket) {
        return;
      }
      setState(() => _loadingStructures = false);
      await _showError('Structures unavailable', error);
    }
  }

  Future<void> _onDescriptionsChanged(List<QualityRfiOption> selected) async {
    setState(() {
      _selectedDescriptionIds =
          selected.map((QualityRfiOption o) => o.id).toList();
      _selectedEnclosureIds = <String>[];
      _enclosures = const <QualityRfiOption>[];
    });
    await _loadEnclosures();
  }

  Future<void> _loadEnclosures({bool keepSelection = false}) async {
    final int ticket = ++_enclosureTicket;
    if (_selectedDescriptionIds.isEmpty) {
      setState(() {
        _enclosures = const <QualityRfiOption>[];
        if (!keepSelection) {
          _selectedEnclosureIds = <String>[];
        }
        _loadingEnclosures = false;
      });
      return;
    }
    setState(() => _loadingEnclosures = true);
    try {
      final List<String> labels = _rfiDescriptions
          .where(
            (QualityRfiOption o) => _selectedDescriptionIds.contains(o.id),
          )
          .map((QualityRfiOption o) => o.label)
          .toList();
      final List<QualityRfiOption> enc = await _source.fetchEnclosures(labels);
      if (!mounted || ticket != _enclosureTicket) {
        return;
      }
      setState(() {
        _enclosures = enc;
        if (keepSelection) {
          _selectedEnclosureIds = _selectedEnclosureIds
              .where(
                (String id) => enc.any((QualityRfiOption o) => o.id == id),
              )
              .toList();
        } else {
          _selectedEnclosureIds = <String>[];
        }
        _loadingEnclosures = false;
      });
    } on Object catch (error) {
      if (!mounted || ticket != _enclosureTicket) {
        return;
      }
      setState(() => _loadingEnclosures = false);
      if (!_viewing) {
        await _showError('Enclosures unavailable', error);
      }
    }
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

  Future<void> _pickInspectionDate() async {
    if (_scheduleLocked) {
      return;
    }
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
    if (picked != null && mounted) {
      setState(() {
        _inspectionDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickInspectionTime() async {
    if (_scheduleLocked) {
      return;
    }
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: _inspectionTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _inspectionTime = picked);
    }
  }

  QualityRfiSubmitDraft _draft() {
    return QualityRfiSubmitDraft(
      project: _projectId,
      contract: _contractId,
      structureType: _structureType,
      structure: _structureId,
      action: _editing ? _action : qualityRfiFixedAction,
      typeOfRfi: _typeOfRfi,
      contractorRepresentative: _representativeId,
      dateOfSubmission: _submissionDate == null
          ? ''
          : workRfiFormatApiDate(_submissionDate!),
      dateOfInspection: _inspectionDate == null
          ? ''
          : workRfiFormatApiDate(_inspectionDate!),
      timeOfInspection: _inspectionTime == null
          ? ''
          : _apiTime(_inspectionTime!),
      rfiDescriptions: List<String>.from(_selectedDescriptionIds),
      enclosures: List<String>.from(_selectedEnclosureIds),
      description: _description.text,
      editing: _editing,
      today: _today(),
      originalTypeOfRfi: _originalTypeOfRfi,
      originalDateOfInspection: _originalDateOfInspection,
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final QualityRfiSubmitDraft draft = _draft();
    final String? error = qualityRfiValidationMessage(draft);
    if (error != null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Validation',
        message: error,
      );
      return;
    }
    setState(() {
      _submitting = true;
      _submitSuccess = false;
    });
    try {
      final Map<String, dynamic> body = buildQualityRfiPayload(draft);
      final int? id = widget.rfiId;
      if (id == null) {
        await _source.create(body);
      } else {
        await _source.update(id, body);
      }
      if (!mounted) {
        return;
      }
      setState(() => _submitSuccess = true);
      await Future<void>.delayed(AppButtonLottie.successHold);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _submitSuccess = false;
      });
      await _showError(_editing ? 'Update failed' : 'Create failed', error);
    }
  }

  Future<void> _showError(String title, Object error) async {
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: title,
      message: _errorMessage(error),
    );
  }

  String _titleText() {
    final String code = widget.rfiCode.trim();
    if (_viewing) {
      return code.isEmpty
          ? 'View Quality/Safety RFI'
          : 'View Quality/Safety RFI ($code)';
    }
    if (_editing) {
      return code.isEmpty
          ? 'Edit Quality/Safety RFI'
          : 'Edit Quality/Safety RFI ($code)';
    }
    return 'Quality/Safety RFI';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(title: Text(_titleText())),
        body: Column(
          children: <Widget>[
            RfiContentLoader(
              loading: _busy && !_submitting && _bootstrapError == null,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_bootstrapError != null && !_ready) {
      return _bootstrapErrorPanel();
    }
    if (!_ready) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionLabel('Project *'),
          _dropdown(
            fieldKey: 'project',
            value: _projectId,
            items: _projects,
            hint: 'Select...',
            onChanged: _hierarchyLocked ? null : _onProjectChanged,
          ),
          const SizedBox(height: 16),
          _sectionLabel('Contract *'),
          _dropdown(
            fieldKey: 'contract',
            value: _contractId,
            items: _contracts,
            hint: _loadingContracts ? 'Loading...' : 'Select...',
            onChanged: _hierarchyLocked ? null : _onContractChanged,
          ),
          const SizedBox(height: 16),
          _sectionLabel('Structure Type *'),
          _dropdown(
            fieldKey: 'structureType',
            value: _structureType,
            items: _structureTypes,
            hint: _loadingStructureTypes ? 'Loading...' : 'Select...',
            onChanged: _hierarchyLocked ? null : _onStructureTypeChanged,
          ),
          const SizedBox(height: 16),
          _sectionLabel('Structure *'),
          _dropdown(
            fieldKey: 'structure',
            value: _structureId,
            items: _structures,
            hint: _loadingStructures ? 'Loading...' : 'Select Structure...',
            onChanged: _hierarchyLocked
                ? null
                : (String? id) {
                    if (id != null) {
                      setState(() => _structureId = id);
                    }
                  },
          ),
          const SizedBox(height: 16),
          _sectionLabel('RFI Description'),
          _multiSelectChips(
            options: _rfiDescriptions,
            selectedIds: _selectedDescriptionIds,
            hint: 'Select RFI description(s)...',
            onChanged: _descriptionsLocked ? null : _onDescriptionsChanged,
          ),
          const SizedBox(height: 16),
          _sectionLabel('Enclosures'),
          _multiSelectChips(
            options: _enclosures,
            selectedIds: _selectedEnclosureIds,
            hint: _loadingEnclosures ? 'Loading...' : 'Select enclosures...',
            onChanged: _descriptionsLocked
                ? null
                : (List<QualityRfiOption> selected) {
                    setState(() {
                      _selectedEnclosureIds = selected
                          .map((QualityRfiOption o) => o.id)
                          .toList();
                    });
                  },
          ),
          const SizedBox(height: 16),
          _sectionLabel('Action *'),
          if (_editing)
            _dropdown(
              fieldKey: 'action',
              value: _action,
              items: qualityRfiEditActions,
              hint: 'Select...',
              onChanged: _locked
                  ? null
                  : (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _action = value);
                    },
            )
          else
            _readOnlyField(qualityRfiFixedAction),
          const SizedBox(height: 16),
          _sectionLabel('Type of RFI'),
          _dropdown(
            fieldKey: 'typeOfRfi',
            value: _typeOfRfi,
            items: qualityRfiTypeOptions,
            hint: 'Select...',
            onChanged: _typeLocked
                ? null
                : (String? value) {
                    if (value != null) {
                      _onTypeOfRfiChanged(value);
                    }
                  },
          ),
          const SizedBox(height: 16),
          _sectionLabel("Name of Contractor's Representative *"),
          _dropdown(
            fieldKey: 'representative',
            value: _representativeId,
            items: _representatives,
            hint: _loadingRepresentatives
                ? 'Loading...'
                : 'Select Representative...',
            onChanged: _representativeLocked
                ? null
                : (String? value) {
                    if (value != null) {
                      setState(() => _representativeId = value);
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
            onTap: _scheduleLocked ? null : _pickInspectionDate,
          ),
          const SizedBox(height: 16),
          _sectionLabel('Time of Inspection *'),
          _timeTile(
            value: _inspectionTime,
            hint: '--:--',
            onTap: _scheduleLocked ? null : _pickInspectionTime,
          ),
          const SizedBox(height: 16),
          _sectionLabel('Description'),
          TextField(
            controller: _description,
            enabled: !_descriptionTextLocked,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Add Description',
              isDense: true,
            ),
          ),
          const SizedBox(height: 24),
          if (_viewing)
            Center(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 40),
                ),
                child: const Text('Close'),
              ),
            )
          else
            // AppTheme Size.fromHeight (infinite width) blanks the form in a Row.
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 40),
                    ),
                    child: AppAsyncButtonChild(
                      phase: _submitSuccess
                          ? AppButtonPhase.success
                          : _submitting
                          ? AppButtonPhase.loading
                          : AppButtonPhase.idle,
                      tone: AppButtonLottieTone.white,
                      child: Text(_editing ? 'Save Changes' : 'Create'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, 40),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bootstrapErrorPanel() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, color: scheme.error, size: 40),
            const SizedBox(height: 12),
            Text(
              _bootstrapError ?? 'Unable to load Quality/Safety RFI.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurface),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => unawaited(_bootstrap()),
              style: FilledButton.styleFrom(
                minimumSize: const Size(120, 40),
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final bool required = text.trimRight().endsWith('*');
    final String plain = required
        ? text.trimRight().substring(0, text.trimRight().length - 1).trimRight()
        : text;
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
    required String fieldKey,
    required String value,
    required List<QualityRfiOption> items,
    required String hint,
    required void Function(String?)? onChanged,
  }) {
    // Empty string must not match an accidental empty option id — that
    // assertion-crashes DropdownButtonFormField and blanks the screen.
    final List<QualityRfiOption> unique = <QualityRfiOption>[];
    final Set<String> seen = <String>{};
    for (final QualityRfiOption option in items) {
      if (option.id.isEmpty || !seen.add(option.id)) {
        continue;
      }
      unique.add(option);
    }
    final String? selected = value.isEmpty
        ? null
        : (unique.any((QualityRfiOption o) => o.id == value) ? value : null);
    return DropdownButtonFormField<String>(
      // fieldKey keeps sibling dropdowns unique even when item lists are empty.
      key: ValueKey<String>(
        'qdd_$fieldKey|${unique.map((QualityRfiOption o) => o.id).join('|')}|$selected',
      ),
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(isDense: true),
      hint: Text(hint),
      items: unique
          .map(
            (QualityRfiOption o) => DropdownMenuItem<String>(
              value: o.id,
              child: Text(o.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
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

  Widget _multiSelectChips({
    required List<QualityRfiOption> options,
    required List<String> selectedIds,
    required String hint,
    required void Function(List<QualityRfiOption>)? onChanged,
  }) {
    final List<QualityRfiOption> selected = options
        .where((QualityRfiOption o) => selectedIds.contains(o.id))
        .toList();
    return InkWell(
      onTap: onChanged == null || options.isEmpty
          ? null
          : () async {
              final List<QualityRfiOption> result =
                  await showDialog<List<QualityRfiOption>>(
                        context: context,
                        builder: (BuildContext ctx) {
                          return _QualityMultiSelectDialog(
                            options: options,
                            selected: List<QualityRfiOption>.from(selected),
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
                children: selected.map((QualityRfiOption item) {
                  return Chip(
                    label: Text(
                      item.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: onChanged == null
                        ? null
                        : () {
                            final List<QualityRfiOption> updated =
                                List<QualityRfiOption>.from(selected)
                                  ..removeWhere(
                                    (QualityRfiOption o) => o.id == item.id,
                                  );
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

  static String _apiTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay? _parseTime(String text) {
    final String api = workRfiApiTime(text);
    if (api.isEmpty) {
      return null;
    }
    final List<String> parts = api.split(':');
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

class _QualityMultiSelectDialog extends StatefulWidget {
  const _QualityMultiSelectDialog({
    required this.options,
    required this.selected,
  });

  final List<QualityRfiOption> options;
  final List<QualityRfiOption> selected;

  @override
  State<_QualityMultiSelectDialog> createState() =>
      _QualityMultiSelectDialogState();
}

class _QualityMultiSelectDialogState extends State<_QualityMultiSelectDialog> {
  late List<QualityRfiOption> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<QualityRfiOption>.from(widget.selected);
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
            final QualityRfiOption item = widget.options[index];
            final bool checked =
                _selected.any((QualityRfiOption o) => o.id == item.id);
            return CheckboxListTile(
              value: checked,
              title: Text(item.label),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    if (!_selected.any((QualityRfiOption o) => o.id == item.id)) {
                      _selected.add(item);
                    }
                  } else {
                    _selected.removeWhere(
                      (QualityRfiOption o) => o.id == item.id,
                    );
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
