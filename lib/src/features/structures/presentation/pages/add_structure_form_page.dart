import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/structures/data/datasources/structure_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/structures/domain/structure_form.dart';
import 'package:swr_pmis_mobile/src/features/structures/domain/structure_parse.dart';
import 'package:swr_pmis_mobile/src/features/structures/presentation/providers/structure_form_provider.dart';

class AddStructureFormPage extends ConsumerStatefulWidget {
  const AddStructureFormPage({super.key, this.projectId = ''});

  final String projectId;

  static const String routeName = 'add-structure-form';
  static const String routePath = '/module/structures/add';
  static const String editRouteName = 'edit-structure-form';
  static const String editRoutePath = '/module/structures/edit/:projectId';

  static String location({String projectId = ''}) {
    final String id = projectId.trim();
    if (id.isEmpty) {
      return routePath;
    }
    return '/module/structures/edit/${Uri.encodeComponent(id)}';
  }

  @override
  ConsumerState<AddStructureFormPage> createState() =>
      _AddStructureFormPageState();
}

class _AddStructureFormPageState extends ConsumerState<AddStructureFormPage> {
  StructureFormMaster _master = StructureFormMaster.empty;
  StructureProjectChainage _chainage = StructureProjectChainage.empty;
  final List<_TypeGroupDraft> _groups = <_TypeGroupDraft>[_TypeGroupDraft()];

  bool _seeded = false;
  bool _reportedLoadError = false;
  bool _saving = false;
  bool _loadingChainage = false;
  String _projectId = '';
  String _projectName = '';

  String get _routeProjectId => widget.projectId.trim();

  bool get _editing => _routeProjectId.isNotEmpty;

