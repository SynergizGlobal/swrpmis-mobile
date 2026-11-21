import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/pending_issues_report_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/pending_issues_report.dart';

final pendingIssuesReportControllerProvider =
    StateNotifierProvider.autoDispose<
      PendingIssuesReportController,
      PendingIssuesReportState
    >((Ref ref) {
      final PendingIssuesReportController controller =
          PendingIssuesReportController(
            ref.watch(pendingIssuesReportRemoteDataSourceProvider),
          );
      controller.load();
      return controller;
    });

class PendingIssuesReportState {
  const PendingIssuesReportState({
    this.hods = const <PendingIssuesHodOption>[],
    this.contracts = const <ContractDetailOption>[],
    this.hodSelectionId = '',
    this.contractId = '',
    this.loading = false,
    this.generating = false,
    this.error,
  });

  final List<PendingIssuesHodOption> hods;
  final List<ContractDetailOption> contracts;
  final String hodSelectionId;
  final String contractId;
  final bool loading;
  final bool generating;
  final Object? error;

  PendingIssuesHodOption? get selectedHod {
    for (final PendingIssuesHodOption item in hods) {
      if (item.selectionId == hodSelectionId) {
        return item;
      }
    }
    return null;
  }

  ContractDetailOption? get selectedContract {
    for (final ContractDetailOption item in contracts) {
      if (item.id == contractId) {
        return item;
      }
    }
    return null;
  }

  bool get canGenerate =>
      (selectedHod?.name.trim().isNotEmpty ?? false) &&
      contractId.trim().isNotEmpty;

  PendingIssuesReportState copyWith({
    List<PendingIssuesHodOption>? hods,
    List<ContractDetailOption>? contracts,
    String? hodSelectionId,
    String? contractId,
    bool? loading,
    bool? generating,
    Object? error = _sentinel,
    bool clearError = false,
  }) {
    return PendingIssuesReportState(
      hods: hods ?? this.hods,
      contracts: contracts ?? this.contracts,
      hodSelectionId: hodSelectionId ?? this.hodSelectionId,
      contractId: contractId ?? this.contractId,
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

class PendingIssuesReportController
    extends StateNotifier<PendingIssuesReportState> {
  PendingIssuesReportController(this._source)
    : super(const PendingIssuesReportState());

  final PendingIssuesReportRemoteDataSource _source;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<PendingIssuesHodOption> hods = await _source.fetchHods();
      final List<ContractDetailOption> contracts = await _source
          .fetchContracts();
      state = state.copyWith(
        hods: hods,
        contracts: contracts,
        loading: false,
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(loading: false, error: error);
    }
  }

  void setHod(String? selectionId) {
    state = state.copyWith(
      hodSelectionId: selectionId?.trim() ?? '',
      clearError: true,
    );
  }

  void setContract(String? id) {
    state = state.copyWith(contractId: id?.trim() ?? '', clearError: true);
  }

  void clearFilters() {
    state = state.copyWith(
      hodSelectionId: '',
      contractId: '',
      clearError: true,
    );
  }

  Future<({Uint8List bytes, String fileName})> generate() async {
    final PendingIssuesHodOption? hod = state.selectedHod;
    final String hodName = hod?.name.trim() ?? '';
    final String contractId = state.contractId.trim();
    if (hodName.isEmpty || contractId.isEmpty) {
      throw StateError('Select both HOD and Contract to generate the report.');
    }
    state = state.copyWith(generating: true, clearError: true);
    try {
      final ({Uint8List bytes, String fileName}) file = await _source.generate(
        hodName: hodName,
        contractId: contractId,
      );
      state = state.copyWith(generating: false);
      return file;
    } on Object catch (error) {
      state = state.copyWith(generating: false, error: error);
      rethrow;
    }
  }
}
