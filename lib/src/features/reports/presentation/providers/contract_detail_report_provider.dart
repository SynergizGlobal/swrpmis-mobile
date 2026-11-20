import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/contract_detail_report_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

final contractDetailReportControllerProvider =
    StateNotifierProvider.autoDispose<
      ContractDetailReportController,
      ContractDetailReportState
    >((Ref ref) {
      final ContractDetailReportController controller =
          ContractDetailReportController(
            ref.watch(contractDetailReportRemoteDataSourceProvider),
          );
      controller.load();
      return controller;
    });

class ContractDetailReportState {
  const ContractDetailReportState({
    this.projects = const <ContractDetailOption>[],
    this.contracts = const <ContractDetailOption>[],
    this.contractors = const <ContractDetailOption>[],
    this.hods = const <ContractDetailOption>[],
    this.statuses = const <ContractDetailOption>[],
    this.projectId = '',
    this.contractId = '',
    this.contractorId = '',
    this.hodId = '',
    this.statusId = '',
    this.loading = false,
    this.generating = false,
    this.error,
  });

  final List<ContractDetailOption> projects;
  final List<ContractDetailOption> contracts;
  final List<ContractDetailOption> contractors;
  final List<ContractDetailOption> hods;
  final List<ContractDetailOption> statuses;
  final String projectId;
  final String contractId;
  final String contractorId;
  final String hodId;
  final String statusId;
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
  ContractDetailOption? get selectedContract => _find(contracts, contractId);
  ContractDetailOption? get selectedContractor =>
      _find(contractors, contractorId);
  ContractDetailOption? get selectedHod => _find(hods, hodId);
  ContractDetailOption? get selectedStatus => _find(statuses, statusId);

  ContractDetailReportState copyWith({
    List<ContractDetailOption>? projects,
    List<ContractDetailOption>? contracts,
    List<ContractDetailOption>? contractors,
    List<ContractDetailOption>? hods,
    List<ContractDetailOption>? statuses,
    String? projectId,
    String? contractId,
    String? contractorId,
    String? hodId,
    String? statusId,
    bool? loading,
    bool? generating,
    Object? error = _sentinel,
    bool clearError = false,
  }) {
    return ContractDetailReportState(
      projects: projects ?? this.projects,
      contracts: contracts ?? this.contracts,
      contractors: contractors ?? this.contractors,
      hods: hods ?? this.hods,
      statuses: statuses ?? this.statuses,
      projectId: projectId ?? this.projectId,
      contractId: contractId ?? this.contractId,
      contractorId: contractorId ?? this.contractorId,
      hodId: hodId ?? this.hodId,
      statusId: statusId ?? this.statusId,
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

class ContractDetailReportController
    extends StateNotifier<ContractDetailReportState> {
  ContractDetailReportController(this._source)
    : super(const ContractDetailReportState());

  final ContractDetailReportRemoteDataSource _source;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      // Projects must surface real failures (empty list was hiding a bad path).
      final List<ContractDetailOption> projects = await _source.fetchProjects();
      final List<ContractDetailOption> contracts = await _source
          .fetchContracts();
      final List<ContractDetailOption> contractors = await _soft(
        _source.fetchContractors,
      );
      final List<ContractDetailOption> hods = await _soft(_source.fetchHods);
      final List<ContractDetailOption> statuses = await _soft(
        _source.fetchStatuses,
      );
      state = state.copyWith(
        projects: projects,
        contracts: contracts,
        contractors: contractors,
        hods: hods,
        statuses: statuses,
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

  void setContract(String? id) {
    state = state.copyWith(contractId: id?.trim() ?? '', clearError: true);
  }

  void setContractor(String? id) {
    state = state.copyWith(contractorId: id?.trim() ?? '', clearError: true);
  }

  void setHod(String? id) {
    state = state.copyWith(hodId: id?.trim() ?? '', clearError: true);
  }

  void setStatus(String? id) {
    state = state.copyWith(statusId: id?.trim() ?? '', clearError: true);
  }

  Future<void> reset() async {
    state = state.copyWith(
      projectId: '',
      contractId: '',
      contractorId: '',
      hodId: '',
      statusId: '',
      clearError: true,
    );
    await load();
  }

  Future<({Uint8List bytes, String fileName})> generate() async {
    if (state.contractId.trim().isEmpty) {
      throw StateError('Please select a contract.');
    }
    state = state.copyWith(generating: true, clearError: true);
    try {
      final ({Uint8List bytes, String fileName}) file = await _source.generate(
        contractId: state.contractId,
        projectId: state.projectId,
        contractorId: state.contractorId,
        status: state.statusId,
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
