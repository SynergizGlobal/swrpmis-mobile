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
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/data/datasources/utility_shifting_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_form.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/presentation/providers/utility_shifting_form_provider.dart';

class AddUtilityShiftingFormPage extends ConsumerStatefulWidget {
  const AddUtilityShiftingFormPage({
    super.key,
    this.utilityShiftingId = '',
  });

  final String utilityShiftingId;

  static const String routeName = 'add-utility-shifting-form';
  static const String routePath = '/module/utility/add';
  static const String editRouteName = 'edit-utility-shifting-form';
  static const String editRoutePath = '/module/utility/edit/:utilityShiftingId';

  static String location({String utilityShiftingId = ''}) {
    final String id = utilityShiftingId.trim();
    if (id.isEmpty) {
      return routePath;
    }
    return '/module/utility/edit/${Uri.encodeComponent(id)}';
  }

  @override
  ConsumerState<AddUtilityShiftingFormPage> createState() =>
      _AddUtilityShiftingFormPageState();
}

class _AddUtilityShiftingFormPageState
    extends ConsumerState<AddUtilityShiftingFormPage> {
  static final DateFormat _displayDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');
  static const List<String> _allowedExtensions = <String>[
    'pdf',
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'doc',
    'docx',
    'xls',
    'xlsx',
  ];

  final TextEditingController _utilityDescription = TextEditingController();
  final TextEditingController _locationName = TextEditingController();
  final TextEditingController _custodian = TextEditingController();
  final TextEditingController _referenceNumber = TextEditingController();
  final TextEditingController _executedBy = TextEditingController();
  final TextEditingController _chainage = TextEditingController();
  final TextEditingController _latitude = TextEditingController();
  final TextEditingController _longitude = TextEditingController();
  final TextEditingController _affectedStructures = TextEditingController();
  final TextEditingController _scope = TextEditingController();
  final TextEditingController _completed = TextEditingController();
  final TextEditingController _remarks = TextEditingController();

  UtilityShiftingFormMaster _master = UtilityShiftingFormMaster.empty;
  bool _seeded = false;
  bool _reportedLoadError = false;
  bool _saving = false;
  bool _loadingStages = false;
  bool _loadingElements = false;
  bool _loadingCascades = false;

  String _recordId = '';
  String _utilityShiftingId = '';
  String _projectId = '';
  String _executionAgencyId = '';
  String _hodId = '';
  String _utilityTypeId = '';
  String _utilityCategoryId = '';
  String _impactedContractId = '';
  String _requirementStageId = '';
  String _impactedElementId = '';
  String _unitId = '';
  String _statusId = '';

  DateTime? _identificationDate;
  DateTime? _targetDate;
  DateTime? _startDate;
  DateTime? _completionDate;

  List<UtilityShiftingFormOption> _requirementStageOptions =
      const <UtilityShiftingFormOption>[];
  List<UtilityShiftingFormOption> _impactedElementOptions =
      const <UtilityShiftingFormOption>[];

  final List<UtilityShiftingProgressDraft> _progress =
      <UtilityShiftingProgressDraft>[];
  final List<UtilityShiftingAttachmentDraft> _attachments =
      <UtilityShiftingAttachmentDraft>[];

  String get _routeUtilityShiftingId => widget.utilityShiftingId.trim();

  bool get _editing => _routeUtilityShiftingId.isNotEmpty;

  @override
  void dispose() {
    _utilityDescription.dispose();
    _locationName.dispose();
    _custodian.dispose();
    _referenceNumber.dispose();
    _executedBy.dispose();
    _chainage.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _affectedStructures.dispose();
    _scope.dispose();
    _completed.dispose();
    _remarks.dispose();
    super.dispose();
  }

  String _match(List<UtilityShiftingFormOption> options, String raw) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    for (final UtilityShiftingFormOption option in options) {
      if (option.id == value || option.label == value) {
        return option.id;
      }
      if (option.label.endsWith(' - $value') ||
          option.label.startsWith('$value - ')) {
        return option.id;
      }
    }
    return value;
  }

  Future<void> _seed(
    UtilityShiftingFormMaster master, {
    UtilityShiftingDetail? detail,
  }) async {
    if (_seeded) {
      return;
    }
    final UtilityShiftingDetail record = detail ?? UtilityShiftingDetail.empty;
    final bool editing = _editing && !record.isEmpty;

    _utilityDescription.text = record.utilityDescription;
    _locationName.text = record.locationName;
    _custodian.text = record.custodian;
    _referenceNumber.text = record.referenceNumber;
    _executedBy.text = record.executedBy;
    _chainage.text = record.chainage;
    _latitude.text = record.latitude;
    _longitude.text = record.longitude;
    _affectedStructures.text = record.affectedStructures;
    _scope.text = record.scope;
    _completed.text = record.completed;
    _remarks.text = record.remarks;

    final String projectId = _match(master.projects, record.projectIdFk);
    final String impactedContractId = _match(
      utilityShiftingImpactedContractsForProject(
        master.impactedContracts,
        projectId,
      ),
      record.impactedContractIdFk,
    );
    final String requirementStageId = record.requirementStageFk.trim();
    final String impactedElementId = record.impactedElement.trim();

    setState(() {
      _seeded = true;
      _master = master;
      _recordId = record.id.trim().isNotEmpty
          ? record.id.trim()
          : record.utilityShiftingId.trim();
      _utilityShiftingId = record.utilityShiftingId.trim().isNotEmpty
          ? record.utilityShiftingId.trim()
          : _routeUtilityShiftingId;
      _projectId = projectId;
      _executionAgencyId = _match(
        master.executionAgencies,
        record.executionAgencyFk,
      );
      _hodId = _match(master.hods, record.hodUserIdFk);
      _utilityTypeId = _match(master.utilityTypes, record.utilityTypeFk);
      _utilityCategoryId = _match(
        master.utilityCategories,
        record.utilityCategoryFk,
      );
      _impactedContractId = impactedContractId;
      _requirementStageId = requirementStageId;
      _impactedElementId = impactedElementId;
      _unitId = _match(master.units, record.unitFk);
      _statusId = _match(master.statuses, record.shiftingStatusFk);
      _identificationDate = parseUtilityShiftingFormDate(
        record.identification,
      );
      _targetDate = parseUtilityShiftingFormDate(
        record.plannedCompletionDate,
      );
      _startDate = parseUtilityShiftingFormDate(record.startDate);
      _completionDate = parseUtilityShiftingFormDate(
        record.shiftingCompletionDate,
      );
      _progress
        ..clear()
        ..addAll(record.progress);
      _requirementStageOptions = master.fallbackRequirementStages.isNotEmpty
          ? master.fallbackRequirementStages
          : master.requirementStages;
      _impactedElementOptions = master.fallbackImpactedElements;
      _loadingCascades = editing && impactedContractId.isNotEmpty;
    });

    if (!editing || impactedContractId.isEmpty) {
      return;
    }
    await _loadCascadesForEdit(
      impactedContractId: impactedContractId,
      requirementStageId: requirementStageId,
      impactedElementId: impactedElementId,
    );
  }

  Future<void> _loadCascadesForEdit({
    required String impactedContractId,
    required String requirementStageId,
    required String impactedElementId,
  }) async {
    final UtilityShiftingRemoteDataSource remote = ref.read(
      utilityShiftingRemoteDataSourceProvider,
    );
    try {
      final List<UtilityShiftingFormOption> stages = await remote
          .fetchRequirementStagesForForm(
            impactedContractId: impactedContractId,
          );
      if (!mounted || _impactedContractId != impactedContractId) {
        return;
      }
      final List<UtilityShiftingFormOption> stageOptions = stages.isNotEmpty
          ? stages
          : (_master.fallbackRequirementStages.isNotEmpty
                ? _master.fallbackRequirementStages
                : _master.requirementStages);
      final String matchedStage = _match(stageOptions, requirementStageId);

      List<UtilityShiftingFormOption> elementOptions =
          _master.fallbackImpactedElements;
      String matchedElement = impactedElementId;
      if (matchedStage.isNotEmpty) {
        setState(() => _loadingElements = true);
        try {
          final List<UtilityShiftingFormOption> elements = await remote
              .fetchImpactedElementsForForm(
                impactedContractId: impactedContractId,
                requirementStage: matchedStage,
              );
          if (!mounted || _impactedContractId != impactedContractId) {
            return;
          }
          elementOptions = elements.isNotEmpty
              ? elements
              : _master.fallbackImpactedElements;
          matchedElement = _match(elementOptions, impactedElementId);
        } on Object {
          if (!mounted) {
            return;
          }
          elementOptions = _master.fallbackImpactedElements;
          matchedElement = _match(elementOptions, impactedElementId);
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _requirementStageOptions = stageOptions;
        _requirementStageId = matchedStage;
        _impactedElementOptions = elementOptions;
        _impactedElementId = matchedElement;
        _loadingStages = false;
        _loadingElements = false;
        _loadingCascades = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _requirementStageOptions = _master.fallbackRequirementStages.isNotEmpty
            ? _master.fallbackRequirementStages
            : _master.requirementStages;
        _requirementStageId = _match(
          _requirementStageOptions,
          requirementStageId,
        );
        _impactedElementOptions = _master.fallbackImpactedElements;
        _impactedElementId = _match(
          _impactedElementOptions,
          impactedElementId,
        );
        _loadingStages = false;
        _loadingElements = false;
        _loadingCascades = false;
      });
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Load Failed',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : 'Could not load cascading options for this record.',
      );
    }
  }

  void _reportLoadError(Object error) {
    if (!mounted || _reportedLoadError) {
      return;
    }
    _reportedLoadError = true;
    final String message = error is DioException
        ? userFriendlyErrorMessage(error)
        : 'Could not load the utility shifting form. Please try again.';
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
      _loadingCascades = false;
    });
    ref.invalidate(utilityShiftingFormMasterProvider);
    if (_editing) {
      ref.invalidate(utilityShiftingDetailProvider(_routeUtilityShiftingId));
    }
  }

  List<UtilityShiftingFormOption> get _impactedContractOptions {
    return utilityShiftingImpactedContractsForProject(
      _master.impactedContracts,
      _projectId,
    );
  }

  Future<void> _selectProject(String id) async {
    if (id == _projectId) {
      return;
    }
    setState(() {
      _projectId = id;
      if (_impactedContractId.isNotEmpty &&
          !_impactedContractOptions.any(
            (UtilityShiftingFormOption option) =>
                option.id == _impactedContractId,
          )) {
        _impactedContractId = '';
        _requirementStageId = '';
        _impactedElementId = '';
        _requirementStageOptions = _master.fallbackRequirementStages.isNotEmpty
            ? _master.fallbackRequirementStages
            : _master.requirementStages;
        _impactedElementOptions = _master.fallbackImpactedElements;
      }
    });
  }

  Future<void> _selectImpactedContract(String id) async {
    if (id == _impactedContractId) {
      return;
    }
    setState(() {
      _impactedContractId = id;
      _requirementStageId = '';
      _impactedElementId = '';
      _impactedElementOptions = _master.fallbackImpactedElements;
      _requirementStageOptions = const <UtilityShiftingFormOption>[];
      _loadingStages = id.isNotEmpty;
      _loadingElements = false;
    });
    if (id.isEmpty) {
      setState(() {
        _requirementStageOptions = _master.fallbackRequirementStages.isNotEmpty
            ? _master.fallbackRequirementStages
            : _master.requirementStages;
        _loadingStages = false;
      });
      return;
    }
    try {
      final List<UtilityShiftingFormOption> stages = await ref
          .read(utilityShiftingRemoteDataSourceProvider)
          .fetchRequirementStagesForForm(impactedContractId: id);
      if (!mounted || _impactedContractId != id) {
        return;
      }
      setState(() {
        _requirementStageOptions = stages.isNotEmpty
            ? stages
            : (_master.fallbackRequirementStages.isNotEmpty
                  ? _master.fallbackRequirementStages
                  : _master.requirementStages);
        _loadingStages = false;
      });
    } on Object catch (error) {
      if (!mounted || _impactedContractId != id) {
        return;
      }
      setState(() {
        _requirementStageOptions = _master.fallbackRequirementStages.isNotEmpty
            ? _master.fallbackRequirementStages
            : _master.requirementStages;
        _loadingStages = false;
      });
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Requirement Stage',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : 'Could not load requirement stages.',
      );
    }
  }

  Future<void> _selectRequirementStage(String id) async {
    if (id == _requirementStageId) {
      return;
    }
    setState(() {
      _requirementStageId = id;
      _impactedElementId = '';
      _impactedElementOptions = const <UtilityShiftingFormOption>[];
      _loadingElements = id.isNotEmpty && _impactedContractId.isNotEmpty;
    });
    if (id.isEmpty || _impactedContractId.isEmpty) {
      setState(() {
        _impactedElementOptions = _master.fallbackImpactedElements;
        _loadingElements = false;
      });
      return;
    }
    try {
      final List<UtilityShiftingFormOption> elements = await ref
          .read(utilityShiftingRemoteDataSourceProvider)
          .fetchImpactedElementsForForm(
            impactedContractId: _impactedContractId,
            requirementStage: id,
          );
      if (!mounted ||
          _requirementStageId != id ||
          _impactedContractId.isEmpty) {
        return;
      }
      setState(() {
        _impactedElementOptions = elements.isNotEmpty
            ? elements
            : _master.fallbackImpactedElements;
        _loadingElements = false;
      });
    } on Object catch (error) {
      if (!mounted || _requirementStageId != id) {
        return;
      }
      setState(() {
        _impactedElementOptions = _master.fallbackImpactedElements;
        _loadingElements = false;
      });
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Impacted Element',
        message: error is DioException
            ? userFriendlyErrorMessage(error)
            : 'Could not load impacted elements.',
      );
    }
  }

  String? _validationMessage() {
    if (_executionAgencyId.isEmpty) {
      return 'Please select an execution agency.';
    }
    if (_hodId.isEmpty) {
      return 'Please select an HOD.';
    }
    if (_utilityTypeId.isEmpty) {
      return 'Please select a utility type.';
    }
    if (_utilityDescription.text.trim().isEmpty) {
      return 'Please enter a utility description.';
    }
    if (_impactedContractId.isEmpty) {
      return 'Please select an impacted contract.';
    }
    if (_requirementStageId.isEmpty) {
      return 'Please select a requirement stage.';
    }
    return null;
  }

  String _formatApiDate(DateTime? date) {
    if (date == null) {
      return '';
    }
    return _apiDate.format(date);
  }

  Future<void> _submit() async {
    if (_saving) {
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
      final String workCode = _projectId;
      final Map<String, String> fields = <String, String>{
        'utility_description': _utilityDescription.text.trim(),
        'location_name': _locationName.text.trim(),
        'custodian': _custodian.text.trim(),
        'identification': _formatApiDate(_identificationDate),
        'reference_number': _referenceNumber.text.trim(),
        'executed_by': _executedBy.text.trim(),
        'chainage': _chainage.text.trim(),
        'latitude': _latitude.text.trim(),
        'longitude': _longitude.text.trim(),
        'affected_structures': _affectedStructures.text.trim(),
        'planned_completion_date': _formatApiDate(_targetDate),
        'scope': _scope.text.trim(),
        'completed': _completed.text.trim(),
        'start_date': _formatApiDate(_startDate),
        'shifting_completion_date': _formatApiDate(_completionDate),
        'remarks': _remarks.text.trim(),
        'project_id_fk': _projectId,
        'execution_agency_fk': _executionAgencyId,
        'hod_user_id_fk': _hodId,
        'utility_type_fk': _utilityTypeId,
        'utility_category_fk': _utilityCategoryId,
        'impacted_contract_id_fk': _impactedContractId,
        'requirement_stage_fk': _requirementStageId,
        'unit_fk': _unitId,
        'shifting_status_fk': _statusId,
        'impacted_element': _impactedElementId,
        'work_code': workCode,
      };
      if (_editing) {
        final String id = _recordId.isNotEmpty
            ? _recordId
            : _utilityShiftingId;
        final String utilityShiftingId = _utilityShiftingId.isNotEmpty
            ? _utilityShiftingId
            : _routeUtilityShiftingId;
        fields['id'] = id;
        fields['utility_shifting_id'] = utilityShiftingId.isNotEmpty
            ? utilityShiftingId
            : id;
      }
      final List<({String path, String fileName})> files =
          <({String path, String fileName})>[
            for (final UtilityShiftingAttachmentDraft item in _attachments)
              (path: item.path, fileName: item.fileName),
          ];
      final List<String> progressDates = <String>[
        for (final UtilityShiftingProgressDraft item in _progress)
          _formatApiDate(item.date),
      ];
      final List<String> progressOfWorks = <String>[
        for (final UtilityShiftingProgressDraft item in _progress)
          item.progressOfWork,
      ];
      final List<String> attachmentFileTypes = <String>[
        for (final UtilityShiftingAttachmentDraft item in _attachments)
          item.fileType,
      ];
      final List<String> attachmentNames = <String>[
        for (final UtilityShiftingAttachmentDraft item in _attachments)
          item.name,
      ];
      final List<String> attachmentFileNames = <String>[
        for (final UtilityShiftingAttachmentDraft item in _attachments)
          item.fileName,
      ];
      final UtilityShiftingRemoteDataSource remote = ref.read(
        utilityShiftingRemoteDataSourceProvider,
      );
      final String result = _editing
          ? await remote.updateUtilityShifting(
              fields: fields,
              files: files,
              progressDates: progressDates,
              progressOfWorks: progressOfWorks,
              attachmentFileTypes: attachmentFileTypes,
              attachmentNames: attachmentNames,
              attachmentFileNames: attachmentFileNames,
            )
          : await remote.addUtilityShifting(
              fields: fields,
              files: files,
              progressDates: progressDates,
              progressOfWorks: progressOfWorks,
              attachmentFileTypes: attachmentFileTypes,
              attachmentNames: attachmentNames,
              attachmentFileNames: attachmentFileNames,
            );
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: _editing ? 'Updated' : 'Saved',
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
        title: 'Save Failed',
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

  Future<void> _addProgressRow() async {
    DateTime? date = DateTime.now();
    final TextEditingController work = TextEditingController();
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Add Progress'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  InkWell(
                    onTap: () async {
                      final DateTime now = DateTime.now();
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        useRootNavigator: true,
                        initialDate: date ?? now,
                        firstDate: DateTime(now.year - 10),
                        lastDate: DateTime(now.year + 10),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          date = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Progress Date *',
                      ),
                      child: Text(
                        date == null
                            ? 'Select'
                            : _displayDate.format(date!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: work,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Progress of Work *',
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (date == null || work.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
    final DateTime? selectedDate = date;
    final String progressText = work.text.trim();
    work.dispose();
    if (saved != true || selectedDate == null || progressText.isEmpty) {
      return;
    }
    setState(() {
      _progress.add(
        UtilityShiftingProgressDraft(
          date: selectedDate,
          progressOfWork: progressText,
        ),
      );
    });
  }

  Future<void> _addAttachmentRow() async {
    String fileTypeId = _master.fileTypes.isNotEmpty
        ? _master.fileTypes.first.id
        : '';
    final TextEditingController name = TextEditingController();
    String? path;
    String fileName = '';
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Add Attachment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (_master.fileTypes.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: fileTypeId.isEmpty ? null : fileTypeId,
                        decoration: const InputDecoration(
                          labelText: 'File Type *',
                        ),
                        items: <DropdownMenuItem<String>>[
                          for (final UtilityShiftingFormOption option
                              in _master.fileTypes)
                            DropdownMenuItem<String>(
                              value: option.id,
                              child: Text(option.label),
                            ),
                        ],
                        onChanged: (String? value) {
                          setDialogState(() => fileTypeId = value ?? '');
                        },
                      )
                    else
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'File Type *',
                        ),
                        onChanged: (String value) => fileTypeId = value.trim(),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name *'),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final FilePickerResult? picked =
                              await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: _allowedExtensions,
                                withData: false,
                              );
                          final PlatformFile? file = picked?.files.single;
                          final String? pickedPath = file?.path;
                          if (pickedPath == null || pickedPath.isEmpty) {
                            return;
                          }
                          setDialogState(() {
                            path = pickedPath;
                            fileName = (file?.name.trim().isNotEmpty ?? false)
                                ? file!.name
                                : p.basename(pickedPath);
                          });
                        },
                        icon: const Icon(Icons.attach_file_rounded),
                        label: Text(
                          fileName.isEmpty ? 'Choose file' : fileName,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (fileTypeId.trim().isEmpty ||
                        name.text.trim().isEmpty ||
                        path == null ||
                        path!.isEmpty) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
    final String attachmentName = name.text.trim();
    final String? attachmentPath = path;
    name.dispose();
    if (saved != true ||
        fileTypeId.trim().isEmpty ||
        attachmentName.isEmpty ||
        attachmentPath == null ||
        attachmentPath.isEmpty) {
      return;
    }
    setState(() {
      _attachments.add(
        UtilityShiftingAttachmentDraft(
          fileType: fileTypeId.trim(),
          name: attachmentName,
          fileName: fileName.isEmpty ? p.basename(attachmentPath) : fileName,
          path: attachmentPath,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<UtilityShiftingFormMaster> masterAsync = ref.watch(
      utilityShiftingFormMasterProvider,
    );
    final AsyncValue<UtilityShiftingDetail>? detailAsync = _editing
        ? ref.watch(utilityShiftingDetailProvider(_routeUtilityShiftingId))
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
      final UtilityShiftingFormMaster master = masterAsync.requireValue;
      final UtilityShiftingDetail? detail = detailAsync?.asData?.value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _seeded) {
          return;
        }
        if (_editing && (detail == null || detail.isEmpty)) {
          _reportLoadError(
            StateError('Utility shifting record not found.'),
          );
          return;
        }
        _seed(master, detail: detail);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing ? 'Edit Utility Shifting' : 'Add Utility Shifting',
        ),
      ),
      body: loadError != null
          ? _ErrorBody(onRetry: _retry)
          : !ready || !_seeded
          ? const Center(child: CircularProgressIndicator())
          : _form(),
    );
  }

  Widget _form() {
    final bool busy =
        _saving || _loadingStages || _loadingElements || _loadingCascades;
    return Column(
      children: <Widget>[
        if (busy) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: <Widget>[
              _Section(
                title: 'Details',
                children: <Widget>[
                  _dropdown(
                    label: 'Project',
                    options: _master.projects,
                    selectedId: _projectId,
                    onPick: _selectProject,
                  ),
                  _dropdown(
                    label: 'Execution Agency *',
                    options: _master.executionAgencies,
                    selectedId: _executionAgencyId,
                    onPick: (String id) =>
                        setState(() => _executionAgencyId = id),
                  ),
                  _dropdown(
                    label: 'HOD *',
                    options: _master.hods,
                    selectedId: _hodId,
                    onPick: (String id) => setState(() => _hodId = id),
                  ),
                  _dropdown(
                    label: 'Utility Type *',
                    options: _master.utilityTypes,
                    selectedId: _utilityTypeId,
                    onPick: (String id) => setState(() => _utilityTypeId = id),
                  ),
                  _dropdown(
                    label: 'Utility Category',
                    options: _master.utilityCategories,
                    selectedId: _utilityCategoryId,
                    onPick: (String id) =>
                        setState(() => _utilityCategoryId = id),
                  ),
                  _text(
                    _utilityDescription,
                    label: 'Utility Description *',
                    maxLines: 3,
                  ),
                  _text(
                    _locationName,
                    label: 'Location Name',
                    maxLength: 50,
                  ),
                  _text(_custodian, label: 'Custodian'),
                  _dateField(
                    label: 'Identification Date',
                    value: _identificationDate,
                    onPicked: (DateTime? date) {
                      setState(() => _identificationDate = date);
                    },
                  ),
                  _text(_referenceNumber, label: 'Reference Number'),
                  _text(_executedBy, label: 'Executed by'),
                  _text(_chainage, label: 'Chainage'),
                  _text(
                    _latitude,
                    label: 'Latitude',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                  _text(
                    _longitude,
                    label: 'Longitude',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                  _dropdown(
                    label: 'Impacted Contract *',
                    options: _impactedContractOptions,
                    selectedId: _impactedContractId,
                    onPick: _selectImpactedContract,
                  ),
                  _dropdown(
                    label: 'Requirement Stage *',
                    options: _requirementStageOptions,
                    selectedId: _requirementStageId,
                    enabled:
                        _impactedContractId.isNotEmpty && !_loadingStages,
                    onPick: _selectRequirementStage,
                  ),
                  _dropdown(
                    label: 'Impacted Element',
                    options: _impactedElementOptions,
                    selectedId: _impactedElementId,
                    enabled:
                        _requirementStageId.isNotEmpty && !_loadingElements,
                    onPick: (String id) =>
                        setState(() => _impactedElementId = id),
                  ),
                  _text(_affectedStructures, label: 'Affected Structures'),
                  _dateField(
                    label: 'Target Date',
                    value: _targetDate,
                    onPicked: (DateTime? date) {
                      setState(() => _targetDate = date);
                    },
                  ),
                  _text(_scope, label: 'Scope', maxLength: 25),
                  _text(_completed, label: 'Completed', maxLength: 25),
                  _dropdown(
                    label: 'Unit',
                    options: _master.units,
                    selectedId: _unitId,
                    onPick: (String id) => setState(() => _unitId = id),
                  ),
                  _dateField(
                    label: 'Start Date',
                    value: _startDate,
                    onPicked: (DateTime? date) {
                      setState(() => _startDate = date);
                    },
                  ),
                  _dropdown(
                    label: 'Status',
                    options: _master.statuses,
                    selectedId: _statusId,
                    onPick: (String id) => setState(() => _statusId = id),
                  ),
                  _dateField(
                    label: 'Completion Date',
                    value: _completionDate,
                    onPicked: (DateTime? date) {
                      setState(() => _completionDate = date);
                    },
                  ),
                ],
              ),
              _Section(
                title: 'Progress Details',
                children: <Widget>[
                  if (_progress.isEmpty)
                    Text(
                      'No progress details added yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    for (int i = 0; i < _progress.length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _displayDate.format(_progress[i].date),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(_progress[i].progressOfWork),
                        trailing: IconButton(
                          tooltip: 'Remove',
                          onPressed: () {
                            setState(() => _progress.removeAt(i));
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      tooltip: 'Add progress',
                      onPressed: _saving ? null : _addProgressRow,
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                      icon: const Icon(Icons.playlist_add_rounded),
                    ),
                  ),
                ],
              ),
              _Section(
                title: 'Attachments',
                children: <Widget>[
                  if (_attachments.isEmpty)
                    Text(
                      'No attachments added yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    for (int i = 0; i < _attachments.length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _attachments[i].name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          '${_attachments[i].fileType} · ${_attachments[i].fileName}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove',
                          onPressed: () {
                            setState(() => _attachments.removeAt(i));
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      tooltip: 'Add attachment',
                      onPressed: _saving ? null : _addAttachmentRow,
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                      icon: const Icon(Icons.playlist_add_rounded),
                    ),
                  ),
                ],
              ),
              _Section(
                title: 'Remarks',
                children: <Widget>[
                  _text(
                    _remarks,
                    label: 'Remarks',
                    maxLines: 4,
                    maxLength: 1000,
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
                onPressed: _saving ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _saving || _loadingCascades ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_editing ? 'Update' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required List<UtilityShiftingFormOption> options,
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
                for (final UtilityShiftingFormOption option in options)
                  RfiFilterOption(id: option.id, label: option.label),
              ],
              selectedId: selectedId.isEmpty ? null : selectedId,
              onClear: !enabled || selectedId.isEmpty
                  ? null
                  : () => onPick(''),
              onPick: (RfiFilterOption option) => onPick(option.id),
            ),
          ),
        ),
      ),
    );
  }

  String? _labelOf(List<UtilityShiftingFormOption> options, String id) {
    if (id.isEmpty) {
      return null;
    }
    for (final UtilityShiftingFormOption option in options) {
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
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: keyboardType?.decimal == true
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
              ]
            : null,
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
    required ValueChanged<DateTime?> onPicked,
  }) {
    final String text = value == null ? 'dd/mm/yyyy' : _displayDate.format(value);
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
            firstDate: DateTime(now.year - 10),
            lastDate: DateTime(now.year + 10),
          );
          if (picked != null) {
            onPicked(DateTime(picked.year, picked.month, picked.day));
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: value == null
                ? const Icon(Icons.calendar_today_rounded, size: 18)
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: () => onPicked(null),
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
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.brandPrimary,
              fontWeight: FontWeight.w800,
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
              'Could not load the utility shifting form.',
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
