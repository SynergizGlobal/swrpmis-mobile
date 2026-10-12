import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_reference_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_reference.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_reference_provider.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_reference_table.dart';

class RfiReferenceView extends ConsumerStatefulWidget {
  const RfiReferenceView({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  ConsumerState<RfiReferenceView> createState() => _RfiReferenceViewState();
}

enum _Editor { none, add, edit }

class _RfiReferenceViewState extends ConsumerState<RfiReferenceView> {
  final TextEditingController _search = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _activity = TextEditingController();
  final TextEditingController _rfiDescription = TextEditingController();
  final TextEditingController _checklistEdit = TextEditingController();
  final List<TextEditingController> _checklistAdds = <TextEditingController>[
    TextEditingController(),
  ];
  final List<TextEditingController> _retired = <TextEditingController>[];
  final TextEditingController _activityLocked = TextEditingController(
    text: 'N/A',
  );

  _Editor _editor = _Editor.none;
  int? _editingId;
  String? _category;
  String? _action;
  List<String> _enclosureIds = <String>[];
  List<RfiEnclosureNameOption> _nameOptions = <RfiEnclosureNameOption>[];
  bool _saving = false;
  bool _loadingNames = false;
  int _namesTicket = 0;
  int? _deletingId;
  StateSetter? _sheetSetter;
  BuildContext? _sheetContext;

  @override
  void dispose() {
    _search.dispose();
    _name.dispose();
    _activity.dispose();
    _rfiDescription.dispose();
    _checklistEdit.dispose();
    _activityLocked.dispose();
    for (final TextEditingController controller in _checklistAdds) {
      controller.dispose();
    }
    for (final TextEditingController controller in _retired) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _busy => _saving || _deletingId != null;

  void _resetLocal() {
    _editor = _Editor.none;
    _editingId = null;
    _category = null;
    _action = null;
    _name.clear();
    _activity.clear();
    _rfiDescription.clear();
    _checklistEdit.clear();
    _enclosureIds = <String>[];
    _clearNameOptions();
    _search.clear();
    _retireChecklistAdds();
  }

  void _closeEditor() {
    _editor = _Editor.none;
    _editingId = null;
    _category = null;
    _action = null;
    _name.clear();
    _activity.clear();
    _rfiDescription.clear();
    _checklistEdit.clear();
    _enclosureIds = <String>[];
    _clearNameOptions();
  }

  void _clearNameOptions() {
    _namesTicket++;
    _loadingNames = false;
    _nameOptions = <RfiEnclosureNameOption>[];
  }

  void _mutate(VoidCallback change) {
    if (!mounted) {
      return;
    }
    setState(change);
    _sheetSetter?.call(() {});
  }

  void _dismissSheet() {
    final BuildContext? sheet = _sheetContext;
    if (sheet != null && sheet.mounted) {
      Navigator.of(sheet).pop();
    }
  }

  Future<void> _openFormSheet({
    required String title,
    required Widget Function() buildBody,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheet) {
              _sheetSetter = setSheet;
              _sheetContext = sheetContext;
              final double maxHeight = MediaQuery.sizeOf(context).height * 0.85;
              return SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: ListView(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      buildBody(),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      _sheetSetter = null;
      _sheetContext = null;
      if (mounted) {
        setState(_closeEditor);
      }
    });
  }

  void _retireChecklistAdds() {
    _retired.addAll(_checklistAdds);
    _checklistAdds
      ..clear()
      ..add(TextEditingController());
  }

  Future<void> _pickForm() async {
    final RfiReferenceState data = ref.read(rfiReferenceControllerProvider);
    final String? picked = await _pick(
      context,
      title: 'Select Form',
      emptyMessage: 'No forms',
      options: <({String id, String label})>[
        (id: '', label: '-- Select --'),
        for (final RfiReferenceForm form in RfiReferenceForm.values)
          (id: form.name, label: form.label),
      ],
      selectedId: data.form?.name ?? '',
    );
    if (picked == null || !mounted) {
      return;
    }
    RfiReferenceForm? form;
    if (picked.isNotEmpty) {
      for (final RfiReferenceForm item in RfiReferenceForm.values) {
        if (item.name == picked) {
          form = item;
          break;
        }
      }
    }
    if (form == data.form) {
      return;
    }
    setState(_resetLocal);
    await ref.read(rfiReferenceControllerProvider.notifier).selectForm(form);
  }

  Future<void> _pickSubOption(RfiReferenceState data) async {
    final String? picked = await _pick(
      context,
      title: 'Sub Option',
      emptyMessage: 'No enclosures',
      options: <({String id, String label})>[
        for (final RfiEnclosure option in data.subOptions)
          if (option.id != null)
            (
              id: '${option.id}',
              label: option.encloserName.isEmpty
                  ? '${option.id}'
                  : option.encloserName,
            ),
      ],
      selectedId: data.selectedEnclosureId?.toString(),
    );
    if (picked == null || !mounted) {
      return;
    }
    final int? id = int.tryParse(picked);
    if (id == null || id == data.selectedEnclosureId) {
      return;
    }
    setState(() {
      _editor = _Editor.none;
      _editingId = null;
      _checklistEdit.clear();
      _search.clear();
      _retireChecklistAdds();
    });
    await ref.read(rfiReferenceControllerProvider.notifier).selectEnclosure(id);
  }

  Future<void> _pickCategory() async {
    final String? picked = await _pick(
      context,
      title: 'RFI Category',
      emptyMessage: 'No categories',
      options: _categoryOptions(),
      selectedId: _category,
    );
    if (picked == null || !mounted || picked == _category) {
      return;
    }
    final bool description =
        ref.read(rfiReferenceControllerProvider).form ==
        RfiReferenceForm.description;
    _mutate(() => _category = picked);
    if (!description) {
      return;
    }
    _mutate(() {
      _enclosureIds = <String>[];
      _nameOptions = <RfiEnclosureNameOption>[];
    });
    await _loadEnclosureNames(picked);
  }

  Future<void> _pickAction() async {
    final String? picked = await _pick(
      context,
      title: 'Action Type',
      emptyMessage: 'No actions',
      options: _actionOptions(),
      selectedId: _action,
    );
    if (picked == null || !mounted) {
      return;
    }
    _mutate(() => _action = picked);
  }

  Future<void> _loadEnclosureNames(String category) async {
    final int ticket = ++_namesTicket;
    _mutate(() => _loadingNames = true);
    try {
      final List<RfiEnclosureNameOption> options = await ref
          .read(rfiReferenceRemoteDataSourceProvider)
          .fetchEnclosureNames(category);
      if (!mounted || ticket != _namesTicket) {
        return;
      }
      _mutate(() {
        _nameOptions = options;
        _loadingNames = false;
      });
    } on Object catch (error) {
      if (!mounted || ticket != _namesTicket) {
        return;
      }
      _mutate(() {
        _nameOptions = <RfiEnclosureNameOption>[];
        _loadingNames = false;
      });
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Enclosures unavailable',
        message: _failureMessage(error),
      );
    }
  }

  Future<void> _pickDescriptionEnclosures() async {
    final String? category = _category;
    if (category == null || category.isEmpty || _loadingNames) {
      return;
    }
    final List<RfiEnclosureNameOption> options = _nameOptions;
    final List<String>? picked = await showModalBottomSheet<List<String>>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final List<String> selected = List<String>.from(_enclosureIds);
        final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.7;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setSheetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Enclosures',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          _NavyButton(
                            label: 'Done',
                            onPressed: () =>
                                Navigator.pop(sheetContext, selected),
                          ),
                        ],
                      ),
                    ),
                    if (options.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No enclosures for this category.'),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          children: <Widget>[
                            for (final RfiEnclosureNameOption option in options)
                              CheckboxListTile(
                                value: selected.contains(option.id),
                                title: Text(
                                  option.label.isEmpty
                                      ? option.id
                                      : option.label,
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (bool? checked) {
                                  setSheetState(() {
                                    final String id = option.id;
                                    if (checked ?? false) {
                                      if (!selected.contains(id)) {
                                        selected.add(id);
                                      }
                                    } else {
                                      selected.remove(id);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    _mutate(() => _enclosureIds = picked);
  }

  Future<void> _refresh() {
    return ref.read(rfiReferenceControllerProvider.notifier).refresh();
  }

  Future<void> _saveEnclosure() async {
    final String name = _name.text.trim();
    final String? action = _action;
    final String? category = _category;
    if (name.isEmpty ||
        action == null ||
        action.isEmpty ||
        category == null ||
        category.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: 'Missing information',
        message: 'Enter an enclosure name, action type, and RFI category.',
      );
      return;
    }
    final bool editing = _editor == _Editor.edit;
    final int? id = _editingId;
    if (editing && id == null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: 'Update unavailable',
        message: 'This enclosure cannot be updated.',
      );
      return;
    }
    _mutate(() => _saving = true);
    final RfiReferenceRemoteDataSource dataSource = ref.read(
      rfiReferenceRemoteDataSourceProvider,
    );
    try {
      if (editing) {
        await dataSource.updateEnclosure(
          id: id!,
          encloserName: name,
          action: action,
          rfiCategory: category,
        );
      } else {
        await dataSource.submitEnclosure(
          encloserName: name,
          action: action,
          rfiCategory: category,
        );
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: editing ? 'Update failed' : 'Save failed',
        message: _failureMessage(error),
      );
      return;
    } finally {
      if (mounted) {
        _mutate(() => _saving = false);
      }
    }
    if (!mounted) {
      return;
    }
    _dismissSheet();
    await _afterWrite(
      successTitle: editing ? 'Updated' : 'Added',
      successMessage: editing
          ? 'The enclosure was updated.'
          : 'The enclosure was added.',
    );
  }

  Future<void> _deleteEnclosure(RfiEnclosure row) async {
    final int? id = row.id;
    if (id == null || _busy) {
      return;
    }
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Delete enclosure',
      message: 'Delete this enclosure?',
      primaryLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _deletingId = id);
    try {
      await ref.read(rfiReferenceRemoteDataSourceProvider).deleteEnclosure(id);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Delete failed',
        message: _failureMessage(error),
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _deletingId = null);
      }
    }
    if (!mounted) {
      return;
    }
    if (_editingId == id) {
      setState(_closeEditor);
    }
    await _afterWrite(
      successTitle: 'Deleted',
      successMessage: 'The enclosure was deleted.',
    );
  }

  Future<void> _saveChecklist() async {
    final int? enclosureId = ref
        .read(rfiReferenceControllerProvider)
        .selectedEnclosureId;
    if (enclosureId == null || _busy) {
      return;
    }
    final List<String> descriptions = _checklistAdds
        .map((TextEditingController controller) => controller.text.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
    if (descriptions.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: 'Missing information',
        message: 'Enter a checklist description.',
      );
      return;
    }
    _mutate(() => _saving = true);
    RfiChecklistSaveResult result;
    try {
      result = await ref
          .read(rfiReferenceRemoteDataSourceProvider)
          .addChecklistDescriptions(
            enclosureId: enclosureId,
            checklistDescriptions: descriptions,
          );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Save failed',
        message: _failureMessage(error),
      );
      return;
    } finally {
      if (mounted) {
        _mutate(() => _saving = false);
      }
    }
    if (!mounted) {
      return;
    }
    _mutate(_retireChecklistAdds);
    _dismissSheet();
    await ref.read(rfiReferenceControllerProvider.notifier).refresh();
    if (!mounted) {
      return;
    }
    if (result.duplicateChecklistDescriptions.isNotEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.warning,
        title: 'Duplicate descriptions',
        message:
            'These checklist descriptions already exist:\n\n${result.duplicateChecklistDescriptions.map((String item) => '• $item').join('\n')}',
      );
      return;
    }
    if (ref.read(rfiReferenceControllerProvider).error != null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Saved',
        message: 'The list could not be reloaded.',
      );
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.success,
      title: 'Saved',
      message: 'Checklist descriptions were saved.',
    );
  }

  Future<void> _saveChecklistEdit() async {
    final int? id = _editingId;
    final String description = _checklistEdit.text.trim();
    if (id == null || _busy) {
      return;
    }
    if (description.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: 'Missing information',
        message: 'Enter a checklist description.',
      );
      return;
    }
    _mutate(() => _saving = true);
    try {
      await ref
          .read(rfiReferenceRemoteDataSourceProvider)
          .updateChecklistDescription(id: id, description: description);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Update failed',
        message: _failureMessage(error),
      );
      return;
    } finally {
      if (mounted) {
        _mutate(() => _saving = false);
      }
    }
    if (!mounted) {
      return;
    }
    _dismissSheet();
    await _afterWrite(
      successTitle: 'Updated',
      successMessage: 'The checklist description was updated.',
    );
  }

  Future<void> _deleteChecklist(RfiChecklistDescription row) async {
    final int? id = row.id;
    if (id == null || _busy || !row.canBeDeleted) {
      return;
    }
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Delete checklist description',
      message: 'Delete this checklist description?',
      primaryLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _deletingId = id);
    try {
      await ref
          .read(rfiReferenceRemoteDataSourceProvider)
          .deleteChecklistDescription(id);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Delete failed',
        message: _failureMessage(error),
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _deletingId = null);
      }
    }
    if (!mounted) {
      return;
    }
    if (_editingId == id) {
      setState(_closeEditor);
    }
    await _afterWrite(
      successTitle: 'Deleted',
      successMessage: 'The checklist description was deleted.',
    );
  }

  Future<void> _submitDescription() async {
    final String description = _rfiDescription.text.trim();
    final String? category = _category;
    if (description.isEmpty ||
        category == null ||
        category.isEmpty ||
        _enclosureIds.isEmpty) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.info,
        title: 'Missing information',
        message:
            'Enter an RFI description, RFI category, and at least one enclosure.',
      );
      return;
    }
    final bool editing = _editor == _Editor.edit;
    final int? id = _editingId;
    if (_busy || (editing && id == null)) {
      return;
    }
    final String activity = rfiReferenceActivityPayload(
      category,
      _activity.text,
    );
    final String enclosures = rfiReferenceJoinIds(_enclosureIds);
    _mutate(() => _saving = true);
    final RfiReferenceRemoteDataSource dataSource = ref.read(
      rfiReferenceRemoteDataSourceProvider,
    );
    try {
      if (editing) {
        await dataSource.updateDescription(
          id: id!,
          rfiCategory: category,
          activity: activity,
          rfiDescription: description,
          enclosures: enclosures,
        );
      } else {
        await dataSource.submitDescription(
          rfiCategory: category,
          activity: activity,
          rfiDescription: description,
          enclosures: enclosures,
        );
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: editing ? 'Update failed' : 'Save failed',
        message: _failureMessage(error),
      );
      return;
    } finally {
      if (mounted) {
        _mutate(() => _saving = false);
      }
    }
    if (!mounted) {
      return;
    }
    _dismissSheet();
    await _afterWrite(
      successTitle: editing ? 'Updated' : 'Added',
      successMessage: editing
          ? 'The RFI description was updated.'
          : 'The RFI description was added.',
    );
  }

  Future<void> _deleteDescription(RfiReferenceDescription row) async {
    final int? id = row.id;
    if (id == null || _busy || !row.canDelete) {
      return;
    }
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Delete RFI description',
      message: 'Delete this RFI description?',
      primaryLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _deletingId = id);
    RfiDescriptionDeleteResult result;
    try {
      result = await ref
          .read(rfiReferenceRemoteDataSourceProvider)
          .deleteDescription(id);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Delete failed',
        message: _failureMessage(error),
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _deletingId = null);
      }
    }
    if (!mounted) {
      return;
    }
    if (!result.success) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: 'Delete failed',
        message: result.message.isEmpty
            ? 'The RFI description could not be deleted.'
            : result.message,
      );
      return;
    }
    if (_editingId == id) {
      setState(_closeEditor);
    }
    await ref.read(rfiReferenceControllerProvider.notifier).refresh();
    if (!mounted) {
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.success,
      title: 'Deleted',
      message: result.message,
    );
  }

  Future<void> _afterWrite({
    required String successTitle,
    required String successMessage,
  }) async {
    await ref.read(rfiReferenceControllerProvider.notifier).refresh();
    if (!mounted) {
      return;
    }
    if (ref.read(rfiReferenceControllerProvider).error != null) {
      await AppDialog.show(
        context,
        variant: AppDialogVariant.error,
        title: successTitle,
        message: 'The list could not be reloaded.',
      );
      return;
    }
    await AppDialog.show(
      context,
      variant: AppDialogVariant.success,
      title: successTitle,
      message: successMessage,
    );
  }

  Future<void> _openAddEnclosure() {
    setState(() {
      _editor = _Editor.add;
      _editingId = null;
      _category = null;
      _action = null;
      _name.clear();
    });
    return _openFormSheet(title: 'Add enclosure', buildBody: _enclosureForm);
  }

  Future<void> _openEditEnclosure(RfiEnclosure row) {
    setState(() {
      _editor = _Editor.edit;
      _editingId = row.id;
      _category = rfiReferenceCategoryWire(row.rfiCategory);
      _action = rfiReferenceActionWire(row.action);
      _name.text = row.encloserName;
    });
    return _openFormSheet(title: 'Edit enclosure', buildBody: _enclosureForm);
  }

  Future<void> _openAddChecklist() {
    setState(() {
      _editor = _Editor.add;
      _editingId = null;
      _checklistEdit.clear();
      _retireChecklistAdds();
    });
    return _openFormSheet(title: 'Add checklist', buildBody: _checklistAddForm);
  }

  Future<void> _openEditChecklist(RfiChecklistDescription row) {
    setState(() {
      _editor = _Editor.edit;
      _editingId = row.id;
      _checklistEdit.text = row.checklistDescription;
    });
    return _openFormSheet(
      title: 'Edit checklist',
      buildBody: _checklistEditForm,
    );
  }

  Future<void> _openAddDescription() {
    setState(() {
      _editor = _Editor.add;
      _editingId = null;
      _category = null;
      _activity.clear();
      _rfiDescription.clear();
      _enclosureIds = <String>[];
      _nameOptions = <RfiEnclosureNameOption>[];
    });
    return _openFormSheet(
      title: 'Add description',
      buildBody: _descriptionForm,
    );
  }

  void _openEditDescription(RfiReferenceDescription row) {
    final String? category = rfiReferenceCategoryWire(row.rfiCategory);
    setState(() {
      _editor = _Editor.edit;
      _editingId = row.id;
      _category = category;
      _activity.text = category == RfiReferenceCategory.work
          ? row.activity
          : '';
      _rfiDescription.text = row.rfiDescription;
      _enclosureIds = List<String>.from(row.enclosureIdList);
      _nameOptions = <RfiEnclosureNameOption>[];
    });
    if (category != null && category.isNotEmpty) {
      _loadEnclosureNames(category);
    }
    _openFormSheet(title: 'Edit description', buildBody: _descriptionForm);
  }

  @override
  Widget build(BuildContext context) {
    final RfiReferenceState data = ref.watch(rfiReferenceControllerProvider);
    final bool chrome = _showsListChrome(data);
    final bool canAddRow =
        data.form == RfiReferenceForm.enclosureList ||
        data.form == RfiReferenceForm.description;
    final int count = _visibleCount(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RfiContentLoader(loading: data.loading || _busy || _loadingNames),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.showTitle)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Reference',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              _PickerField(
                label: 'Select Form:',
                value: data.form?.label,
                placeholder: '-- Select --',
                enabled: !_busy,
                onTap: _pickForm,
              ),
              if (data.form == RfiReferenceForm.checklist) ...<Widget>[
                const SizedBox(height: 12),
                _PickerField(
                  label: 'Sub Option:',
                  value: data.selectedEnclosure?.encloserName,
                  placeholder: '-- Select Enclosure --',
                  enabled:
                      !_busy && (data.subOptions.isNotEmpty || !data.loading),
                  onTap: () => _pickSubOption(data),
                ),
              ],
              if (canAddRow) ...<Widget>[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _NavyButton(
                    label: 'Add Row',
                    onPressed: _busy
                        ? null
                        : data.form == RfiReferenceForm.enclosureList
                        ? _openAddEnclosure
                        : _openAddDescription,
                  ),
                ),
              ],
              if (data.form == RfiReferenceForm.checklist &&
                  data.selectedEnclosureId != null) ...<Widget>[
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(child: _checklistTitle(data)),
                    _NavyButton(
                      label: 'Add',
                      onPressed: _busy ? null : _openAddChecklist,
                    ),
                  ],
                ),
              ],
              if (chrome) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _countLabel(count),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.of(context).mutedText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear',
                                  onPressed: () {
                                    _search.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: data.loading || _busy ? null : _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _body(data)),
      ],
    );
  }

  Widget _enclosureForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _PickerField(
          label: 'RFI Category',
          value: _category == null
              ? null
              : rfiReferenceCategoryLabel(_category!),
          placeholder: 'Select',
          enabled: !_busy,
          onTap: _pickCategory,
        ),
        const SizedBox(height: 12),
        const _FieldLabel('Enclosure Name'),
        TextField(
          controller: _name,
          enabled: !_busy,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Enter enclosure name'),
        ),
        const SizedBox(height: 12),
        _PickerField(
          label: 'Action Type',
          value: _action,
          placeholder: 'Select',
          enabled: !_busy,
          onTap: _pickAction,
        ),
        const SizedBox(height: 12),
        _FormActions(
          primaryLabel: 'Save',
          onPrimary: _busy ? null : _saveEnclosure,
          onCancel: _busy ? null : _dismissSheet,
        ),
      ],
    );
  }

  Widget _descriptionForm() {
    final bool categoryChosen = _category != null && _category!.isNotEmpty;
    final bool activityEditable = _category == RfiReferenceCategory.work;
    final bool namesReady = categoryChosen && !_loadingNames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _PickerField(
          label: 'RFI Category',
          value: _category == null
              ? null
              : rfiReferenceCategoryLabel(_category!),
          placeholder: 'Select',
          enabled: !_busy,
          onTap: _pickCategory,
        ),
        const SizedBox(height: 12),
        const _FieldLabel('Activity'),
        if (activityEditable)
          TextField(
            controller: _activity,
            enabled: !_busy,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Activity'),
          )
        else
          TextField(controller: _activityLocked, enabled: false),
        const SizedBox(height: 12),
        const _FieldLabel('RFI Description'),
        TextField(
          controller: _rfiDescription,
          enabled: !_busy,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Enter RFI Description'),
        ),
        const SizedBox(height: 12),
        _PickerField(
          label: 'Enclosure/Attachments',
          value: categoryChosen && _enclosureIds.isNotEmpty
              ? _enclosureSummary()
              : null,
          placeholder: categoryChosen
              ? 'Select Enclosures'
              : 'Select RFI Category first',
          enabled: !_busy && namesReady,
          onTap: _pickDescriptionEnclosures,
        ),
        const SizedBox(height: 12),
        _FormActions(
          primaryLabel: _editor == _Editor.edit ? 'Save' : 'Submit',
          onPrimary: _busy ? null : _submitDescription,
          onCancel: _busy ? null : _dismissSheet,
        ),
      ],
    );
  }

  Widget _checklistAddForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < _checklistAdds.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _checklistAdds[index],
                  enabled: !_busy,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter checklist description',
                  ),
                ),
              ),
              if (_checklistAdds.length > 1) ...<Widget>[
                const SizedBox(width: 8),
                _DeleteButton(
                  label: 'Remove',
                  onPressed: _busy
                      ? null
                      : () => _mutate(() {
                          _retired.add(_checklistAdds.removeAt(index));
                        }),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _OutlineButton(
              label: 'Add Another Row',
              icon: Icons.add,
              onPressed: _busy
                  ? null
                  : () => _mutate(
                      () => _checklistAdds.add(TextEditingController()),
                    ),
            ),
            _NavyButton(
              label: 'Save All',
              onPressed: _busy ? null : _saveChecklist,
            ),
            TextButton(
              onPressed: _busy ? null : _dismissSheet,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _checklistEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: _checklistEdit,
          enabled: !_busy,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter checklist description',
          ),
        ),
        const SizedBox(height: 12),
        _FormActions(
          primaryLabel: 'Save',
          onPrimary: _busy ? null : _saveChecklistEdit,
          onCancel: _busy ? null : _dismissSheet,
        ),
      ],
    );
  }

  Widget _checklistTitle(RfiReferenceState data) {
    final String name = data.selectedEnclosure?.encloserName ?? '';
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          'Checklist for: $name',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _body(RfiReferenceState data) {
    final RfiReferenceForm? form = data.form;
    if (form == null) {
      return const SizedBox.shrink();
    }
    if (form == RfiReferenceForm.checklist &&
        data.selectedEnclosureId == null) {
      if (data.error != null) {
        return _MessagePane(
          message: _failureMessage(data.error!),
          onRetry: _refresh,
        );
      }
      if (data.loading) {
        return const SizedBox.shrink();
      }
      if (data.subOptions.isEmpty) {
        return _MessagePane(message: 'No enclosures found.', onRetry: _refresh);
      }
      return const _MessagePane(
        message: 'Select an enclosure to view checklist descriptions.',
      );
    }
    if (data.error != null && _rowsEmpty(data)) {
      return _MessagePane(
        message: _failureMessage(data.error!),
        onRetry: _refresh,
      );
    }
    if (data.loading && _rowsEmpty(data)) {
      return const SizedBox.shrink();
    }
    if (data.error != null) {
      return _MessagePane(
        message: _failureMessage(data.error!),
        onRetry: _refresh,
      );
    }
    return switch (form) {
      RfiReferenceForm.enclosureList => _enclosureTable(data),
      RfiReferenceForm.checklist => _checklistTable(data),
      RfiReferenceForm.description => _descriptionTable(data),
    };
  }

  Widget _enclosureTable(RfiReferenceState data) {
    final List<RfiEnclosure> visible = data.enclosures
        .where((RfiEnclosure row) => _matchesEnclosure(row, _search.text))
        .toList(growable: false);
    if (visible.isEmpty) {
      return _MessagePane(
        message: data.enclosures.isEmpty
            ? 'No enclosures found.'
            : 'No matching enclosures.',
        onRetry: data.enclosures.isEmpty ? _refresh : null,
      );
    }
    return RfiReferenceTable(
      columns: const <RfiReferenceColumn>[
        RfiReferenceColumn('Sr No', 72),
        RfiReferenceColumn('RFI Category', 124),
        RfiReferenceColumn('Enclosure Name', 180),
        RfiReferenceColumn('Action Type', 120),
        RfiReferenceColumn('Action', 188),
      ],
      rows: <List<String>>[
        for (int index = 0; index < visible.length; index++)
          <String>[
            '${index + 1}',
            visible[index].categoryLabel,
            visible[index].encloserName,
            visible[index].actionLabel,
          ],
      ],
      actionBuilder: (BuildContext context, int index) {
        final RfiEnclosure row = visible[index];
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            if (row.id != null)
              _EditButton(
                onPressed: _busy ? null : () => _openEditEnclosure(row),
              ),
            if (row.id != null && !row.usedInRfiDescription)
              _DeleteButton(
                label: 'Delete',
                busy: _deletingId == row.id,
                onPressed: _busy ? null : () => _deleteEnclosure(row),
              ),
          ],
        );
      },
    );
  }

  Widget _checklistTable(RfiReferenceState data) {
    final List<RfiChecklistDescription> visible = data.checklist
        .where(
          (RfiChecklistDescription row) =>
              _contains(_search.text, <String>[row.checklistDescription]),
        )
        .toList(growable: false);
    if (visible.isEmpty) {
      return _MessagePane(
        message: data.checklist.isEmpty
            ? 'No checklist descriptions found.'
            : 'No matching checklist descriptions.',
        onRetry: data.checklist.isEmpty ? _refresh : null,
      );
    }
    return RfiReferenceTable(
      columns: const <RfiReferenceColumn>[
        RfiReferenceColumn('S. No', 72),
        RfiReferenceColumn('Reference Description', 260),
        RfiReferenceColumn('Actions', 188),
      ],
      rows: <List<String>>[
        for (int index = 0; index < visible.length; index++)
          <String>['${index + 1}', visible[index].checklistDescription],
      ],
      actionBuilder: (BuildContext context, int index) {
        final RfiChecklistDescription row = visible[index];
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            if (row.id != null)
              _EditButton(
                onPressed: _busy ? null : () => _openEditChecklist(row),
              ),
            if (row.id != null && row.canBeDeleted)
              _DeleteButton(
                label: 'Delete',
                busy: _deletingId == row.id,
                onPressed: _busy ? null : () => _deleteChecklist(row),
              ),
          ],
        );
      },
    );
  }

  Widget _descriptionTable(RfiReferenceState data) {
    final List<RfiReferenceDescription> visible = data.descriptions
        .where(
          (RfiReferenceDescription row) =>
              _matchesDescription(row, _search.text),
        )
        .toList(growable: false);
    if (visible.isEmpty) {
      return _MessagePane(
        message: data.descriptions.isEmpty
            ? 'No RFI descriptions found.'
            : 'No matching RFI descriptions.',
        onRetry: data.descriptions.isEmpty ? _refresh : null,
      );
    }
    return RfiReferenceTable(
      columns: const <RfiReferenceColumn>[
        RfiReferenceColumn('Sr No', 72),
        RfiReferenceColumn('RFI Category', 124),
        RfiReferenceColumn('Activity', 140),
        RfiReferenceColumn('RFI Description', 180),
        RfiReferenceColumn('Enclosure/Attachments', 200),
        RfiReferenceColumn('Action', 188),
      ],
      rows: <List<String>>[
        for (int index = 0; index < visible.length; index++)
          <String>[
            '${index + 1}',
            visible[index].categoryLabel,
            visible[index].activity,
            visible[index].rfiDescription,
            visible[index].enclosures,
          ],
      ],
      actionBuilder: (BuildContext context, int index) {
        final RfiReferenceDescription row = visible[index];
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            if (row.id != null)
              _EditButton(
                onPressed: _busy ? null : () => _openEditDescription(row),
              ),
            if (row.id != null && row.canDelete)
              _DeleteButton(
                label: 'Delete',
                busy: _deletingId == row.id,
                onPressed: _busy ? null : () => _deleteDescription(row),
              ),
          ],
        );
      },
    );
  }

  int _visibleCount(RfiReferenceState data) {
    return switch (data.form) {
      RfiReferenceForm.enclosureList =>
        data.enclosures
            .where((RfiEnclosure row) => _matchesEnclosure(row, _search.text))
            .length,
      RfiReferenceForm.checklist =>
        data.checklist
            .where(
              (RfiChecklistDescription row) =>
                  _contains(_search.text, <String>[row.checklistDescription]),
            )
            .length,
      RfiReferenceForm.description =>
        data.descriptions
            .where(
              (RfiReferenceDescription row) =>
                  _matchesDescription(row, _search.text),
            )
            .length,
      null => 0,
    };
  }

  bool _rowsEmpty(RfiReferenceState data) {
    return switch (data.form) {
      RfiReferenceForm.enclosureList => data.enclosures.isEmpty,
      RfiReferenceForm.checklist => data.checklist.isEmpty,
      RfiReferenceForm.description => data.descriptions.isEmpty,
      null => true,
    };
  }

  String _enclosureSummary() {
    final Map<String, String> names = <String, String>{
      for (final RfiEnclosureNameOption item in _nameOptions)
        item.id: item.label,
    };
    return _enclosureIds
        .map((String id) {
          final String? name = names[id];
          if (name == null || name.isEmpty) {
            return id;
          }
          return name;
        })
        .join(', ');
  }

  List<({String id, String label})> _categoryOptions() {
    final List<({String id, String label})> options =
        <({String id, String label})>[
          for (final String value in RfiReferenceCategory.values)
            (id: value, label: rfiReferenceCategoryLabel(value)),
        ];
    final String? current = _category;
    if (current != null && !RfiReferenceCategory.values.contains(current)) {
      options.add((id: current, label: rfiReferenceCategoryLabel(current)));
    }
    return options;
  }

  List<({String id, String label})> _actionOptions() {
    final List<({String id, String label})> options =
        <({String id, String label})>[
          for (final String value in rfiReferenceActions)
            (id: value, label: value),
        ];
    final String? current = _action;
    if (current != null && !rfiReferenceActions.contains(current)) {
      options.add((id: current, label: current));
    }
    return options;
  }
}

