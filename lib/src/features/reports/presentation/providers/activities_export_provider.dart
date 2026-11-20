import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/activities_export_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/activities_export_option.dart';

final activitiesExportControllerProvider =
    StateNotifierProvider.autoDispose<
      ActivitiesExportController,
      ActivitiesExportState
    >((Ref ref) {
      final ActivitiesExportController controller = ActivitiesExportController(
        ref.watch(activitiesExportRemoteDataSourceProvider),
      );
      controller.load();
      return controller;
    });

class ActivitiesExportState {
  const ActivitiesExportState({
    this.projects = const <ActivitiesExportProject>[],
    this.contracts = const <ActivitiesExportContract>[],
    this.projectId = '',
    this.contractId = '',
    this.loadingFilters = false,
    this.generating = false,
    this.error,
  });

  final List<ActivitiesExportProject> projects;
  final List<ActivitiesExportContract> contracts;
  final String projectId;
  final String contractId;
  final bool loadingFilters;
  final bool generating;
  final Object? error;

  ActivitiesExportProject? get selectedProject {
    for (final ActivitiesExportProject item in projects) {
      if (item.projectId == projectId) {
        return item;
      }
    }
    return null;
  }

  ActivitiesExportContract? get selectedContract {
    for (final ActivitiesExportContract item in contracts) {
      if (item.contractId == contractId) {
        return item;
      }
    }
    return null;
  }

  ActivitiesExportState copyWith({
    List<ActivitiesExportProject>? projects,
    List<ActivitiesExportContract>? contracts,
    String? projectId,
    String? contractId,
    bool? loadingFilters,
    bool? generating,
    Object? error = _sentinel,
    bool clearError = false,
  }) {
    return ActivitiesExportState(
      projects: projects ?? this.projects,
      contracts: contracts ?? this.contracts,
      projectId: projectId ?? this.projectId,
      contractId: contractId ?? this.contractId,
      loadingFilters: loadingFilters ?? this.loadingFilters,
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

class ActivitiesExportController extends StateNotifier<ActivitiesExportState> {
  ActivitiesExportController(this._source)
    : super(const ActivitiesExportState());

  final ActivitiesExportRemoteDataSource _source;

  Future<void> load() async {
    state = state.copyWith(loadingFilters: true, clearError: true);
    try {
      final List<ActivitiesExportProject> projects = await _source
          .fetchProjects();
      final List<ActivitiesExportContract> contracts = await _source
          .fetchContracts();
      state = state.copyWith(
        projects: projects,
        contracts: contracts,
        loadingFilters: false,
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(loadingFilters: false, error: error);
    }
  }

  Future<void> selectProject(String? projectId) async {
    final String next = projectId?.trim() ?? '';
    state = state.copyWith(
      projectId: next,
      loadingFilters: true,
      clearError: true,
    );
    try {
      final List<ActivitiesExportContract> contracts = await _source
          .fetchContracts(projectId: next.isEmpty ? null : next);
      String contractId = state.contractId;
      if (contractId.isNotEmpty &&
          !contracts.any(
            (ActivitiesExportContract item) => item.contractId == contractId,
          )) {
        contractId = '';
      }
      state = state.copyWith(
        contracts: contracts,
        contractId: contractId,
        loadingFilters: false,
      );
    } on Object catch (error) {
      state = state.copyWith(loadingFilters: false, error: error);
    }
  }

  Future<void> selectContract(String? contractId) async {
    final String next = contractId?.trim() ?? '';
    state = state.copyWith(
      contractId: next,
      loadingFilters: true,
      clearError: true,
    );
    try {
      final List<ActivitiesExportProject> projects = await _source
          .fetchProjects(contractId: next.isEmpty ? null : next);
      String projectId = state.projectId;
      if (projectId.isNotEmpty &&
          !projects.any(
            (ActivitiesExportProject item) => item.projectId == projectId,
          )) {
        projectId = '';
      }
      // If a contract implies a project, keep project aligned when empty.
      if (projectId.isEmpty && next.isNotEmpty) {
        for (final ActivitiesExportContract item in state.contracts) {
          if (item.contractId == next && item.projectId.isNotEmpty) {
            projectId = item.projectId;
            break;
          }
        }
      }
      state = state.copyWith(
        projects: projects,
        projectId: projectId,
        loadingFilters: false,
      );
    } on Object catch (error) {
      state = state.copyWith(loadingFilters: false, error: error);
    }
  }

  Future<void> reset() async {
    state = state.copyWith(projectId: '', contractId: '');
    await load();
  }

  Future<({Uint8List bytes, String fileName})> generate() async {
    state = state.copyWith(generating: true, clearError: true);
    try {
      final ({Uint8List bytes, String fileName}) file = await _source.generate(
        projectId: state.projectId,
        contractId: state.contractId,
      );
      state = state.copyWith(generating: false);
      return file;
    } on Object catch (error) {
      state = state.copyWith(generating: false, error: error);
      rethrow;
    }
  }
}
