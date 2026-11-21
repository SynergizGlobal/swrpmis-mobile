import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/land_acquisition_report_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

final landAcquisitionReportControllerProvider =
    StateNotifierProvider.autoDispose<
      LandAcquisitionReportController,
      LandAcquisitionReportState
    >((Ref ref) {
      final LandAcquisitionReportController controller =
          LandAcquisitionReportController(
            ref.watch(landAcquisitionReportRemoteDataSourceProvider),
          );
      controller.load();
      return controller;
    });

class LandAcquisitionReportState {
  const LandAcquisitionReportState({
    this.projects = const <ContractDetailOption>[],
    this.types = const <ContractDetailOption>[],
    this.subCategories = const <ContractDetailOption>[],
    this.projectId = '',
    this.categoryFk = '',
    this.subCategoryFk = '',
    this.loading = false,
    this.cascading = false,
    this.generating = false,
    this.error,
  });

  final List<ContractDetailOption> projects;
  final List<ContractDetailOption> types;
  final List<ContractDetailOption> subCategories;
  final String projectId;
  final String categoryFk;
  final String subCategoryFk;
  final bool loading;
  final bool cascading;
  final bool generating;
  final Object? error;

  ContractDetailOption? _find(List<ContractDetailOption> items, String id) {
    for (final ContractDetailOption item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  ContractDetailOption? get selectedProject => _find(projects, projectId);
  ContractDetailOption? get selectedType => _find(types, categoryFk);
  ContractDetailOption? get selectedSubCategory =>
      _find(subCategories, subCategoryFk);

  bool get canGenerate =>
      projectId.trim().isNotEmpty &&
      categoryFk.trim().isNotEmpty &&
      subCategoryFk.trim().isNotEmpty;

  List<String> get missingRequiredFilters {
    final List<String> missing = <String>[];
    if (projectId.trim().isEmpty) {
      missing.add('Project');
    }
    if (categoryFk.trim().isEmpty) {
      missing.add('Type Of Land');
    }
    if (subCategoryFk.trim().isEmpty) {
      missing.add('Sub Category');
    }
    return missing;
  }

  LandAcquisitionReportState copyWith({
    List<ContractDetailOption>? projects,
    List<ContractDetailOption>? types,
    List<ContractDetailOption>? subCategories,
    String? projectId,
    String? categoryFk,
    String? subCategoryFk,
    bool? loading,
    bool? cascading,
    bool? generating,
    Object? error = _sentinel,
    bool clearError = false,
  }) {
    return LandAcquisitionReportState(
      projects: projects ?? this.projects,
      types: types ?? this.types,
      subCategories: subCategories ?? this.subCategories,
      projectId: projectId ?? this.projectId,
      categoryFk: categoryFk ?? this.categoryFk,
      subCategoryFk: subCategoryFk ?? this.subCategoryFk,
      loading: loading ?? this.loading,
      cascading: cascading ?? this.cascading,
      generating: generating ?? this.generating,
      error: clearError
          ? null
          : identical(error, _sentinel)
          ? this.error
          : error,
    );
  }
}

const Object _sentinel = Object();

class LandAcquisitionReportController
    extends StateNotifier<LandAcquisitionReportState> {
  LandAcquisitionReportController(this._source)
    : super(const LandAcquisitionReportState());

  final LandAcquisitionReportRemoteDataSource _source;
  int _cascadeRequestId = 0;

  /// Initial load: all three lists without query params.
  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<List<ContractDetailOption>> results =
          await Future.wait(<Future<List<ContractDetailOption>>>[
            _source.fetchProjects(),
            _source.fetchTypes(),
            _source.fetchSubCategories(),
          ]);
      state = state.copyWith(
        projects: results[0],
        types: results[1],
        subCategories: results[2],
        loading: false,
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(loading: false, error: error);
    }
  }

  Future<void> setProject(String? id) async {
    final String next = id?.trim() ?? '';
    state = state.copyWith(
      projectId: next,
      subCategoryFk: '',
      clearError: true,
    );
    await _cascadeAfterProjectOrTypeChange();
  }

  Future<void> setType(String? categoryFk) async {
    final String next = categoryFk?.trim() ?? '';
    state = state.copyWith(
      categoryFk: next,
      subCategoryFk: '',
      clearError: true,
    );
    await _cascadeAfterProjectOrTypeChange();
  }

  void setSubCategory(String? id) {
    state = state.copyWith(
      subCategoryFk: id?.trim() ?? '',
      clearError: true,
    );
  }

  /// Clear Filter: reset selections and reload unfiltered lists.
  Future<void> clearFilters() async {
    _cascadeRequestId++;
    state = const LandAcquisitionReportState();
    await load();
  }

  Future<({Uint8List bytes, String fileName})> generate() async {
    final List<String> missing = state.missingRequiredFilters;
    if (missing.isNotEmpty) {
      throw StateError(
        'Select ${missing.join(', ')} to generate the report.',
      );
    }
    state = state.copyWith(generating: true, clearError: true);
    try {
      final ({Uint8List bytes, String fileName}) file = await _source.generate(
        projectId: state.projectId,
        categoryFk: state.categoryFk,
        subCategoryFk: state.subCategoryFk,
      );
      state = state.copyWith(generating: false);
      return file;
    } on Object catch (error) {
      state = state.copyWith(generating: false, error: error);
      rethrow;
    }
  }

  /// When Project and/or Type Of Land change, refetch dependent lists with
  /// the selected query params and drop invalid child selections.
  Future<void> _cascadeAfterProjectOrTypeChange() async {
    final int requestId = ++_cascadeRequestId;
    final String projectId = state.projectId;
    final String categoryFk = state.categoryFk;
    state = state.copyWith(cascading: true, clearError: true);
    try {
      final List<List<ContractDetailOption>> results =
          await Future.wait(<Future<List<ContractDetailOption>>>[
            _source.fetchProjects(categoryFk: categoryFk),
            _source.fetchTypes(projectId: projectId),
            _source.fetchSubCategories(
              projectId: projectId,
              categoryFk: categoryFk,
            ),
          ]);
      if (requestId != _cascadeRequestId) {
        return;
      }
      final List<ContractDetailOption> projects = results[0];
      final List<ContractDetailOption> types = results[1];
      final List<ContractDetailOption> subCategories = results[2];
      final String keptProject = _keepIfPresent(projects, projectId);
      final String keptType = _keepIfPresent(types, categoryFk);
      final String keptSub = _keepIfPresent(subCategories, state.subCategoryFk);
      state = state.copyWith(
        projects: projects,
        types: types,
        subCategories: subCategories,
        projectId: keptProject,
        categoryFk: keptType,
        subCategoryFk: keptSub,
        cascading: false,
        clearError: true,
      );
    } on Object catch (error) {
      if (requestId != _cascadeRequestId) {
        return;
      }
      state = state.copyWith(cascading: false, error: error);
    }
  }

  String _keepIfPresent(List<ContractDetailOption> items, String id) {
    final String trimmed = id.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    for (final ContractDetailOption item in items) {
      if (item.id == trimmed) {
        return trimmed;
      }
    }
    return '';
  }
}
