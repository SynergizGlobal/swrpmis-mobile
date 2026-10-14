import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/issues/data/datasources/issue_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/issues/domain/issue_form.dart';

class AddIssueFormPage extends ConsumerStatefulWidget {
  const AddIssueFormPage({super.key});

  static const String routeName = 'add-issue-form';
  static const String routePath = '/module/issues/add';

  @override
  ConsumerState<AddIssueFormPage> createState() => _AddIssueFormPageState();
}

class _AddIssueFormPageState extends ConsumerState<AddIssueFormPage> {
  static const int _detailMaxChars = 1000;

  final TextEditingController _description = TextEditingController();
  final TextEditingController _actionTaken = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _otherName = TextEditingController();
  final TextEditingController _otherDesignation = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _cascadeBusy = false;
  int _step = 0;

  List<IssueFormOption> _projects = const <IssueFormOption>[];
  List<IssueFormOption> _contracts = const <IssueFormOption>[];
  List<IssueFormOption> _categories = const <IssueFormOption>[];
  List<IssueFormOption> _titles = const <IssueFormOption>[];
  List<IssueFormOption> _structures = const <IssueFormOption>[];
  List<IssueFormOption> _components = const <IssueFormOption>[];
  List<IssueFormOption> _priorities = const <IssueFormOption>[];
  List<IssueFormOption> _railways = const <IssueFormOption>[];
  List<IssueFormOption> _otherOrgs = const <IssueFormOption>[];

  IssueFormOption? _project;
  IssueFormOption? _contract;
  IssueFormOption? _category;
  IssueFormOption? _title;
  IssueFormOption? _structure;
  IssueFormOption? _component;
  IssueFormOption? _priority;
  IssueFormOption? _responsible;
  IssueFormOption? _otherOrg;
  DateTime? _deadline;

  IssueRemoteDataSource get _source => ref.read(issueRemoteDataSourceProvider);

  bool get _locked => _loading || _saving || _cascadeBusy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _description.dispose();
    _actionTaken.dispose();
    _location.dispose();
    _otherName.dispose();
    _otherDesignation.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final dynamic data = await _source.fetchAddIssueForm();
      if (!mounted) {
        return;
      }
      setState(() {
        _projects = issueFormProjects(data);
        _priorities = issueFormPriorities(data);
        _railways = issueFormRailways(data);
        _otherOrgs = issueFormOtherOrganizations(data);
        _structures = issueFormStructures(data);
        _components = issueFormComponents(data);
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Load Failed',
        message: userFriendlyErrorMessage(error),
      );
    } on Object {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Load Failed',
        message: 'Could not load add-issue form data. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _onProject(IssueFormOption? project) async {
    setState(() {
      _project = project;
      _contract = null;
      _category = null;
      _title = null;
      _structure = null;
      _component = null;
      _contracts = const <IssueFormOption>[];
      _categories = const <IssueFormOption>[];
      _titles = const <IssueFormOption>[];
      _structures = const <IssueFormOption>[];
      _components = const <IssueFormOption>[];
    });
    if (project == null) {
      return;
    }
    await _cascade(() async {
      final dynamic data = await _source.fetchIssueFormContracts(project.id);
      if (!mounted) {
        return;
      }
      setState(() => _contracts = issueFormContracts(data));
    });
  }

