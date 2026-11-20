import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/bg_insurance_report_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

final bgInsuranceReportControllerProvider =
    StateNotifierProvider.autoDispose<
      BgInsuranceReportController,
      BgInsuranceReportState
    >((Ref ref) {
      final BgInsuranceReportController controller =
          BgInsuranceReportController(
            ref.watch(bgInsuranceReportRemoteDataSourceProvider),
          );
      controller.load();
      return controller;
    });

class BgInsuranceReportState {
  const BgInsuranceReportState({
    this.projects = const <ContractDetailOption>[],
    this.contractors = const <ContractDetailOption>[],
    this.contractStatuses = const <ContractDetailOption>[],
    this.projectId = '',
    this.contractorId = '',
    this.contractStatusId = '',
    this.fromDate,
    this.toDate,
    this.loading = false,
    this.generating = false,
    this.error,
  });

  final List<ContractDetailOption> projects;
  final List<ContractDetailOption> contractors;
  final List<ContractDetailOption> contractStatuses;
  final String projectId;
  final String contractorId;
  final String contractStatusId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool loading;
  final bool generating;
  final Object? error;

  static final DateFormat apiDateFormat = DateFormat('dd-MM-yyyy');
  static final DateFormat displayDateFormat = DateFormat('dd/MM/yyyy');

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
  ContractDetailOption? get selectedContractStatus =>
      _find(contractStatuses, contractStatusId);

  String? get fromDateLabel =>
      fromDate == null ? null : displayDateFormat.format(fromDate!);
  String? get toDateLabel =>
      toDate == null ? null : displayDateFormat.format(toDate!);

  BgInsuranceReportState copyWith({
    List<ContractDetailOption>? projects,
    List<ContractDetailOption>? contractors,
    List<ContractDetailOption>? contractStatuses,
    String? projectId,
    String? contractorId,
    String? contractStatusId,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool? loading,
    bool? generating,
    Object? error = _sentinel,
    bool clearError = false,
  }) {
    return BgInsuranceReportState(
      projects: projects ?? this.projects,
      contractors: contractors ?? this.contractors,
      contractStatuses: contractStatuses ?? this.contractStatuses,
      projectId: projectId ?? this.projectId,
      contractorId: contractorId ?? this.contractorId,
      contractStatusId: contractStatusId ?? this.contractStatusId,
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
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

class BgInsuranceReportController
    extends StateNotifier<BgInsuranceReportState> {
  BgInsuranceReportController(this._source)
    : super(const BgInsuranceReportState());

  final BgInsuranceReportRemoteDataSource _source;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<ContractDetailOption> projects = await _source.fetchProjects();
      final List<ContractDetailOption> contractors = await _soft(
        _source.fetchContractors,
      );
      final List<ContractDetailOption> contractStatuses = await _soft(
        _source.fetchContractStatuses,
      );
      state = state.copyWith(
        projects: projects,
        contractors: contractors,
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

  void setContractStatus(String? id) {
    state = state.copyWith(
      contractStatusId: id?.trim() ?? '',
      clearError: true,
    );
  }

  void setFromDate(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearFromDate: true, clearError: true);
      return;
    }
    state = state.copyWith(fromDate: date, clearError: true);
  }

  void setToDate(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearToDate: true, clearError: true);
      return;
    }
    state = state.copyWith(toDate: date, clearError: true);
  }

  Future<void> reset() async {
    state = state.copyWith(
      projectId: '',
      contractorId: '',
      contractStatusId: '',
      clearFromDate: true,
      clearToDate: true,
      clearError: true,
    );
    await load();
  }

  Future<({Uint8List bytes, String fileName})> generate() async {
    final DateTime? from = state.fromDate;
    final DateTime? to = state.toDate;
    if (from == null || to == null) {
      throw StateError(
        'Please select Validity Expiry From Date and Validity Expiry To Date.',
      );
    }
    state = state.copyWith(generating: true, clearError: true);
    try {
      final ({Uint8List bytes, String fileName}) file = await _source.generate(
        projectId: state.projectId,
        contractorId: state.contractorId,
        contractStatus: state.contractStatusId,
        fromDate: BgInsuranceReportState.apiDateFormat.format(from),
        toDate: BgInsuranceReportState.apiDateFormat.format(to),
      );
      state = state.copyWith(generating: false);
      return file;
    } on Object catch (error) {
      state = state.copyWith(generating: false, error: error);
      rethrow;
    }
  }
}
