import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_filter_field.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/data/datasources/structure_form_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/domain/structure_form_detail.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/presentation/providers/structure_form_edit_provider.dart';

class UpdateStructureFormPage extends ConsumerStatefulWidget {
  const UpdateStructureFormPage({super.key, required this.structureId});

  final String structureId;

  static const String routeName = 'update-structure-form';
  static const String routePath = '/module/structure-form/edit/:structureId';

  static String location({required String structureId}) {
    return '/module/structure-form/edit/${Uri.encodeComponent(structureId.trim())}';
  }

  @override
  ConsumerState<UpdateStructureFormPage> createState() =>
      _UpdateStructureFormPageState();
}

class _UpdateStructureFormPageState
    extends ConsumerState<UpdateStructureFormPage> {
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

  final TextEditingController _structureName = TextEditingController();
  final TextEditingController _structureIdField = TextEditingController();

  StructureFormMaster _master = StructureFormMaster.empty;
  List<StructureFormFormOption> _contractOptions =
      const <StructureFormFormOption>[];
  bool _seeded = false;
  bool _reportedLoadError = false;
  bool _saving = false;
  bool _loadingContracts = false;

  String _structureId = '';
  String _projectId = '';
  String _structureTypeId = '';
  String _workStatusId = '';

  final List<_ExecutiveDraft> _executives = <_ExecutiveDraft>[];
  final List<_DetailDraft> _details = <_DetailDraft>[];
  final List<_DocumentDraft> _documents = <_DocumentDraft>[];

  String get _routeStructureId => widget.structureId.trim();

  @override
  void dispose() {
    _structureName.dispose();
    _structureIdField.dispose();
    for (final _ExecutiveDraft row in _executives) {
      row.dispose();
    }
    for (final _DetailDraft row in _details) {
      row.dispose();
    }
    for (final _DocumentDraft row in _documents) {
      row.dispose();
    }
    super.dispose();
  }

  String _match(List<StructureFormFormOption> options, String raw) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    for (final StructureFormFormOption option in options) {
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

  Future<void> _seed(StructureFormMaster master) async {
    final StructureFormDetail detail = master.detail ?? StructureFormDetail.empty;
    _master = master;
    _contractOptions = master.contracts;
    _structureId = detail.structureId.isNotEmpty
        ? detail.structureId
        : _routeStructureId;
    _projectId = _match(master.projects, detail.projectIdFk);
    _structureTypeId = _match(master.structureTypes, detail.structureTypeFk);
    _workStatusId = _match(master.workStatuses, detail.workStatusFk);
    _structureName.text = detail.structureName.isNotEmpty
        ? detail.structureName
        : detail.structure;
    _structureIdField.text = detail.structure.isNotEmpty
        ? detail.structure
        : detail.structureName;

    for (final _ExecutiveDraft row in _executives) {
      row.dispose();
    }
    _executives
      ..clear()
      ..addAll(detail.executives.map(_ExecutiveDraft.fromModel));
    if (_executives.isEmpty) {
      _executives.add(_ExecutiveDraft.empty());
    }

    for (final _DetailDraft row in _details) {
      row.dispose();
    }
    _details
      ..clear()
      ..addAll(detail.details.map(_DetailDraft.fromModel));
    if (_details.isEmpty) {
      _details.add(_DetailDraft.empty());
    }

    for (final _DocumentDraft row in _documents) {
      row.dispose();
    }
    _documents
      ..clear()
      ..addAll(detail.documents.map(_DocumentDraft.fromModel));
    if (_documents.isEmpty) {
      _documents.add(_DocumentDraft.empty());
    }

    _seeded = true;
    if (mounted) {
      setState(() {});
    }
    if (_projectId.isNotEmpty) {
      await _reloadContractsForProject(_projectId, keepSelection: true);
    }
  }

  Future<void> _reloadContractsForProject(
    String projectId, {
    required bool keepSelection,
  }) async {
    setState(() => _loadingContracts = true);
    try {
      final List<StructureFormFormOption> contracts = await ref
          .read(structureFormRemoteDataSourceProvider)
          .fetchContractsForProject(projectIdFk: projectId);
      if (!mounted) {
        return;
      }
      setState(() {
        _contractOptions = contracts.isNotEmpty ? contracts : _master.contracts;
        if (!keepSelection) {
          for (final _ExecutiveDraft row in _executives) {
            row.contractId = '';
          }
        } else {
          for (final _ExecutiveDraft row in _executives) {
            row.contractId = _match(_contractOptions, row.contractId);
          }
        }
        _loadingContracts = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _contractOptions = _master.contracts;
        _loadingContracts = false;
      });
    }
  }

  Future<void> _selectProject(String projectId) async {
    if (projectId == _projectId) {
      return;
    }
    setState(() => _projectId = projectId);
    await _reloadContractsForProject(projectId, keepSelection: false);
  }

  Future<void> _reportLoadError(Object error) async {
    if (_reportedLoadError || !mounted) {
      return;
    }
    _reportedLoadError = true;
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: 'Update Structure Form',
      message: error is DioException
          ? userFriendlyErrorMessage(error)
          : error.toString(),
    );
  }

  Future<void> _retry() async {
    _reportedLoadError = false;
    _seeded = false;
    ref.invalidate(structureFormEditProvider(_routeStructureId));
  }

  String? _validationMessage() {
    if (_projectId.trim().isEmpty) {
      return 'Please select a project.';
    }
    if (_structureTypeId.trim().isEmpty) {
      return 'Please select a structure type.';
    }
    if (_structureName.text.trim().isEmpty) {
      return 'Please enter the structure name.';
    }
    if (_structureIdField.text.trim().isEmpty) {
      return 'Please enter the structure ID.';
    }
    for (int i = 0; i < _executives.length; i++) {
      final _ExecutiveDraft row = _executives[i];
      if (row.contractId.trim().isEmpty) {
        return 'Please select a contract for executive row ${i + 1}.';
      }
      if (row.personIds.isEmpty) {
        return 'Please select responsible executives for row ${i + 1}.';
      }
    }
    return null;
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
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final List<String> contractsIdFk = <String>[
        for (final _ExecutiveDraft row in _executives) row.contractId.trim(),
      ];
      final List<String> responsiblePeopleIdFks = <String>[
        for (final _ExecutiveDraft row in _executives)
          row.personIds.join(','),
      ];
      final List<String> structureDetails = <String>[
        for (final _DetailDraft row in _details)
          if (row.detail.text.trim().isNotEmpty ||
              row.value.text.trim().isNotEmpty)
            row.detail.text.trim(),
      ];
      final List<String> structureValues = <String>[
        for (final _DetailDraft row in _details)
          if (row.detail.text.trim().isNotEmpty ||
              row.value.text.trim().isNotEmpty)
            row.value.text.trim(),
      ];
      final List<_DocumentDraft> docsToSend = <_DocumentDraft>[
        for (final _DocumentDraft row in _documents)
          if (row.fileType.trim().isNotEmpty ||
              row.name.text.trim().isNotEmpty ||
              row.existingAttachment.isNotEmpty ||
              row.localPath.isNotEmpty)
            row,
      ];
      final List<String> structureFileTypes = <String>[
        for (final _DocumentDraft row in docsToSend) row.fileType.trim(),
      ];
      final List<String> structureDocumentNames = <String>[
        for (final _DocumentDraft row in docsToSend) row.name.text.trim(),
      ];
      final List<String> structureFileNames = <String>[
        for (final _DocumentDraft row in docsToSend) row.submitFileName,
      ];
      final List<({String? path, String fileName})> structureFiles =
          <({String? path, String fileName})>[
            for (final _DocumentDraft row in docsToSend)
              (
                path: row.localPath.isEmpty ? null : row.localPath,
                fileName: row.submitFileName,
              ),
          ];

      final String result = await ref
          .read(structureFormRemoteDataSourceProvider)
          .updateStructureForm(
            fields: <String, String>{
              'project_id_fk': _projectId.trim(),
              'structure_type_fk': _structureTypeId.trim(),
              'structure_name': _structureName.text.trim(),
              'structure': _structureIdField.text.trim(),
              'work_status_fk': _workStatusId.trim(),
              'structure_id': _structureId.trim().isEmpty
                  ? _routeStructureId
                  : _structureId.trim(),
            },
            contractsIdFk: contractsIdFk,
            responsiblePeopleIdFks: responsiblePeopleIdFks,
            structureDetails: structureDetails,
            structureValues: structureValues,
            structureFileTypes: structureFileTypes,
            structureDocumentNames: structureDocumentNames,
            structureFileNames: structureFileNames,
            structureFiles: structureFiles,
          );
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.success,
        title: 'Update Structure Form',
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
        title: 'Update Structure Form',
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

  Future<void> _pickPeople(_ExecutiveDraft row) async {
    final Set<String> selected = Set<String>.from(row.personIds);
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Responsible Executives'),
              content: SizedBox(
                width: 420,
                child: _master.responsiblePeople.isEmpty
                    ? const Text('No responsible people available.')
                    : ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          for (final StructureFormPersonOption person
                              in _master.responsiblePeople)
                            CheckboxListTile(
                              value: selected.contains(person.id),
                              title: Text(person.label),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (bool? checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    selected.add(person.id);
                                  } else {
                                    selected.remove(person.id);
                                  }
                                });
                              },
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
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved != true || !mounted) {
      return;
    }
    setState(() {
      row.personIds
        ..clear()
        ..addAll(selected);
      row.peopleLabels
        ..clear()
        ..addAll(
          selected.map((String id) {
            for (final StructureFormPersonOption person
                in _master.responsiblePeople) {
              if (person.id == id) {
                return person.label;
              }
            }
            return id;
          }),
        );
    });
  }

  Future<void> _pickDocumentFile(_DocumentDraft row) async {
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: false,
    );
    final PlatformFile? file = picked?.files.single;
    final String? path = file?.path;
    if (path == null || path.isEmpty || !mounted) {
      return;
    }
    setState(() {
      row.localPath = path;
      row.localFileName = (file?.name.trim().isNotEmpty ?? false)
          ? file!.name
          : p.basename(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<StructureFormMaster> masterAsync = ref.watch(
      structureFormEditProvider(_routeStructureId),
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
      final StructureFormMaster master = masterAsync.requireValue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _seeded) {
          return;
        }
        _seed(master);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Update Structure Form')),
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
                title: 'Structure',
                children: <Widget>[
                  _dropdown(
                    label: 'Project *',
                    options: _withId(_master.projects, _projectId),
                    selectedId: _projectId,
                    onPick: _selectProject,
                  ),
                  _dropdown(
                    label: 'Structure Type *',
                    options: _withId(_master.structureTypes, _structureTypeId),
                    selectedId: _structureTypeId,
                    onPick: (String id) =>
                        setState(() => _structureTypeId = id),
                  ),
                  _text(_structureName, label: 'Structure Name *'),
                  _text(_structureIdField, label: 'Structure ID *'),
                  _dropdown(
                    label: 'Work Status',
                    options: _withId(_master.workStatuses, _workStatusId),
                    selectedId: _workStatusId,
                    onPick: (String id) => setState(() => _workStatusId = id),
                  ),
                ],
              ),
              _Section(
                title: 'Contract - Execution Executives',
                children: <Widget>[
                  if (_loadingContracts)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  for (int i = 0; i < _executives.length; i++)
                    _executiveCard(i),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Add executive row',
                      onPressed: () {
                        setState(() => _executives.add(_ExecutiveDraft.empty()));
                      },
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
              _Section(
                title: 'Structure Details',
                children: <Widget>[
                  for (int i = 0; i < _details.length; i++) _detailCard(i),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Add detail row',
                      onPressed: () {
                        setState(() => _details.add(_DetailDraft.empty()));
                      },
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
              _Section(
                title: 'Documents',
                children: <Widget>[
                  for (int i = 0; i < _documents.length; i++) _documentCard(i),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Add document row',
                      onPressed: () {
                        setState(() => _documents.add(_DocumentDraft.empty()));
                      },
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update'),
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

  Widget _executiveCard(int index) {
    final _ExecutiveDraft row = _executives[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _dropdown(
                    label: 'Contract *',
                    options: _withId(_contractOptions, row.contractId),
                    selectedId: row.contractId,
                    onPick: (String id) => setState(() => row.contractId = id),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: _executives.length <= 1
                      ? null
                      : () {
                          setState(() {
                            final _ExecutiveDraft removed = _executives
                                .removeAt(index);
                            removed.dispose();
                          });
                        },
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.red.shade700,
                ),
              ],
            ),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Responsible Executives *',
                border: OutlineInputBorder(),
              ),
              child: InkWell(
                onTap: () => _pickPeople(row),
                child: row.peopleLabels.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Select executives'),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          for (int i = 0; i < row.peopleLabels.length; i++)
                            InputChip(
                              label: Text(row.peopleLabels[i]),
                              onDeleted: () {
                                setState(() {
                                  if (i < row.personIds.length) {
                                    row.personIds.removeAt(i);
                                  }
                                  row.peopleLabels.removeAt(i);
                                });
                              },
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

  Widget _detailCard(int index) {
    final _DetailDraft row = _details[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  _text(row.detail, label: 'Structure Detail'),
                  _text(row.value, label: 'Value'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: _details.length <= 1
                  ? null
                  : () {
                      setState(() {
                        final _DetailDraft removed = _details.removeAt(index);
                        removed.dispose();
                      });
                    },
              icon: const Icon(Icons.delete_outline_rounded),
              color: Colors.red.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentCard(int index) {
    final _DocumentDraft row = _documents[index];
    final String existing = row.existingAttachment.trim();
    final String local = row.localFileName.trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _master.fileTypes.isEmpty
                      ? TextFormField(
                          initialValue: row.fileType,
                          decoration: const InputDecoration(
                            labelText: 'File Type',
                          ),
                          onChanged: (String value) => row.fileType = value,
                        )
                      : _dropdown(
                          label: 'File Type',
                          options: _withId(_master.fileTypes, row.fileType),
                          selectedId: row.fileType,
                          onPick: (String id) =>
                              setState(() => row.fileType = id),
                        ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: _documents.length <= 1
                      ? null
                      : () {
                          setState(() {
                            final _DocumentDraft removed = _documents.removeAt(
                              index,
                            );
                            removed.dispose();
                          });
                        },
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.red.shade700,
                ),
              ],
            ),
            _text(row.name, label: 'Name'),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _pickDocumentFile(row),
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(local.isEmpty ? 'Upload File' : local),
              ),
            ),
            if (existing.isNotEmpty && local.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Existing file: $existing',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.brandPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<StructureFormFormOption> _withId(
    List<StructureFormFormOption> options,
    String selectedId,
  ) {
    final String id = selectedId.trim();
    if (id.isEmpty ||
        options.any((StructureFormFormOption option) => option.id == id)) {
      return options;
    }
    return <StructureFormFormOption>[
      ...options,
      StructureFormFormOption(id: id, label: id),
    ];
  }

  Widget _dropdown({
    required String label,
    required List<StructureFormFormOption> options,
    required String selectedId,
    required ValueChanged<String> onPick,
  }) {
    final String? id = selectedId.trim().isEmpty ? null : selectedId.trim();
    String? valueLabel;
    if (id != null) {
      for (final StructureFormFormOption option in options) {
        if (option.id == id) {
          valueLabel = option.label;
          break;
        }
      }
      valueLabel ??= id;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RfiFilterField(
        label: label,
        value: valueLabel,
        emptyLabel: 'Select',
        options: <RfiFilterOption>[
          for (final StructureFormFormOption option in options)
            RfiFilterOption(id: option.id, label: option.label),
        ],
        selectedId: id,
        onClear: id == null ? null : () => onPick(''),
        onPick: (RfiFilterOption option) => onPick(option.id),
      ),
    );
  }

  Widget _text(TextEditingController controller, {required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.brandPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
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
            const Text('Unable to load structure form.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ExecutiveDraft {
  _ExecutiveDraft({
    required this.contractId,
    required List<String> personIds,
    required List<String> peopleLabels,
  }) : personIds = List<String>.from(personIds),
       peopleLabels = List<String>.from(peopleLabels);

  factory _ExecutiveDraft.empty() =>
      _ExecutiveDraft(contractId: '', personIds: <String>[], peopleLabels: <String>[]);

  factory _ExecutiveDraft.fromModel(StructureFormExecutiveRow row) {
    return _ExecutiveDraft(
      contractId: row.contractIdFk,
      personIds: row.people.map((StructureFormResponsiblePerson p) => p.id).toList(),
      peopleLabels: row.people
          .map((StructureFormResponsiblePerson p) => p.label)
          .toList(),
    );
  }

  String contractId;
  final List<String> personIds;
  final List<String> peopleLabels;

  void dispose() {}
}

class _DetailDraft {
  _DetailDraft({required String detail, required String value})
    : detail = TextEditingController(text: detail),
      value = TextEditingController(text: value);

  factory _DetailDraft.empty() => _DetailDraft(detail: '', value: '');

  factory _DetailDraft.fromModel(StructureFormDetailRow row) {
    return _DetailDraft(
      detail: row.structureDetail,
      value: row.structureValue,
    );
  }

  final TextEditingController detail;
  final TextEditingController value;

  void dispose() {
    detail.dispose();
    value.dispose();
  }
}

class _DocumentDraft {
  _DocumentDraft({
    required this.fileType,
    required String name,
    this.existingAttachment = '',
  }) : name = TextEditingController(text: name);

  factory _DocumentDraft.empty() => _DocumentDraft(fileType: '', name: '');

  factory _DocumentDraft.fromModel(StructureFormDocumentRow row) {
    return _DocumentDraft(
      fileType: row.fileType,
      name: row.name,
      existingAttachment: row.existingAttachment,
    );
  }

  String fileType;
  final TextEditingController name;
  String existingAttachment;
  String localPath = '';
  String localFileName = '';

  String get submitFileName {
    if (localFileName.trim().isNotEmpty) {
      return localFileName.trim();
    }
    return existingAttachment.trim();
  }

  void dispose() {
    name.dispose();
  }
}