  Future<void> _onContract(IssueFormOption? contract) async {
    setState(() {
      _contract = contract;
      _category = null;
      _title = null;
      _structure = null;
      _component = null;
      _categories = const <IssueFormOption>[];
      _titles = const <IssueFormOption>[];
      _structures = const <IssueFormOption>[];
      _components = const <IssueFormOption>[];
    });
    if (contract == null) {
      return;
    }
    await _cascade(() async {
      final dynamic categories = await _source.fetchIssueFormCategories(
        issueContractTypeFk(contract),
      );
      final dynamic structures = await _source.fetchIssueFormStructures(
        contract.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = issueFormCategories(categories);
        _structures = issueFormStructures(structures);
      });
    });
  }

  Future<void> _onCategory(IssueFormOption? category) async {
    setState(() {
      _category = category;
      _title = null;
      _titles = const <IssueFormOption>[];
    });
    if (category == null) {
      return;
    }
    await _cascade(() async {
      final dynamic data = await _source.fetchIssueFormTitles(
        issueCategoryFk(category),
      );
      if (!mounted) {
        return;
      }
      setState(() => _titles = issueFormTitles(data));
    });
  }

  Future<void> _onStructure(IssueFormOption? structure) async {
    final IssueFormOption? contract = _contract;
    setState(() {
      _structure = structure;
      _component = null;
      _components = const <IssueFormOption>[];
    });
    if (structure == null || contract == null) {
      return;
    }
    await _cascade(() async {
      final dynamic data = await _source.fetchIssueFormComponents(
        contractIdFk: contract.id,
        structure: structure.id,
      );
      if (!mounted) {
        return;
      }
      setState(() => _components = issueFormComponents(data));
    });
  }

  Future<void> _cascade(Future<void> Function() action) async {
    setState(() => _cascadeBusy = true);
    try {
      await action();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Load Failed',
        message: userFriendlyErrorMessage(error),
      );
    } on Object {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Load Failed',
        message: 'Could not load the next issue options.',
      );
    } finally {
      if (mounted) {
        setState(() => _cascadeBusy = false);
      }
    }
  }

  String _reportedBy() {
    final AuthSession? session = ref.read(authControllerProvider).valueOrNull;
    final String name = session?.userName.trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }
    return session?.userId.trim() ?? '';
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (_project == null) {
        _required('Please select a project.');
        return false;
      }
      if (_contract == null) {
        _required('Please select a contract.');
        return false;
      }
      if (_category == null) {
        _required('Please select a category.');
        return false;
      }
      if (_title == null) {
        _required('Please select an issue title / short description.');
        return false;
      }
      if (_priority == null) {
        _required('Please select issue priority.');
        return false;
      }
      return true;
    }
    if (_reportedBy().isEmpty) {
      _required('Reported by is required for this issue.');
      return false;
    }
    if (_description.text.trim().isEmpty) {
      _required('Please enter description of issue.');
      return false;
    }
    if (_responsible == null) {
      _required('Please select responsible organization (pending with).');
      return false;
    }
    if (_otherOrg != null) {
      if (_otherName.text.trim().isEmpty) {
        _required('Please enter responsible person name.');
        return false;
      }
      if (_otherDesignation.text.trim().isEmpty) {
        _required('Please enter responsible person designation.');
        return false;
      }
    }
    return true;
  }

  Future<void> _required(String message) {
    return AppDialog.show(
      context,
      variant: AppDialogVariant.info,
      title: 'Required',
      message: message,
    );
  }

  Future<void> _next() async {
    if (!_validateStep(0)) {
      return;
    }
    setState(() => _step = 1);
  }

  Map<String, String> _fields() {
    final String deadline = _deadline == null
        ? ''
        : DateFormat('yyyy-MM-dd').format(_deadline!);
    return <String, String>{
      'project_id_fk': _project?.id ?? '',
      'contract_id_fk': _contract?.id ?? '',
      'structure': _structure?.id ?? '',
      'component': _component?.id ?? '',
      'category_fk': _category == null ? '' : issueCategoryFk(_category!),
      'title': _title?.label ?? '',
      'priority_fk': _priority?.label ?? '',
      'description': _description.text.trim(),
      'corrective_measure': _actionTaken.text.trim(),
      'date': deadline,
      'location': _location.text.trim(),
      'other_organization': _otherOrg?.label ?? '',
      'zonal_railway_fk': _responsible == null
          ? ''
          : issueZonalRailwayFk(_responsible!),
      'other_org_resposible_person_name': _otherName.text.trim(),
      'other_org_resposible_person_designation': _otherDesignation.text.trim(),
      'reported_by': _reportedBy(),
      'assigned_date': '',
      'resolved_date': '',
      'escalation_date': '',
      'issue_file_types': '',
      'issueFileNames': '',
      'issue_file_ids': '',
    };
  }

  Future<void> _submit() async {
    if (!_validateStep(0) || !_validateStep(1)) {
      return;
    }
    setState(() => _saving = true);
    try {
      await _source.submitAddIssue(_fields());
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Saved',
        message: 'Issue submitted successfully.',
      );
      if (!mounted) {
        return;
      }
      context.pop(true);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Save Failed',
        message: userFriendlyErrorMessage(error),
      );
    } on Object {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Save Failed',
        message: 'Unable to submit issue. Check required fields and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Issue')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                _step == 0 ? 'Step 1 — Basics' : 'Step 2 — Issue details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: <Widget>[
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          children: <Widget>[
                            if (_step == 0) ..._basics(),
                            if (_step == 1) ..._details(),
                          ],
                        ),
                  if (_cascadeBusy || _saving)
                    const Positioned.fill(
                      child: AbsorbPointer(
                        child: ColoredBox(
                          color: Color(0x14000000),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!_loading)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(
                    top: BorderSide(color: colors.outlineVariant),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _locked
                              ? null
                              : () => setState(() => _step = 0),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _locked
                            ? null
                            : (_step == 0 ? _next : _submit),
                        icon: Icon(
                          _step == 0
                              ? Icons.arrow_forward_rounded
                              : Icons.send_rounded,
                        ),
                        label: Text(_step == 0 ? 'Continue' : 'Submit issue'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _basics() {
    return <Widget>[
      _select(
        label: 'Project *',
        title: 'Select project',
        placeholder: 'Select project',
        items: _projects,
        value: _project,
        onChanged: _onProject,
      ),
      _select(
        label: 'Contract *',
        title: 'Select contract',
        placeholder: 'Select contract',
        items: _contracts,
        value: _contract,
        enabled: _project != null && !_cascadeBusy,
        onChanged: _onContract,
      ),
      _select(
        label: 'Structure',
        title: 'Select structure',
        placeholder: 'Optional',
        items: _structures,
        value: _structure,
        enabled: _contract != null && !_cascadeBusy,
        onChanged: _onStructure,
      ),
      _select(
        label: 'Component',
        title: 'Select component',
        placeholder: 'Optional',
        items: _components,
        value: _component,
        enabled: _structure != null && !_cascadeBusy,
        onChanged: (IssueFormOption? value) =>
            setState(() => _component = value),
      ),
      _select(
        label: 'Issue Category *',
        title: 'Select category',
        placeholder: 'Select category',
        items: _categories,
        value: _category,
        enabled: _contract != null && !_cascadeBusy,
        onChanged: _onCategory,
      ),
      _select(
        label: 'Short Description *',
        title: 'Select Description',
        placeholder: 'Select Description',
        items: _titles,
        value: _title,
        enabled: _category != null && !_cascadeBusy,
        onChanged: (IssueFormOption? value) => setState(() => _title = value),
      ),
      _select(
        label: 'Issue Priority *',
        title: 'Select priority',
        placeholder: 'Select priority',
        items: _priorities,
        value: _priority,
        enabled: !_cascadeBusy,
        onChanged: (IssueFormOption? value) =>
            setState(() => _priority = value),
      ),
    ];
  }

  List<Widget> _details() {
    return <Widget>[
      TextField(
        controller: _description,
        maxLines: 5,
        maxLength: _detailMaxChars,
        decoration: const InputDecoration(
          labelText: 'Description of issue *',
          hintText: 'Describe the issue',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _actionTaken,
        maxLines: 5,
        maxLength: _detailMaxChars,
        decoration: const InputDecoration(
          labelText: 'Action taken',
          hintText: 'What has been done so far',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 12),
      _dateField(),
      const SizedBox(height: 12),
      TextField(
        controller: _location,
        decoration: const InputDecoration(
          labelText: 'Location / station / KM',
        ),
      ),
      const SizedBox(height: 12),
      _select(
        label: 'Responsible Organization (Pending with) *',
        title: 'Select organization',
        placeholder: 'Select value',
        items: _railways,
        value: _responsible,
        enabled: !_cascadeBusy,
        onChanged: (IssueFormOption? value) =>
            setState(() => _responsible = value),
      ),
      _select(
        label: 'Other Responsible Organization (Pending with)',
        title: 'Select organization',
        placeholder: 'Select value',
        items: _otherOrgs,
        value: _otherOrg,
        enabled: !_cascadeBusy,
        onChanged: (IssueFormOption? value) {
          setState(() {
            _otherOrg = value;
            _otherName.clear();
            _otherDesignation.clear();
          });
        },
      ),
      if (_otherOrg != null) ...<Widget>[
        TextField(
          controller: _otherName,
          decoration: const InputDecoration(
            labelText: 'Responsible Person Name *',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _otherDesignation,
          decoration: const InputDecoration(
            labelText: 'Responsible Person Designation *',
          ),
        ),
        const SizedBox(height: 12),
      ],
      InputDecorator(
        decoration: const InputDecoration(labelText: 'Reported by'),
        child: Text(_reportedBy().isEmpty ? '—' : _reportedBy()),
      ),
    ];
  }

  Widget _dateField() {
    final String text = _deadline == null
        ? 'dd/mm/yyyy'
        : DateFormat('dd/MM/yyyy').format(_deadline!);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _locked
          ? null
          : () async {
              final DateTime now = DateTime.now();
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _deadline ?? now,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) {
                setState(() => _deadline = picked);
              }
            },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Deadline for issue resolution',
        ),
        child: Text(text),
      ),
    );
  }

  Widget _select({
    required String label,
    required String title,
    required String placeholder,
    required List<IssueFormOption> items,
    required IssueFormOption? value,
    required ValueChanged<IssueFormOption?> onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _IssueSelectField(
        label: label,
        title: title,
        placeholder: placeholder,
        items: items,
        value: value,
        enabled: enabled && !_locked,
        onChanged: onChanged,
      ),
    );
  }
}

class _IssueSelectField extends StatelessWidget {
  const _IssueSelectField({
    required this.label,
    required this.title,
    required this.placeholder,
    required this.items,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String title;
  final String placeholder;
  final List<IssueFormOption> items;
  final IssueFormOption? value;
  final bool enabled;
  final ValueChanged<IssueFormOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? () => _pick(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
        ),
        child: Text(
          value?.label ?? placeholder,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final IssueFormOption? picked = await showModalBottomSheet<IssueFormOption>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.6;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No options'),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          title,
                          style: Theme.of(sheetContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      for (final IssueFormOption option in items)
                        ListTile(
                          title: Text(option.label),
                          trailing: option.id == value?.id
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: () => Navigator.pop(sheetContext, option),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
    if (picked != null) {
      onChanged(picked);
    }
  }
}
