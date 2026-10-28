import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/contracts/data/datasources/contract_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/contracts/domain/contract_form.dart';
import 'package:swr_pmis_mobile/src/features/contracts/presentation/providers/contract_form_provider.dart';

class AddContractFormPage extends ConsumerStatefulWidget {
  const AddContractFormPage({super.key});

  static const String routeName = 'add-contract-form';
  static const String routePath = '/module/contracts/add';

  @override
  ConsumerState<AddContractFormPage> createState() =>
      _AddContractFormPageState();
}

class _AddContractFormPageState extends ConsumerState<AddContractFormPage> {
  static const int _textMaxChars = 1000;

  final TextEditingController _shortName = TextEditingController();
  final TextEditingController _contractName = TextEditingController();
  final TextEditingController _ifasCode = TextEditingController();
  final TextEditingController _scope = TextEditingController();
  final TextEditingController _loaLetterNo = TextEditingController();
  final TextEditingController _estimatedCost = TextEditingController();
  final TextEditingController _remarks = TextEditingController();
  final TextEditingController _closureRemarks = TextEditingController();

  ContractFormMaster _master = ContractFormMaster.empty;
  List<ContractFormOption> _workStatuses = const <ContractFormOption>[];
  bool _seeded = false;
  bool _reportedLoadError = false;
  bool _saving = false;
  int _stepIndex = 0;

  String _projectId = '';
  String _contractAwarded = 'No';
  String _hodId = '';
  String _dyHodId = '';
  String _departmentId = '';
  String _bankFunded = 'No';
  String _bankName = '';
  String _reviewType = '';
  String _contractType = '';
  String _contractorId = '';
  String _workStatus = '';
  String _costUnit = 'Rupees';
  DateTime? _loaDate;
  DateTime? _plannedAward;
  DateTime? _plannedCompletion;
  DateTime? _nitDate;
  DateTime? _tenderOpening;
  DateTime? _techEval;
  DateTime? _finEval;

  String _bgRequired = 'No';
  String _insuranceRequired = 'No';
  String _milestoneRequired = 'No';
  String _milestoneRevisionRequired = 'No';
  String _keyPersonnelRequired = 'No';

  final List<_ExecutiveDraft> _executives = <_ExecutiveDraft>[_ExecutiveDraft()];
  final List<_RevisionDraft> _revisions = <_RevisionDraft>[
    _RevisionDraft(revisionNo: 'R1'),
  ];
  final List<_BgDraft> _bankGuarantees = <_BgDraft>[_BgDraft()];
  final List<_InsuranceDraft> _insurances = <_InsuranceDraft>[_InsuranceDraft()];
  final List<_DocumentDraft> _documents = <_DocumentDraft>[_DocumentDraft()];

  AddContractStep get _step => AddContractStepX.all[_stepIndex];

  bool get _isLastStep => _stepIndex >= AddContractStepX.all.length - 1;

  @override
  void dispose() {
    _shortName.dispose();
    _contractName.dispose();
    _ifasCode.dispose();
    _scope.dispose();
    _loaLetterNo.dispose();
    _estimatedCost.dispose();
    _remarks.dispose();
    _closureRemarks.dispose();
    for (final _ExecutiveDraft draft in _executives) {
      draft.dispose();
    }
    for (final _RevisionDraft draft in _revisions) {
      draft.dispose();
    }
    for (final _BgDraft draft in _bankGuarantees) {
      draft.dispose();
    }
    for (final _InsuranceDraft draft in _insurances) {
      draft.dispose();
    }
    for (final _DocumentDraft draft in _documents) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _seed(ContractFormMaster master) async {
    if (_seeded) {
      return;
    }
    _master = master;
    _workStatuses = master.workStatuses;
    _costUnit = master.units.isNotEmpty ? master.units.first.id : 'Rupees';
    _seeded = true;
    if (mounted) {
      setState(() {});
    }
    await _reloadStatusesForAwarded(preserve: true);
  }

  Future<void> _reportLoadError(Object error) async {
    if (_reportedLoadError || !mounted) {
      return;
    }
    _reportedLoadError = true;
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: 'Add Contract',
      message: error is DioException
          ? userFriendlyErrorMessage(error)
          : error.toString(),
    );
  }

