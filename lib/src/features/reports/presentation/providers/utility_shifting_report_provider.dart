import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/utility_shifting_report_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/utility_shifting_report.dart';

final utilityShiftingReportControllerProvider =
    StateNotifierProvider.autoDispose<
      UtilityShiftingReportController,
      UtilityShiftingReportState
    >((Ref ref) {
      final UtilityShiftingReportController controller =
          UtilityShiftingReportController(
            ref.watch(utilityShiftingReportRemoteDataSourceProvider),
          );
      controller.load();
      return controller;
    });

class UtilityShiftingReportState {
  const UtilityShiftingReportState({
    this.projects = const <ContractDetailOption>[],
    this.executionAgencies = const <ContractDetailOption>[],
    this.impactedContracts = const <ContractDetailOption>[],
    this.hods = const <ContractDetailOption>[],
    this.projectId = '',
    this.executionAgencyId = '',
    this.contractId = '',
    this.hodId = '',
    this.loading = false,
    this.error,
  });

  final List<ContractDetailOption> projects;
  final List<ContractDetailOption> executionAgencies;
  final List<ContractDetailOption> impactedContracts;
  final List<ContractDetailOption> hods;
  final String projectId;
  final String executionAgencyId;
  final String contractId;
  final String hodId;
  final bool loading;
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
  ContractDetailOption? get selectedExecutionAgency =>
      _find(executionAgencies, executionAgencyId);
  ContractDetailOption? get selectedImpactedContract =>
      _find(impactedContracts, contractId);
  ContractDetailOption? get selectedHod => _find(hods, hodId);

  UtilityShiftingReportState copyWith({
    List<ContractDetailOption>? projects,
    List<ContractDetailOption>? executionAgencies,
    List<ContractDetailOption>? impactedContracts,
    List<ContractDetailOption>? hods,
    String? projectId,
    String? executionAgencyId,
    String? contractId,
    String? hodId,
    bool? loading,
    Object? error = _sentinel,
    bool clearError = false,
    bool clearSelections = false,
  }) {
    return UtilityShiftingReportState(
      projects: projects ?? this.projects,
      executionAgencies: executionAgencies ?? this.executionAgencies,
      impactedContracts: impactedContracts ?? this.impactedContracts,
      hods: hods ?? this.hods,
      projectId: clearSelections ? '' : (projectId ?? this.projectId),
      executionAgencyId: clearSelections
          ? ''
          : (executionAgencyId ?? this.executionAgencyId),
      contractId: clearSelections ? '' : (contractId ?? this.contractId),
      hodId: clearSelections ? '' : (hodId ?? this.hodId),
      loading: loading ?? this.loading,
      error: clearError
          ? null
          : identical(error, _sentinel)
          ? this.error
          : error,
    );
  }
}

const Object _sentinel = Object();

class UtilityShiftingReportController
    extends StateNotifier<UtilityShiftingReportState> {
  UtilityShiftingReportController(this._source)
    : super(const UtilityShiftingReportState());

  final UtilityShiftingReportRemoteDataSource _source;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final UtilityShiftingReportFilters filters = await _source.fetchFilters();
      state = state.copyWith(
        projects: filters.projects,
        executionAgencies: filters.executionAgencies,
        impactedContracts: filters.impactedContracts,
        hods: filters.hods,
        loading: false,
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(loading: false, error: error);
    }
  }

  void setProject(String? id) {
    state = state.copyWith(projectId: id?.trim() ?? '', clearError: true);
  }

  void setExecutionAgency(String? id) {
    state = state.copyWith(
      executionAgencyId: id?.trim() ?? '',
      clearError: true,
    );
  }

  void setImpactedContract(String? id) {
    state = state.copyWith(contractId: id?.trim() ?? '', clearError: true);
  }

  void setHod(String? id) {
    state = state.copyWith(hodId: id?.trim() ?? '', clearError: true);
  }

  /// Clears all four selections; loaded lists stay in place.
  void reset() {
    state = state.copyWith(clearSelections: true, clearError: true);
  }

  /// Stub for future download wiring — throws until backend provides the API.
  ///
  /// TODO(utility-report): Call [_source.generateReport] from the page once
  /// the download endpoint exists; keep filter ids as documented there.
  Future<({Uint8List bytes, String fileName})> generateReport() {
    return _source.generateReport(
      projectId: state.projectId,
      executionAgency: state.executionAgencyId,
      contractId: state.contractId,
      hodUserId: state.hodId,
    );
  }
}
