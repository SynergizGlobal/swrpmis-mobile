import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/quality_control_summary_report_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/quality_control_summary_report.dart';

final qualityControlSummaryReportControllerProvider =
    StateNotifierProvider.autoDispose<
      QualityControlSummaryReportController,
      QualityControlSummaryReportState
    >((Ref ref) {
      final QualityControlSummaryReportController controller =
          QualityControlSummaryReportController(
            ref.watch(qualityControlSummaryReportRemoteDataSourceProvider),
          );
      controller.load();
      return controller;
    });

class QualityControlSummaryReportState {
  const QualityControlSummaryReportState({
    this.projects = const <ContractDetailOption>[],
    this.contracts = const <ContractDetailOption>[],
    this.projectId = '',
    this.contractId = '',
    this.fromDate,
    this.toDate,
    this.contractorName = '',
    this.report,
    this.generated = false,
    this.loading = false,
    this.loadingContracts = false,
    this.generating = false,
    this.error,
  });

  final List<ContractDetailOption> projects;
  final List<ContractDetailOption> contracts;
  final String projectId;
  final String contractId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String contractorName;
  final QualityControlSummaryReport? report;
  final bool generated;
  final bool loading;
  final bool loadingContracts;
  final bool generating;
  final Object? error;

  /// API query uses `yyyy-MM-dd`.
  static final DateFormat apiDateFormat = DateFormat('yyyy-MM-dd');
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
  ContractDetailOption? get selectedContract => _find(contracts, contractId);

  String? get fromDateLabel =>
      fromDate == null ? null : displayDateFormat.format(fromDate!);
  String? get toDateLabel =>
      toDate == null ? null : displayDateFormat.format(toDate!);

  /// Labels of filters required before Generate.
  List<String> get missingRequiredFilters {
    final List<String> missing = <String>[];
    if (projectId.trim().isEmpty) {
      missing.add('Project');
    }
    if (contractId.trim().isEmpty) {
      missing.add('Contract');
    }
    if (fromDate == null) {
      missing.add('From date');
    }
    if (toDate == null) {
      missing.add('To date');
    }
    if (contractorName.trim().isEmpty) {
      missing.add('Contractor Name');
    }
    return missing;
  }

  String? get dateRangeError {
    final DateTime? from = fromDate;
    final DateTime? to = toDate;
    if (from == null || to == null) {
      return null;
    }
    final DateTime fromDay = DateTime(from.year, from.month, from.day);
    final DateTime toDay = DateTime(to.year, to.month, to.day);
    if (fromDay.isAfter(toDay)) {
      return 'From date must be on or before To date.';
    }
    return null;
  }

  QualityControlSummaryReportState copyWith({
    List<ContractDetailOption>? projects,
    List<ContractDetailOption>? contracts,
    String? projectId,
    String? contractId,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearFromDate = false,
    bool clearToDate = false,
    String? contractorName,
    QualityControlSummaryReport? report,
    bool clearReport = false,
    bool? generated,
    bool? loading,
    bool? loadingContracts,
    bool? generating,
    Object? error = _sentinel,
    bool clearError = false,
  }) {
    return QualityControlSummaryReportState(
      projects: projects ?? this.projects,
      contracts: contracts ?? this.contracts,
      projectId: projectId ?? this.projectId,
      contractId: contractId ?? this.contractId,
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      contractorName: contractorName ?? this.contractorName,
      report: clearReport ? null : (report ?? this.report),
      generated: generated ?? this.generated,
      loading: loading ?? this.loading,
      loadingContracts: loadingContracts ?? this.loadingContracts,
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

class QualityControlSummaryReportController
    extends StateNotifier<QualityControlSummaryReportState> {
  QualityControlSummaryReportController(this._source)
    : super(const QualityControlSummaryReportState());

  final QualityControlSummaryReportRemoteDataSource _source;
  int _contractsRequestId = 0;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<ContractDetailOption> projects = await _source.fetchProjects();
      state = state.copyWith(
        projects: projects,
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
      contractId: '',
      contracts: const <ContractDetailOption>[],
      clearReport: true,
      generated: false,
      clearError: true,
    );
    if (next.isEmpty) {
      return;
    }
    await _loadContracts(next);
  }

  void setContract(String? id) {
    state = state.copyWith(
      contractId: id?.trim() ?? '',
      clearReport: true,
      generated: false,
      clearError: true,
    );
  }

  void setFromDate(DateTime? date) {
    if (date == null) {
      state = state.copyWith(
        clearFromDate: true,
        clearReport: true,
        generated: false,
        clearError: true,
      );
      return;
    }
    state = state.copyWith(
      fromDate: date,
      clearReport: true,
      generated: false,
      clearError: true,
    );
  }

  void setToDate(DateTime? date) {
    if (date == null) {
      state = state.copyWith(
        clearToDate: true,
        clearReport: true,
        generated: false,
        clearError: true,
      );
      return;
    }
    state = state.copyWith(
      toDate: date,
      clearReport: true,
      generated: false,
      clearError: true,
    );
  }

  void setContractorName(String value) {
    state = state.copyWith(
      contractorName: value,
      clearReport: true,
      generated: false,
      clearError: true,
    );
  }

  Future<void> clear() async {
    _contractsRequestId++;
    state = const QualityControlSummaryReportState();
    await load();
  }

  Future<void> generate() async {
    final List<String> missing = state.missingRequiredFilters;
    if (missing.isNotEmpty) {
      throw StateError(
        'Please select ${missing.join(', ')} before generating the report.',
      );
    }
    final String? rangeError = state.dateRangeError;
    if (rangeError != null) {
      throw StateError(rangeError);
    }
    final DateTime from = state.fromDate!;
    final DateTime to = state.toDate!;
    final ContractDetailOption? project = state.selectedProject;
    final ContractDetailOption? contract = state.selectedContract;
    state = state.copyWith(generating: true, clearError: true);
    try {
      final QualityControlSummaryReport report = await _source.fetchSummary(
        contractId: state.contractId,
        from: QualityControlSummaryReportState.apiDateFormat.format(from),
        to: QualityControlSummaryReportState.apiDateFormat.format(to),
        projectName: project?.label ?? '',
        contractShortName: contract?.label ?? '',
        contractorName: state.contractorName.trim(),
      );
      state = state.copyWith(
        report: report,
        generated: true,
        generating: false,
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(
        generating: false,
        generated: true,
        clearReport: true,
        error: error,
      );
      rethrow;
    }
  }

  Future<void> _loadContracts(String projectId) async {
    final int requestId = ++_contractsRequestId;
    state = state.copyWith(loadingContracts: true, clearError: true);
    try {
      final List<ContractDetailOption> contracts = await _source.fetchContracts(
        projectId,
      );
      if (requestId != _contractsRequestId) {
        return;
      }
      state = state.copyWith(
        contracts: contracts,
        loadingContracts: false,
        clearError: true,
      );
    } on Object catch (error) {
      if (requestId != _contractsRequestId) {
        return;
      }
      state = state.copyWith(
        contracts: const <ContractDetailOption>[],
        loadingContracts: false,
        error: error,
      );
    }
  }
}