  Future<void> _retry() {
    _reportedLoadError = false;
    ref.invalidate(contractFormMasterProvider);
    return Future<void>.value();
  }

  Future<void> _reloadStatusesForAwarded({required bool preserve}) async {
    final String previous = _workStatus;
    try {
      final List<ContractFormOption> statuses = await ref
          .read(contractRemoteDataSourceProvider)
          .fetchFormStatusesForAwarded(contractAwarded: _contractAwarded);
      if (!mounted) {
        return;
      }
      setState(() {
        _workStatuses = statuses.isNotEmpty ? statuses : _master.workStatuses;
        if (preserve) {
          _workStatus = _match(_workStatuses, previous);
        } else {
          _workStatus = '';
        }
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _workStatuses = _master.workStatuses;
        if (!preserve) {
          _workStatus = '';
        }
      });
    }
  }

  String _match(List<ContractFormOption> options, String raw) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    for (final ContractFormOption option in options) {
      if (option.id == value ||
          option.label.toLowerCase() == value.toLowerCase()) {
        return option.id;
      }
    }
    return value;
  }

  String? _validateStep(AddContractStep step) {
    switch (step) {
      case AddContractStep.managers:
        if (_projectId.trim().isEmpty) {
          return 'Please select a project.';
        }
        if (_contractAwarded.trim().isEmpty) {
          return 'Please select Contract Awarded.';
        }
        if (_hodId.trim().isEmpty) {
          return 'Please select HOD.';
        }
        if (_dyHodId.trim().isEmpty) {
          return 'Please select Dy HOD.';
        }
        if (_departmentId.trim().isEmpty) {
          return 'Please select Contract Department.';
        }
        if (_bankFunded == 'Yes' && _bankName.trim().isEmpty) {
          return 'Please select Bank Name.';
        }
        return null;
      case AddContractStep.executives:
        return null;
      case AddContractStep.details:
        if (_shortName.text.trim().isEmpty) {
          return 'Please enter Contract Short Name.';
        }
        if (_contractName.text.trim().isEmpty) {
          return 'Please enter Contract Name.';
        }
        if (_workStatus.trim().isEmpty) {
          return 'Please select Status of Work.';
        }
        return null;
      case AddContractStep.closure:
        return null;
      case AddContractStep.bankGuarantee:
        if (_bgRequired == 'Yes') {
          for (final _BgDraft draft in _bankGuarantees) {
            if (draft.bgType.trim().isEmpty) {
              return 'Please select BG Type for each bank guarantee.';
            }
            if (draft.expiryDate == null) {
              return 'Please select Expiry Date for each bank guarantee.';
            }
          }
        }
        return null;
      case AddContractStep.insurance:
        if (_insuranceRequired == 'Yes') {
          for (final _InsuranceDraft draft in _insurances) {
            if (draft.insuranceType.trim().isEmpty) {
              return 'Please select Insurance Type for each row.';
            }
            if (draft.validUpto == null) {
              return 'Please select Valid Upto for each insurance.';
            }
          }
        }
        return null;
      case AddContractStep.milestone:
      case AddContractStep.keyPersonnel:
      case AddContractStep.documents:
        return null;
    }
  }

  Future<void> _goNext() async {
    final String? message = _validateStep(_step);
    if (message != null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: 'Required',
        message: message,
      );
      return;
    }
    if (_isLastStep) {
      await _submit();
      return;
    }
    setState(() => _stepIndex += 1);
  }

  void _goPrevious() {
    if (_stepIndex <= 0) {
      return;
    }
    setState(() => _stepIndex -= 1);
  }

  Map<String, String> _buildFields() {
    return <String, String>{
      'project_id_fk': _projectId.trim(),
      'contract_awarded': _contractAwarded.trim(),
      'hod_user_id_fk': _hodId.trim(),
      'dy_hod_user_id_fk': _dyHodId.trim(),
      'department_fk': _departmentId.trim(),
      'bank_funded': _bankFunded.trim(),
      'bank_name': _bankName.trim(),
      'type_of_review': _reviewType.trim(),
      'contract_short_name': _shortName.text.trim(),
      'contract_name': _contractName.text.trim(),
      'contract_type_fk': _contractType.trim(),
      'contractor_id_fk': _contractorId.trim(),
      'contract_ifas_code': _ifasCode.text.trim(),
      'scope_of_contract': _scope.text.trim(),
      'loa_letter_no': _loaLetterNo.text.trim(),
      'loa_date': formatContractApiDate(_loaDate),
      'status_of_work': _workStatus.trim(),
      'detailed_estimated_cost': _estimatedCost.text.trim(),
      'estimated_cost_units': _costUnit.trim(),
      'planned_date_of_award': formatContractApiDate(_plannedAward),
      'planned_date_of_completion': formatContractApiDate(_plannedCompletion),
      'notice_inviting_tender': formatContractApiDate(_nitDate),
      'tender_opening_date': formatContractApiDate(_tenderOpening),
      'technical_eval_submission': formatContractApiDate(_techEval),
      'financial_eval_submission': formatContractApiDate(_finEval),
      'remarks': _remarks.text.trim(),
      'closure_remarks': _closureRemarks.text.trim(),
      'bank_guarantee_required': _bgRequired.trim(),
      'insurance_required': _insuranceRequired.trim(),
      'milestone_required': _milestoneRequired.trim(),
      'milestone_revision_required': _milestoneRevisionRequired.trim(),
      'key_personnel_required': _keyPersonnelRequired.trim(),
    };
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    for (final AddContractStep step in AddContractStepX.all) {
      final String? message = _validateStep(step);
      if (message != null) {
        setState(() => _stepIndex = AddContractStepX.all.indexOf(step));
        await AppDialog.show(
          context,
          variant: AppDialogVariant.info,
          title: 'Required',
          message: message,
        );
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final List<String> execDepts = <String>[];
      final List<String> execUsers = <String>[];
      for (final _ExecutiveDraft draft in _executives) {
        if (draft.departmentId.trim().isEmpty &&
            draft.executiveIds.isEmpty) {
          continue;
        }
        execDepts.add(draft.departmentId.trim());
        execUsers.add(draft.executiveIds.join(','));
      }
      final List<({String path, String fileName})> files =
          <({String path, String fileName})>[];
      for (final _DocumentDraft draft in _documents) {
        final String? path = draft.filePath;
        if (path == null || path.isEmpty) {
          continue;
        }
        files.add((
          path: path,
          fileName: draft.fileName.isEmpty ? p.basename(path) : draft.fileName,
        ));
      }
      final String message = await ref
          .read(contractRemoteDataSourceProvider)
          .addContract(
            fields: _buildFields(),
            files: files,
            executiveDepartments: execDepts,
            executiveUserIds: execUsers,
          );
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Add Contract',
        message: message,
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
        title: 'Add Contract',
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
    final AsyncValue<ContractFormMaster> masterAsync = ref.watch(
      contractFormMasterProvider,
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
      final ContractFormMaster master = masterAsync.requireValue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _seeded) {
          return;
        }
        _seed(master);
      });
    }

    return PopScope(
      canPop: _stepIndex == 0 && !_saving,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop || _saving) {
          return;
        }
        if (_stepIndex > 0) {
          _goPrevious();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add Contract · ${_step.shortTitle}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _saving
                ? null
                : () {
                    if (_stepIndex > 0) {
                      _goPrevious();
                    } else if (context.canPop()) {
                      context.pop(false);
                    }
                  },
          ),
        ),
        body: loadError != null
            ? _ErrorBody(onRetry: _retry)
            : !ready || !_seeded
            ? const Center(child: CircularProgressIndicator())
            : _body(),
      ),
    );
  }

  Widget _body() {
    return Column(
      children: <Widget>[
        _stepHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: <Widget>[_stepContent()],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: <Widget>[
                if (_stepIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _goPrevious,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_stepIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _goNext,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isLastStep ? 'Submit' : 'Next'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => context.pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFD6E4F5),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            _step.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.brandPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AddContractStepX.all.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final AddContractStep step = AddContractStepX.all[index];
                final bool active = index == _stepIndex;
                final bool done = index < _stepIndex;
                return ChoiceChip(
                  label: Text(step.shortTitle),
                  selected: active,
                  onSelected: _saving
                      ? null
                      : (bool selected) {
                          if (!selected) {
                            return;
                          }
                          if (index > _stepIndex) {
                            final String? message = _validateStep(_step);
                            if (message != null) {
                              AppDialog.show(
                                context,
                                variant: AppDialogVariant.info,
                                title: 'Required',
                                message: message,
                              );
                              return;
                            }
                          }
                          setState(() => _stepIndex = index);
                        },
                  selectedColor: AppTheme.brandPrimary,
                  labelStyle: TextStyle(
                    color: active
                        ? Colors.white
                        : done
                        ? AppTheme.brandPrimary
                        : null,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Step ${_stepIndex + 1} of ${AddContractStepX.all.length}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case AddContractStep.managers:
        return _managersStep();
      case AddContractStep.executives:
        return _executivesStep();
      case AddContractStep.details:
        return _detailsStep();
      case AddContractStep.closure:
        return _closureStep();
      case AddContractStep.bankGuarantee:
        return _bgStep();
      case AddContractStep.insurance:
        return _insuranceStep();
      case AddContractStep.milestone:
        return _milestoneStep();
      case AddContractStep.keyPersonnel:
        return _keyPersonnelStep();
      case AddContractStep.documents:
        return _documentsStep();
    }
  }

  Widget _managersStep() {
    return _fieldGrid(<Widget>[
      _dropdown(
        label: 'Project *',
        options: _master.projects,
        selectedId: _projectId,
        onPick: (String id) => setState(() => _projectId = id),
      ),
      _radioYesNo(
        label: 'Contract Awarded *',
        value: _contractAwarded,
        onChanged: (String value) async {
          setState(() => _contractAwarded = value);
          await _reloadStatusesForAwarded(preserve: false);
        },
      ),
      _dropdown(
        label: 'HOD *',
        options: _master.hods,
        selectedId: _hodId,
        onPick: (String id) => setState(() => _hodId = id),
      ),
      _dropdown(
        label: 'Dy HOD *',
        options: _master.dyHods,
        selectedId: _dyHodId,
        onPick: (String id) => setState(() => _dyHodId = id),
      ),
      _dropdown(
        label: 'Contract Department *',
        options: _master.departments,
        selectedId: _departmentId,
        onPick: (String id) => setState(() => _departmentId = id),
      ),
      _radioYesNo(
        label: 'Bank Funded',
        value: _bankFunded,
        onChanged: (String value) => setState(() {
          _bankFunded = value;
          if (value != 'Yes') {
            _bankName = '';
            _reviewType = '';
          }
        }),
      ),
      if (_bankFunded == 'Yes') ...<Widget>[
        _dropdown(
          label: 'Bank Name',
          options: _master.banks,
          selectedId: _bankName,
          onPick: (String id) => setState(() => _bankName = id),
        ),
        _dropdown(
          label: 'Type of Review',
          options: _master.reviewTypes,
          selectedId: _reviewType,
          onPick: (String id) => setState(() => _reviewType = id),
        ),
      ],
    ]);
  }

  Widget _executivesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _sectionTitle('Executives'),
        for (int i = 0; i < _executives.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: <Widget>[
                  _dropdown(
                    label: 'Department',
                    options: _master.departments,
                    selectedId: _executives[i].departmentId,
                    onPick: (String id) {
                      setState(() {
                        _executives[i].departmentId = id;
                        _executives[i].executiveIds.clear();
                      });
                    },
                  ),
                  _multiSelect(
                    label: 'Select Executives',
                    options: _executivesForDept(_executives[i].departmentId),
                    selectedIds: _executives[i].executiveIds,
                    enabled: _executives[i].departmentId.isNotEmpty,
                    emptyHint: 'Select Department first',
                    onChanged: (List<String> ids) {
                      setState(() {
                        _executives[i].executiveIds
                          ..clear()
                          ..addAll(ids);
                      });
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Remove',
                      onPressed: () {
                        setState(() {
                          _executives[i].dispose();
                          _executives.removeAt(i);
                          if (_executives.isEmpty) {
                            _executives.add(_ExecutiveDraft());
                          }
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFC1121F),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Center(
          child: IconButton(
            tooltip: 'Add executive row',
            onPressed: () => setState(() => _executives.add(_ExecutiveDraft())),
            style: IconButton.styleFrom(
              backgroundColor: AppPalette.of(context).success,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.playlist_add_rounded),
          ),
        ),
      ],
    );
  }

  List<ContractFormOption> _executivesForDept(String departmentId) {
    final String dept = departmentId.trim();
    if (dept.isEmpty) {
      return const <ContractFormOption>[];
    }
    final List<ContractFormOption>? mapped =
        _master.executivesByDepartment[dept];
    if (mapped != null && mapped.isNotEmpty) {
      return mapped;
    }
    final List<ContractFormOption> filtered = _master.responsiblePeople
        .where(
          (ContractFormOption o) =>
              o.meta.isEmpty ||
              o.meta == dept ||
              o.meta.toLowerCase() == dept.toLowerCase(),
        )
        .toList(growable: false);
    return filtered.isEmpty ? _master.responsiblePeople : filtered;
  }

  Widget _detailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _fieldGrid(<Widget>[
          _text(
            _shortName,
            label: 'Contract Short Name *',
            hint: 'Enter short name',
            maxLength: 100,
          ),
          _text(
            _contractName,
            label: 'Contract Name *',
            hint: 'Enter contract name',
            maxLines: 3,
            maxLength: _textMaxChars,
          ),
          _dropdown(
            label: 'Contract Type',
            options: _master.contractTypes,
            selectedId: _contractType,
            onPick: (String id) => setState(() => _contractType = id),
          ),
          _dropdown(
            label: 'Contractor Name',
            options: _master.contractors,
            selectedId: _contractorId,
            onPick: (String id) => setState(() => _contractorId = id),
          ),
          _text(
            _ifasCode,
            label: 'Contract (IFAS Code)',
            hint: 'Enter IFAS code',
            maxLength: 50,
          ),
          _dropdown(
            label: 'Status of Work *',
            options: _workStatuses.isNotEmpty
                ? _workStatuses
                : _master.workStatuses,
            selectedId: _workStatus,
            onPick: (String id) => setState(() => _workStatus = id),
          ),
          _text(
            _estimatedCost,
            label: 'Detailed Estimated Cost',
            hint: 'Enter amount',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _dropdown(
            label: 'Unit',
            options: _master.units.isNotEmpty
                ? _master.units
                : contractCostUnitOptions,
            selectedId: _costUnit,
            onPick: (String id) => setState(() => _costUnit = id),
          ),
          _dateField(
            label: 'Planned date of award',
            value: _plannedAward,
            onChanged: (DateTime? v) => setState(() => _plannedAward = v),
          ),
          _dateField(
            label: 'Planned date of completion',
            value: _plannedCompletion,
            onChanged: (DateTime? v) => setState(() => _plannedCompletion = v),
          ),
          _dateField(
            label: 'Notice Inviting Tender',
            value: _nitDate,
            onChanged: (DateTime? v) => setState(() => _nitDate = v),
          ),
          _dateField(
            label: 'Tender Opening Date',
            value: _tenderOpening,
            onChanged: (DateTime? v) => setState(() => _tenderOpening = v),
          ),
          _dateField(
            label: 'Technical Eval. Submission',
            value: _techEval,
            onChanged: (DateTime? v) => setState(() => _techEval = v),
          ),
          _dateField(
            label: 'Financial Eval. Submission',
            value: _finEval,
            onChanged: (DateTime? v) => setState(() => _finEval = v),
          ),
        ]),
        _text(
          _scope,
          label: 'Scope of Contract',
          hint: 'Enter scope',
          maxLines: 4,
          maxLength: _textMaxChars,
        ),
        const SizedBox(height: 8),
        _sectionTitle('Tender Bid Revisions'),
        for (int i = 0; i < _revisions.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: <Widget>[
                  _text(
                    _revisions[i].revisionNo,
                    label: 'Revision No',
                    hint: 'R${i + 1}',
                  ),
                  _text(
                    _revisions[i].estimatedCost,
                    label: 'Detailed Estimated Cost',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  _dateField(
                    label: 'Planned date of award',
                    value: _revisions[i].plannedAward,
                    onChanged: (DateTime? v) {
                      setState(() => _revisions[i].plannedAward = v);
                    },
                  ),
                  _dateField(
                    label: 'Planned date of completion',
                    value: _revisions[i].plannedCompletion,
                    onChanged: (DateTime? v) {
                      setState(() => _revisions[i].plannedCompletion = v);
                    },
                  ),
                  _text(
                    _revisions[i].remarks,
                    label: 'Remarks',
                    maxLines: 2,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _revisions[i].dispose();
                          _revisions.removeAt(i);
                          if (_revisions.isEmpty) {
                            _revisions.add(_RevisionDraft(revisionNo: 'R1'));
                          }
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFC1121F),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Center(
          child: IconButton(
            onPressed: () {
              setState(() {
                _revisions.add(
                  _RevisionDraft(revisionNo: 'R${_revisions.length + 1}'),
                );
              });
            },
            style: IconButton.styleFrom(
              backgroundColor: AppPalette.of(context).success,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.playlist_add_rounded),
          ),
        ),
        _text(
          _remarks,
          label: 'Remarks',
          hint: 'Enter remarks',
          maxLines: 3,
          maxLength: _textMaxChars,
        ),
      ],
    );
  }

  Widget _closureStep() {
    return _fieldGrid(<Widget>[
      _text(_loaLetterNo, label: 'LOA Letter No', hint: 'Enter LOA letter no'),
      _dateField(
        label: 'LOA Date',
        value: _loaDate,
        onChanged: (DateTime? v) => setState(() => _loaDate = v),
      ),
      _text(
        _closureRemarks,
        label: 'Closure Remarks',
        hint: 'Enter remarks',
        maxLines: 4,
        maxLength: _textMaxChars,
      ),
    ]);
  }

  Widget _bgStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _radioYesNo(
          label: 'Bank Guarantee Required?',
          value: _bgRequired,
          onChanged: (String value) => setState(() => _bgRequired = value),
        ),
        if (_bgRequired == 'Yes') ...<Widget>[
          for (int i = 0; i < _bankGuarantees.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: <Widget>[
                    _dropdown(
                      label: 'BG Type *',
                      options: _master.bgTypes,
                      selectedId: _bankGuarantees[i].bgType,
                      onPick: (String id) {
                        setState(() => _bankGuarantees[i].bgType = id);
                      },
                    ),
                    _text(
                      _bankGuarantees[i].issuingBank,
                      label: 'Issuing Bank',
                    ),
                    _text(
                      _bankGuarantees[i].bgNumber,
                      label: 'BG / FDR Number',
                    ),
                    _text(
                      _bankGuarantees[i].amount,
                      label: 'Amount',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _dropdown(
                      label: 'Unit',
                      options: _master.units.isNotEmpty
                          ? _master.units
                          : contractCostUnitOptions,
                      selectedId: _bankGuarantees[i].unit,
                      onPick: (String id) {
                        setState(() => _bankGuarantees[i].unit = id);
                      },
                    ),
                    _dateField(
                      label: 'BG / FDR Date',
                      value: _bankGuarantees[i].bgDate,
                      onChanged: (DateTime? v) {
                        setState(() => _bankGuarantees[i].bgDate = v);
                      },
                    ),
                    _dateField(
                      label: 'Expiry Date *',
                      value: _bankGuarantees[i].expiryDate,
                      onChanged: (DateTime? v) {
                        setState(() => _bankGuarantees[i].expiryDate = v);
                      },
                    ),
                    _dateField(
                      label: 'Release Date',
                      value: _bankGuarantees[i].releaseDate,
                      onChanged: (DateTime? v) {
                        setState(() => _bankGuarantees[i].releaseDate = v);
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _bankGuarantees[i].dispose();
                            _bankGuarantees.removeAt(i);
                            if (_bankGuarantees.isEmpty) {
                              _bankGuarantees.add(_BgDraft());
                            }
                          });
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFC1121F),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Center(
            child: IconButton(
              onPressed: () =>
                  setState(() => _bankGuarantees.add(_BgDraft())),
              style: IconButton.styleFrom(
                backgroundColor: AppPalette.of(context).success,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.playlist_add_rounded),
            ),
          ),
        ],
      ],
    );
  }

  Widget _insuranceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _radioYesNo(
          label: 'Insurance Required?',
          value: _insuranceRequired,
          onChanged: (String value) {
            setState(() => _insuranceRequired = value);
          },
        ),
        if (_insuranceRequired == 'Yes') ...<Widget>[
          for (int i = 0; i < _insurances.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: <Widget>[
                    _dropdown(
                      label: 'Insurance Type *',
                      options: _master.insuranceTypes,
                      selectedId: _insurances[i].insuranceType,
                      onPick: (String id) {
                        setState(() => _insurances[i].insuranceType = id);
                      },
                    ),
                    _text(
                      _insurances[i].issuingAgency,
                      label: 'Issuing Agency',
                    ),
                    _text(
                      _insurances[i].agencyAddress,
                      label: 'Agency Address',
                    ),
                    _text(
                      _insurances[i].insuranceNumber,
                      label: 'Insurance Number',
                    ),
                    _text(
                      _insurances[i].insuranceValue,
                      label: 'Insurance Value',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _dateField(
                      label: 'Valid Upto *',
                      value: _insurances[i].validUpto,
                      onChanged: (DateTime? v) {
                        setState(() => _insurances[i].validUpto = v);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Release'),
                      value: _insurances[i].released,
                      onChanged: (bool value) {
                        setState(() => _insurances[i].released = value);
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _insurances[i].dispose();
                            _insurances.removeAt(i);
                            if (_insurances.isEmpty) {
                              _insurances.add(_InsuranceDraft());
                            }
                          });
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFC1121F),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Center(
            child: IconButton(
              onPressed: () =>
                  setState(() => _insurances.add(_InsuranceDraft())),
              style: IconButton.styleFrom(
                backgroundColor: AppPalette.of(context).success,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.playlist_add_rounded),
            ),
          ),
        ],
      ],
    );
  }

  Widget _milestoneStep() {
    return Column(
      children: <Widget>[
        _radioYesNo(
          label: 'Milestone Required?',
          value: _milestoneRequired,
          onChanged: (String value) {
            setState(() => _milestoneRequired = value);
          },
        ),
        _radioYesNo(
          label: 'Revision Required?',
          value: _milestoneRevisionRequired,
          onChanged: (String value) {
            setState(() => _milestoneRevisionRequired = value);
          },
        ),
        if (_milestoneRequired == 'Yes')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Milestone line items can be refined once the save payload fields are confirmed from the live form.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _keyPersonnelStep() {
    return Column(
      children: <Widget>[
        _radioYesNo(
          label: "Contractor's Key Required?",
          value: _keyPersonnelRequired,
          onChanged: (String value) {
            setState(() => _keyPersonnelRequired = value);
          },
        ),
        if (_keyPersonnelRequired == 'Yes')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Key personnel rows can be refined once the save payload fields are confirmed from the live form.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _documentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _sectionTitle('Documents'),
        for (int i = 0; i < _documents.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: <Widget>[
                  _dropdown(
                    label: 'File Type',
                    options: _master.fileTypes,
                    selectedId: _documents[i].fileType,
                    onPick: (String id) {
                      setState(() => _documents[i].fileType = id);
                    },
                  ),
                  _text(_documents[i].name, label: 'Name'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        final FilePickerResult? picked =
                            await FilePicker.platform.pickFiles(
                          withData: false,
                        );
                        final String? path = picked?.files.single.path;
                        if (path == null || path.isEmpty) {
                          return;
                        }
                        setState(() {
                          _documents[i].filePath = path;
                          _documents[i].fileName =
                              picked?.files.single.name ?? p.basename(path);
                        });
                      },
                      icon: const Icon(Icons.attach_file_rounded),
                      label: Text(
                        _documents[i].fileName.isEmpty
                            ? 'Upload File'
                            : _documents[i].fileName,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _documents[i].dispose();
                          _documents.removeAt(i);
                          if (_documents.isEmpty) {
                            _documents.add(_DocumentDraft());
                          }
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFC1121F),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Center(
          child: IconButton(
            onPressed: () => setState(() => _documents.add(_DocumentDraft())),
            style: IconButton.styleFrom(
              backgroundColor: AppPalette.of(context).success,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.playlist_add_rounded),
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
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
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
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required List<ContractFormOption> options,
    required String selectedId,
    required ValueChanged<String> onPick,
  }) {
    final String? value = selectedId.isEmpty
        ? null
        : options.any((ContractFormOption option) => option.id == selectedId)
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
          for (final ContractFormOption option in options)
            DropdownMenuItem<String>(
              value: option.id,
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

  Widget _radioYesNo({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: RadioGroup<String>(
          groupValue: value.isEmpty ? null : value,
          onChanged: (String? next) {
            if (next != null) {
              onChanged(next);
            }
          },
          child: const Row(
            children: <Widget>[
              Radio<String>(value: 'Yes'),
              Text('Yes'),
              SizedBox(width: 12),
              Radio<String>(value: 'No'),
              Text('No'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    final String text = value == null
        ? 'dd/mm/yyyy'
        : formatContractDisplayDate(value);
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

  Widget _multiSelect({
    required String label,
    required List<ContractFormOption> options,
    required List<String> selectedIds,
    required ValueChanged<List<String>> onChanged,
    required bool enabled,
    required String emptyHint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            if (!enabled)
              Text(
                emptyHint,
                style: TextStyle(color: AppPalette.of(context).mutedText),
              )
            else ...<Widget>[
              for (final String id in selectedIds)
                InputChip(
                  label: Text(_optionLabel(options, id)),
                  onDeleted: () {
                    final List<String> next = List<String>.from(selectedIds)
                      ..remove(id);
                    onChanged(next);
                  },
                ),
              ActionChip(
                label: const Text('Add'),
                onPressed: options.isEmpty
                    ? null
                    : () async {
                        final String? picked = await showModalBottomSheet<String>(
                          context: context,
                          builder: (BuildContext context) {
                            return SafeArea(
                              child: ListView(
                                children: <Widget>[
                                  for (final ContractFormOption option
                                      in options)
                                    ListTile(
                                      title: Text(option.label),
                                      enabled: !selectedIds.contains(option.id),
                                      onTap: () =>
                                          Navigator.pop(context, option.id),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                        if (picked == null || picked.isEmpty) {
                          return;
                        }
                        if (selectedIds.contains(picked)) {
                          return;
                        }
                        onChanged(<String>[...selectedIds, picked]);
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _optionLabel(List<ContractFormOption> options, String id) {
    for (final ContractFormOption option in options) {
      if (option.id == id) {
        return option.label;
      }
    }
    return id;
  }
}

class _ExecutiveDraft {
  String departmentId = '';
  final List<String> executiveIds = <String>[];

  void dispose() {}
}

class _RevisionDraft {
  _RevisionDraft({String revisionNo = ''})
    : revisionNo = TextEditingController(text: revisionNo),
      estimatedCost = TextEditingController(),
      remarks = TextEditingController();

  final TextEditingController revisionNo;
  final TextEditingController estimatedCost;
  final TextEditingController remarks;
  DateTime? plannedAward;
  DateTime? plannedCompletion;

  void dispose() {
    revisionNo.dispose();
    estimatedCost.dispose();
    remarks.dispose();
  }
}

class _BgDraft {
  _BgDraft()
    : issuingBank = TextEditingController(),
      bgNumber = TextEditingController(),
      amount = TextEditingController();

  String bgType = '';
  final TextEditingController issuingBank;
  final TextEditingController bgNumber;
  final TextEditingController amount;
  String unit = 'Rupees';
  DateTime? bgDate;
  DateTime? expiryDate;
  DateTime? releaseDate;

  void dispose() {
    issuingBank.dispose();
    bgNumber.dispose();
    amount.dispose();
  }
}

class _InsuranceDraft {
  _InsuranceDraft()
    : issuingAgency = TextEditingController(),
      agencyAddress = TextEditingController(),
      insuranceNumber = TextEditingController(),
      insuranceValue = TextEditingController();

  String insuranceType = '';
  final TextEditingController issuingAgency;
  final TextEditingController agencyAddress;
  final TextEditingController insuranceNumber;
  final TextEditingController insuranceValue;
  DateTime? validUpto;
  bool released = false;

  void dispose() {
    issuingAgency.dispose();
    agencyAddress.dispose();
    insuranceNumber.dispose();
    insuranceValue.dispose();
  }
}

class _DocumentDraft {
  _DocumentDraft() : name = TextEditingController();

  String fileType = '';
  final TextEditingController name;
  String? filePath;
  String fileName = '';

  void dispose() {
    name.dispose();
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
              'Could not load the contract form.',
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