bool _showsListChrome(RfiReferenceState data) {
  if (data.error != null) {
    return false;
  }
  return switch (data.form) {
    RfiReferenceForm.enclosureList || RfiReferenceForm.description => true,
    RfiReferenceForm.checklist => data.selectedEnclosureId != null,
    null => false,
  };
}

bool _matchesEnclosure(RfiEnclosure row, String query) {
  return _contains(query, <String>[
    row.categoryLabel,
    row.rfiCategory,
    row.encloserName,
    row.actionLabel,
    row.action,
  ]);
}

bool _matchesDescription(RfiReferenceDescription row, String query) {
  return _contains(query, <String>[
    row.categoryLabel,
    row.rfiCategory,
    row.activity,
    row.rfiDescription,
    row.enclosures,
    row.enclosureIds,
  ]);
}

bool _contains(String query, List<String> parts) {
  final String needle = query.trim().toLowerCase();
  if (needle.isEmpty) {
    return true;
  }
  return parts.any((String part) => part.toLowerCase().contains(needle));
}

String _countLabel(int count) {
  if (count == 1) {
    return '1 record total';
  }
  return '$count records total';
}

String _failureMessage(Object error) {
  if (error is DioException) {
    return userFriendlyErrorMessage(error);
  }
  return error.toString();
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String placeholder;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool chosen = value != null && value!.isNotEmpty;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _FieldLabel(label),
          Material(
            color: dark ? const Color(0xFF122844) : AppTheme.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: enabled ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        chosen ? value! : placeholder,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: chosen ? null : palette.mutedText,
                          fontWeight: chosen
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormActions extends StatelessWidget {
  const _FormActions({
    required this.primaryLabel,
    required this.onPrimary,
    required this.onCancel,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _NavyButton(label: primaryLabel, onPressed: onPrimary),
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
      ],
    );
  }
}

class _NavyButton extends StatelessWidget {
  const _NavyButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color color = dark ? AppTheme.brandSecondary : AppTheme.brandPrimary;
    return FilledButton(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 36)),
        padding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return color.withValues(alpha: 0.38);
          }
          return color;
        }),
        foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 36)),
      padding: const WidgetStatePropertyAll<EdgeInsets>(
        EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      textStyle: const WidgetStatePropertyAll<TextStyle>(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
    if (icon == null) {
      return OutlinedButton(
        style: style,
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return OutlinedButton.icon(
      style: style,
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color color = dark
        ? const Color(0xFFF0C36A)
        : const Color(0xFF8A5A00);
    return OutlinedButton(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 32)),
        padding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 10),
        ),
        foregroundColor: WidgetStatePropertyAll<Color>(color),
        side: WidgetStatePropertyAll<BorderSide>(BorderSide(color: color)),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      onPressed: onPressed,
      child: const Text('Edit'),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 32)),
        padding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 10),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return AppTheme.railwayRed.withValues(alpha: 0.38);
          }
          return AppTheme.railwayRed;
        }),
        foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      onPressed: onPressed,
      child: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}

class _MessagePane extends StatelessWidget {
  const _MessagePane({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(
            context,
          ).copyWith(overscroll: false, physics: const ClampingScrollPhysics()),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: math.max(height, 160)),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(message, textAlign: TextAlign.center),
                      if (onRetry != null) ...<Widget>[
                        const SizedBox(height: 12),
                        _NavyButton(label: 'Retry', onPressed: onRetry),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<String?> _pick(
  BuildContext context, {
  required String title,
  required String emptyMessage,
  required List<({String id, String label})> options,
  required String? selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.7;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: options.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(emptyMessage),
                )
              : ListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        title,
                        style: Theme.of(sheetContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    for (final ({String id, String label}) option in options)
                      ListTile(
                        title: Text(option.label),
                        trailing: option.id == selectedId
                            ? const Icon(Icons.check_rounded)
                            : null,
                        onTap: () => Navigator.pop(sheetContext, option.id),
                      ),
                  ],
                ),
        ),
      );
    },
  );
}
