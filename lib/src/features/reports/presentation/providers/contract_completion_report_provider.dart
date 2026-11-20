import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/contract_completion_report_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

final contractCompletionReportControllerProvider =
    StateNotifierProvider.autoDispose<
      ContractCompletionReportController,
      ContractCompletionReportState
    >((Ref ref) {
      final ContractCompletionReportController controller =
          ContractCompletionReportController(
            ref.watch(contractCompletionReportRemoteDataSourceProvider),
          );
      controller.load();
      return controller;
    });

class ContractCompletionReportState {
  const ContractCompletionReportState({
    this.projects = const <ContractDetailOption>[],
    this.contractors = const <ContractDetailOption>[],
    this.hods = const <ContractDetailOption>[],
    this.contractStatuses = const <ContractDetailOption>[],
    this.projectId = '',
    this.contractorId = '',
    this.hodId = '',
    this.contractStatusId = '',
    this.loading = false,
    this.generating = false,
    this.error,
  });

  final List<ContractDetailOption> projects;
  final List<ContractDetailOption> contractors;
  final List<ContractDetailOption> hods;
  final List<ContractDetailOption> contractStatuses;
  final String projectId;
  final String contractorId;
  final String hodId;
  final String contractStatusId;
  final bool loading;
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
  ContractDetailOption? get selectedContractor =>
      _find(contractors, contractorId);
  ContractDetailOption? get selectedHod => _find(hods, hodId);
  ContractDetailOption? get selectedContractStatus =>
      _find(contractStatuses, contractStatusId);

  /// Labels of filters that must be set before generate.
  List<String> get missingRequiredFilters {
    final List<String> missing = <String>[];
    if (projectId.trim().isEmpty) {
      missing.add('Project');
    }
    if (contractorId.trim().isEmpty) {
      missing.add('Contractor');
    }
    if (contractStatusId.trim().isEmpty) {
      missing.add('Status of Work');
    }
    if (hodId.trim().isEmpty) {
      missing.add('HOD');
    }
    return missing;
  }

  ContractCompletionReportState copyWith({
    List<ContractDetailOption>? projects,
    List<ContractDetailOption>? contractors,
    List<ContractDetailOption>? hods,
    List<ContractDetailOption>? contractStatuses,
    String? projectId,
    String? contractorId,
    String? hodId,
    String? contractStatusId,
    bool? loading,
    bool? generating,
    Object? error = _sentinel,
    bool clearError = false,
  }) {
    return ContractCompletionReportState(
      projects: projects ?? this.projects,
      contractors: contractors ?? this.contractors,
      hods: hods ?? this.hods,
      contractStatuses: contractStatuses ?? this.contractStatuses,
      projectId: projectId ?? this.projectId,
      contractorId: contractorId ?? this.contractorId,
      hodId: hodId ?? this.hodId,
      contractStatusId: contractStatusId ?? this.contractStatusId,
      loading: loading ?? this.loading,
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

class ContractCompletionReportController
    extends StateNotifier<ContractCompletionReportState> {
  ContractCompletionReportController(this._source)
    : super(const ContractCompletionReportState());

  final ContractCompletionReportRemoteDataSource _source;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<ContractDetailOption> projects = await _source.fetchProjects();
      final List<ContractDetailOption> contractors = await _soft(
        _source.fetchContractors,
      );
      final List<ContractDetailOption> hods = await _soft(_source.fetchHods);
      final List<ContractDetailOption> contractStatuses = await _soft(
        _source.fetchContractStatuses,
      );
      state = state.copyWith(
        projects: projects,
        contractors: contractors,
        hods: hods,
        contractStatuses: contractStatuses,
        loading: false,
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(loading: false, error: error);
    }
  }

  Future<List<ContractDetailOption>> _soft(
    Future<List<ContractDetailOption>> Function() load,
  ) async {
    try {
      return await load();
    } on Object {
      return const <ContractDetailOption>[];
    }
  }

  void setProject(String? id) {
    state = state.copyWith(projectId: id?.trim() ?? '', clearError: true);
  }

  void setContractor(String? id) {
    state = state.copyWith(contractorId: id?.trim() ?? '', clearError: true);
  }

  void setHod(String? id) {
    state = state.copyWith(hodId: id?.trim() ?? '', clearError: true);
  }

  void setContractStatus(String? id) {
    state = state.copyWith(
      contractStatusId: id?.trim() ?? '',
      clearError: true,
    );
  }

  Future<void> reset() async {
    state = state.copyWith(
      projectId: '',
      contractorId: '',
      hodId: '',
      contractStatusId: '',
      clearError: true,
    );
    await load();
  }

  Future<({Uint8List bytes, String fileName})> generate() async {
    final List<String> missing = state.missingRequiredFilters;
    if (missing.isNotEmpty) {
      throw StateError(
        'Please select ${missing.join(', ')} before generating the report.',
      );
    }
    state = state.copyWith(generating: true, clearError: true);
    try {
      final ({Uint8List bytes, String fileName}) file = await _source.generate(
        projectId: state.projectId,
        contractorId: state.contractorId,
        contractStatus: state.contractStatusId,
        hodDesignation: state.hodId,
      );
      state = state.copyWith(generating: false);
      return file;
    } on Object catch (error) {
      state = state.copyWith(generating: false, error: error);
      rethrow;
    }
  }
}