  @override
  void dispose() {
    for (final _TypeGroupDraft group in _groups) {
      group.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<StructureFormMaster> masterAsync = ref.watch(
      structureFormMasterProvider,
    );
    masterAsync.when(
      data: (StructureFormMaster master) {
        if (!_seeded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _seeded) {
              return;
            }
            _bootstrap(master);
          });
        }
      },
      error: (Object error, StackTrace stackTrace) {
        if (!_reportedLoadError) {
          _reportedLoadError = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            _showLoadError(error);
          });
        }
      },
      loading: () {},
    );

    final AsyncValue<StructureFullDetail>? detailAsync = _editing
        ? ref.watch(structureFullDetailProvider(_routeProjectId))
        : null;
    if (_editing && !_seeded && masterAsync.hasValue && detailAsync != null) {
      detailAsync.when(
        data: (StructureFullDetail detail) {
          if (!_seeded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _seeded) {
                return;
              }
              _applyDetail(detail, masterAsync.requireValue);
            });
          }
        },
        error: (Object error, StackTrace stackTrace) {
          if (!_reportedLoadError) {
            _reportedLoadError = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              _showLoadError(error);
            });
          }
        },
        loading: () {},
      );
    }

    final bool loadingMaster = masterAsync.isLoading && !_seeded;
    final bool loadingDetail =
        detailAsync != null && detailAsync.isLoading && !_seeded;
    final bool loadFailed =
        !_seeded &&
        (masterAsync.hasError || (detailAsync?.hasError ?? false));
    final bool busy = _saving || loadingMaster || loadingDetail;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Update Structure' : 'Add Structure'),
      ),
      body: loadingMaster || loadingDetail
          ? const Center(child: CircularProgressIndicator())
          : loadFailed
          ? _ErrorBody(
              onRetry: () {
                _reportedLoadError = false;
                ref.invalidate(structureFormMasterProvider);
                if (_editing) {
                  ref.invalidate(structureFullDetailProvider(_routeProjectId));
                }
              },
            )
          : _buildForm(busy: busy),
    );
  }

  Future<void> _bootstrap(StructureFormMaster master) async {
    if (_editing) {
      _master = master;
      return;
    }
    setState(() {
      _master = master;
      _seeded = true;
      if (_groups.isEmpty) {
        _groups.add(_TypeGroupDraft());
      }
    });
  }

  Future<void> _applyDetail(
    StructureFullDetail detail,
    StructureFormMaster master,
  ) async {
    for (final _TypeGroupDraft group in _groups) {
      group.dispose();
    }
    _groups.clear();
    final List<_TypeGroupDraft> next = <_TypeGroupDraft>[
      for (final StructureTypeGroupDraft group in detail.structureTypes)
        _TypeGroupDraft.fromModel(group),
    ];
    if (next.isEmpty) {
      next.add(_TypeGroupDraft());
    }
    setState(() {
      _master = master;
      _projectId = detail.projectId.trim().isEmpty
          ? _routeProjectId
          : detail.projectId.trim();
      _projectName = detail.projectName;
      _groups
        ..clear()
        ..addAll(next);
      _seeded = true;
    });
    await _loadChainage(_projectId);
  }

  Future<void> _showLoadError(Object error) async {
    await AppDialog.show(
      context,
      variant: AppDialogVariant.error,
      title: 'Load failed',
      message: _errorMessage(error),
    );
  }

  Future<void> _loadChainage(String projectId) async {
    final String id = projectId.trim();
    if (id.isEmpty) {
      setState(() => _chainage = StructureProjectChainage.empty);
      return;
    }
    setState(() => _loadingChainage = true);
    try {
      final StructureProjectChainage chainage = await ref
          .read(structureRemoteDataSourceProvider)
          .fetchProjectChainage(id);
      if (!mounted) {
        return;
      }
      setState(() {
        _chainage = chainage;
        _loadingChainage = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _chainage = StructureProjectChainage.empty;
        _loadingChainage = false;
      });
    }
  }

  Widget _buildForm({required bool busy}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        _projectField(busy: busy),
        if (_chainage.hasBounds || _loadingChainage) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            _loadingChainage
                ? 'Loading project chainage…'
                : 'Project chainage: '
                      '${_formatBound(_chainage.fromChainage)} → '
                      '${_formatBound(_chainage.toChainage)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.of(context).mutedText,
            ),
          ),
        ],
        const SizedBox(height: 16),
        for (int i = 0; i < _groups.length; i++) ...<Widget>[
          _groupCard(index: i, busy: busy),
          const SizedBox(height: 12),
        ],
        Center(
          child: IconButton(
            tooltip: 'Add structure type',
            onPressed: busy
                ? null
                : () {
                    setState(() => _groups.add(_TypeGroupDraft()));
                  },
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.brandPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        const SizedBox(height: 24),
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
                    : Text(_editing ? 'UPDATE' : 'ADD'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: busy ? null : () => context.pop(false),
                child: const Text('CANCEL'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _projectField({required bool busy}) {
    final List<StructureProjectOption> options = _ensureProjectOption(
      _master.projects,
      _projectId,
      _projectName,
    );
    final String? value = _projectId.isEmpty
        ? null
        : options.any(
            (StructureProjectOption option) => option.projectId == _projectId,
          )
        ? _projectId
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey<String>('project|$_projectId|${options.length}'),
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Project *',
          hintText: 'Select Project',
        ),
        items: <DropdownMenuItem<String>>[
          for (final StructureProjectOption option in options)
            DropdownMenuItem<String>(
              value: option.projectId,
              child: Text(
                option.displayLabel,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: busy || _editing
            ? null
            : (String? next) {
                if (next == null) {
                  return;
                }
                StructureProjectOption? picked;
                for (final StructureProjectOption option in options) {
                  if (option.projectId == next) {
                    picked = option;
                    break;
                  }
                }
                setState(() {
                  _projectId = next;
                  _projectName = picked?.projectName ?? '';
                });
                _loadChainage(next);
              },
      ),
    );
  }

  Widget _groupCard({required int index, required bool busy}) {
    final _TypeGroupDraft group = _groups[index];
    final AppPalette palette = AppPalette.of(context);
    final List<String> typeOptions = _ensureTypeOption(
      _master.structureTypes,
      group.type,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey<String>(
                      'type|$index|${group.type}|${typeOptions.length}',
                    ),
                    initialValue: group.type.isEmpty
                        ? null
                        : typeOptions.contains(group.type)
                        ? group.type
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Structure Type :',
                      hintText: 'Select Structure Type',
                    ),
                    items: <DropdownMenuItem<String>>[
                      for (final String type in typeOptions)
                        DropdownMenuItem<String>(
                          value: type,
                          child: Text(type, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: busy
                        ? null
                        : (String? next) {
                            if (next == null) {
                              return;
                            }
                            setState(() => group.type = next);
                          },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove structure type',
                  onPressed: busy
                      ? null
                      : () {
                          setState(() {
                            group.dispose();
                            _groups.removeAt(index);
                            if (_groups.isEmpty) {
                              _groups.add(_TypeGroupDraft());
                            }
                          });
                        },
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF9CA3AF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(40, 40),
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _rowsTable(group: group, busy: busy),
            const SizedBox(height: 8),
            Center(
              child: IconButton(
                tooltip: 'Add row',
                onPressed: busy
                    ? null
                    : () {
                        setState(() => group.rows.add(_RowDraft()));
                      },
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.brandPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(40, 40),
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowsTable({required _TypeGroupDraft group, required bool busy}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _tableHeader(const <String>[
          'Structure',
          'Structure Name',
          'Structure Details',
          'From Chainage',
          'To Chainage',
          'Action',
        ]),
        for (int i = 0; i < group.rows.length; i++)
          _tableRow(
            children: <Widget>[
              TextField(
                controller: group.rows[i].structure,
                enabled: !busy,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Structure',
                ),
              ),
              TextField(
                controller: group.rows[i].structureName,
                enabled: !busy,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Name',
                ),
              ),
              TextField(
                controller: group.rows[i].structureDetails,
                enabled: !busy,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Details',
                ),
              ),
              TextField(
                controller: group.rows[i].fromChainage,
                enabled: !busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'From',
                ),
              ),
              TextField(
                controller: group.rows[i].toChainage,
                enabled: !busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'To',
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Remove row',
                  onPressed: busy
                      ? null
                      : () {
                          setState(() {
                            group.rows[i].dispose();
                            group.rows.removeAt(i);
                            if (group.rows.isEmpty) {
                              group.rows.add(_RowDraft());
                            }
                          });
                        },
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF9CA3AF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(36, 36),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ),
            ],
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
                  fontSize: 11,
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

  String? _validationMessage() {
    if (_projectId.trim().isEmpty) {
      return 'Please select a project.';
    }
    final List<_TypeGroupDraft> filledGroups = _groups
        .where((_TypeGroupDraft group) => group.type.trim().isNotEmpty)
        .toList(growable: false);
    if (filledGroups.isEmpty) {
      return 'Please add at least one structure type.';
    }
    final Set<String> seenTypes = <String>{};
    for (final _TypeGroupDraft group in filledGroups) {
      final String type = group.type.trim();
      if (!seenTypes.add(type)) {
        return 'Duplicate structure type "$type".';
      }
      final bool hasRow = group.rows.any((_RowDraft row) => row.hasAnyValue);
      if (!hasRow) {
        return 'Please add at least one row for "$type".';
      }
    }
    return null;
  }

  String? _chainageWarning() {
    if (!_chainage.hasBounds) {
      return null;
    }
    for (final _TypeGroupDraft group in _groups) {
      if (group.type.trim().isEmpty) {
        continue;
      }
      for (final _RowDraft row in group.rows) {
        if (!row.hasAnyValue) {
          continue;
        }
        final double? from = double.tryParse(row.fromChainage.text.trim());
        final double? to = double.tryParse(row.toChainage.text.trim());
        if (_outsideBounds(from) || _outsideBounds(to)) {
          return 'Some chainage values are outside the project range '
              '(${_formatBound(_chainage.fromChainage)} → '
              '${_formatBound(_chainage.toChainage)}). Submit anyway?';
        }
      }
    }
    return null;
  }

  bool _outsideBounds(double? value) {
    if (value == null) {
      return false;
    }
    final double? min = _chainage.fromChainage;
    final double? max = _chainage.toChainage;
    if (min != null && value < min) {
      return true;
    }
    if (max != null && value > max) {
      return true;
    }
    return false;
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
    final String? warning = _chainageWarning();
    if (warning != null) {
      final bool confirmed = await AppDialog.confirm(
        context,
        title: 'Chainage warning',
        message: warning,
        primaryLabel: 'Submit',
      );
      if (!confirmed || !mounted) {
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final List<Map<String, dynamic>> structureTypes = <Map<String, dynamic>>[
        for (final _TypeGroupDraft group in _groups)
          if (group.type.trim().isNotEmpty)
            group.toPayload(editing: _editing),
      ];
      final Map<String, dynamic> body = <String, dynamic>{
        'project': _projectId.trim(),
        'structureTypes': structureTypes,
      };
      final String result = await ref
          .read(structureRemoteDataSourceProvider)
          .saveOrUpdate(body);
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
        title: _editing ? 'Update failed' : 'Save failed',
        message: _errorMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is StateError) {
      return error.message;
    }
    if (error is DioException) {
      final String? api = structureApiMessage(error.response?.data);
      if (api != null && api.isNotEmpty) {
        return api;
      }
      return userFriendlyErrorMessage(error);
    }
    return error.toString();
  }

  String _formatBound(double? value) {
    if (value == null) {
      return '—';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  List<StructureProjectOption> _ensureProjectOption(
    List<StructureProjectOption> options,
    String projectId,
    String projectName,
  ) {
    final String id = projectId.trim();
    if (id.isEmpty) {
      return options;
    }
    if (options.any(
      (StructureProjectOption option) => option.projectId == id,
    )) {
      return options;
    }
    return <StructureProjectOption>[
      ...options,
      StructureProjectOption(projectId: id, projectName: projectName),
    ];
  }

  List<String> _ensureTypeOption(List<String> options, String type) {
    final String value = type.trim();
    if (value.isEmpty || options.contains(value)) {
      return options;
    }
    return <String>[...options, value];
  }
}

class _TypeGroupDraft {
  _TypeGroupDraft({this.type = '', List<_RowDraft>? rows})
    : rows = rows ?? <_RowDraft>[_RowDraft()];

  factory _TypeGroupDraft.fromModel(StructureTypeGroupDraft model) {
    return _TypeGroupDraft(
      type: model.type,
      rows: <_RowDraft>[
        for (final StructureRowDraft row in model.rows) _RowDraft.fromModel(row),
      ],
    );
  }

  String type;
  final List<_RowDraft> rows;

  Map<String, dynamic> toPayload({required bool editing}) {
    return StructureTypeGroupDraft(
      type: type,
      rows: <StructureRowDraft>[
        for (final _RowDraft row in rows)
          if (row.hasAnyValue) row.toModel(),
      ],
    ).toPayload(editing: editing);
  }

  void dispose() {
    for (final _RowDraft row in rows) {
      row.dispose();
    }
  }
}

class _RowDraft {
  _RowDraft({
    this.structureId = '',
    String structure = '',
    String structureName = '',
    String structureDetails = '',
    String fromChainage = '',
    String toChainage = '',
  }) : structure = TextEditingController(text: structure),
       structureName = TextEditingController(text: structureName),
       structureDetails = TextEditingController(text: structureDetails),
       fromChainage = TextEditingController(text: fromChainage),
       toChainage = TextEditingController(text: toChainage);

  factory _RowDraft.fromModel(StructureRowDraft model) {
    return _RowDraft(
      structureId: model.structureId,
      structure: model.structure,
      structureName: model.structureName,
      structureDetails: model.structureDetails,
      fromChainage: model.fromChainage,
      toChainage: model.toChainage,
    );
  }

  String structureId;
  final TextEditingController structure;
  final TextEditingController structureName;
  final TextEditingController structureDetails;
  final TextEditingController fromChainage;
  final TextEditingController toChainage;

  bool get hasAnyValue =>
      structure.text.trim().isNotEmpty ||
      structureName.text.trim().isNotEmpty ||
      structureDetails.text.trim().isNotEmpty ||
      fromChainage.text.trim().isNotEmpty ||
      toChainage.text.trim().isNotEmpty;

  StructureRowDraft toModel() {
    return StructureRowDraft(
      structureId: structureId,
      structure: structure.text,
      structureName: structureName.text,
      structureDetails: structureDetails.text,
      fromChainage: fromChainage.text,
      toChainage: toChainage.text,
    );
  }

  void dispose() {
    structure.dispose();
    structureName.dispose();
    structureDetails.dispose();
    fromChainage.dispose();
    toChainage.dispose();
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
              'Could not load the structure form.',
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
