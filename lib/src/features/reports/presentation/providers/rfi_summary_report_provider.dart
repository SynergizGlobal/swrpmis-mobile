import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/rfi_summary_report_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/rfi_summary_report.dart';

final rfiSummaryReportControllerProvider =
    StateNotifierProvider.autoDispose<
      RfiSummaryReportController,
      RfiSummaryReportState
    >((Ref ref) {
      final RfiSummaryReportController controller = RfiSummaryReportController(
        ref.watch(rfiSummaryReportRemoteDataSourceProvider),
      );
      controller.load();
      return controller;
    });

class RfiSummaryReportState {
  const RfiSummaryReportState({
    this.projects = const <ContractDetailOption>[],
    this.contracts = const <ContractDetailOption>[],
    this.categories = const <ContractDetailOption>[],
    this.projectId = '',
    this.contractId = '',
    this.categoryId = '',
    this.fromDate,
    this.toDate,
    this.dateRange,
    this.loading = false,
    this.loadingContracts = false,
    this.loadingCategories = false,
    this.loadingDateRange = false,
    this.downloading = false,
    this.error,
  });

  final List<ContractDetailOption> projects;
  final List<ContractDetailOption> contracts;
  final List<ContractDetailOption> categories;
  final String projectId;
  final String contractId;
  final String categoryId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final RfiSummaryDateRange? dateRange;
  final bool loading;
  final bool loadingContracts;
  final bool loadingCategories;
  final bool loadingDateRange;
  final bool downloading;
  final Object? error;

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
  ContractDetailOption? get selectedCategory => _find(categories, categoryId);

  String? get fromDateLabel =>
      fromDate == null ? null : displayDateFormat.format(fromDate!);
  String? get toDateLabel =>
      toDate == null ? null : displayDateFormat.format(toDate!);

  bool get canDownload =>
      projectId.trim().isNotEmpty &&
      contractId.trim().isNotEmpty &&
      categoryId.trim().isNotEmpty;

  bool get showSingleCategoryNote => categories.length == 1;

  String get dateRangeHint => dateRange?.hintLabel ?? '';

  String? get dateRangeError {
    final DateTime? from = fromDate;
    final DateTime? to = toDate;
    if (from != null && to != null) {
      final DateTime fromDay = DateTime(from.year, from.month, from.day);
      final DateTime toDay = DateTime(to.year, to.month, to.day);
      if (fromDay.isAfter(toDay)) {
        return 'Date Of Submission From must be on or before To.';
      }
    }
    final RfiSummaryDateRange? range = dateRange;
    if (range == null) {
      return null;
    }
    for (final DateTime? picked in <DateTime?>[from, to]) {
      if (picked == null) {
        continue;
      }
      final DateTime day = DateTime(picked.year, picked.month, picked.day);
      final DateTime? min = range.minDate;
      final DateTime? max = range.maxDate;
      if (min != null) {
        final DateTime minDay = DateTime(min.year, min.month, min.day);
        if (day.isBefore(minDay)) {
          return 'Submission dates must be within the available range.';
        }
      }
      if (max != null) {
        final DateTime maxDay = DateTime(max.year, max.month, max.day);
        if (day.isAfter(maxDay)) {
          return 'Submission dates must be within the available range.';
        }
      }
    }
    return null;
  }

  RfiSummaryReportState copyWith({
    List<ContractDetailOption>? projects,
    List<ContractDetailOption>? contracts,
    List<ContractDetailOption>? categories,
    String? projectId,
    String? contractId,
    String? categoryId,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearFromDate = false,
    bool clearToDate = false,
    RfiSummaryDateRange? dateRange,
    bool clearDateRange = false,
    bool? loading,
    bool? loadingContracts,
    bool? loadingCategories,
    bool? loadingDateRange,
    bool? downloading,
    Object? error = _sentinel,
    bool clearError = false,
  }) {
    return RfiSummaryReportState(
      projects: projects ?? this.projects,
      contracts: contracts ?? this.contracts,
      categories: categories ?? this.categories,
      projectId: projectId ?? this.projectId,
      contractId: contractId ?? this.contractId,
      categoryId: categoryId ?? this.categoryId,
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      loading: loading ?? this.loading,
      loadingContracts: loadingContracts ?? this.loadingContracts,
      loadingCategories: loadingCategories ?? this.loadingCategories,
      loadingDateRange: loadingDateRange ?? this.loadingDateRange,
      downloading: downloading ?? this.downloading,
      error: clearError
          ? null
          : identical(error, _sentinel)
          ? this.error
          : error,
    );
  }
}

const Object _sentinel = Object();

class RfiSummaryReportController extends StateNotifier<RfiSummaryReportState> {
  RfiSummaryReportController(this._source)
    : super(const RfiSummaryReportState());

  final RfiSummaryReportRemoteDataSource _source;
  int _contractsRequestId = 0;
  int _categoriesRequestId = 0;
  int _dateRangeRequestId = 0;

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
    _contractsRequestId++;
    _categoriesRequestId++;
    _dateRangeRequestId++;
    state = state.copyWith(
      projectId: next,
      contractId: '',
      categoryId: '',
      contracts: const <ContractDetailOption>[],
      categories: const <ContractDetailOption>[],
      clearFromDate: true,
      clearToDate: true,
      clearDateRange: true,
      loadingContracts: false,
      loadingCategories: false,
      loadingDateRange: false,
      clearError: true,
    );
    if (next.isEmpty) {
      return;
    }
    await _loadContracts(next);
  }

  Future<void> setContract(String? id) async {
    final String next = id?.trim() ?? '';
    _categoriesRequestId++;
    _dateRangeRequestId++;
    state = state.copyWith(
      contractId: next,
      categoryId: '',
      categories: const <ContractDetailOption>[],
      clearFromDate: true,
      clearToDate: true,
      clearDateRange: true,
      loadingCategories: false,
      loadingDateRange: false,
      clearError: true,
    );
    if (next.isEmpty || state.projectId.isEmpty) {
      return;
    }
    await _loadCategories(projectId: state.projectId, contractId: next);
  }

  Future<void> setCategory(String? id) async {
    final String next = id?.trim() ?? '';
    _dateRangeRequestId++;
    state = state.copyWith(
      categoryId: next,
      clearFromDate: true,
      clearToDate: true,
      clearDateRange: true,
      loadingDateRange: false,
      clearError: true,
    );
    if (next.isEmpty || state.projectId.isEmpty || state.contractId.isEmpty) {
      return;
    }
    await _loadDateRange(
      projectId: state.projectId,
      contractId: state.contractId,
      rfiCategory: next,
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
    _contractsRequestId++;
    _categoriesRequestId++;
    _dateRangeRequestId++;
    state = const RfiSummaryReportState();
    await load();
  }

  Future<({Uint8List bytes, String fileName})> downloadExcel() async {
    if (!state.canDownload) {
      throw StateError(
        'Please select Project, Contract, and RFI Category before downloading.',
      );
    }
    final String? rangeError = state.dateRangeError;
    if (rangeError != null) {
      throw StateError(rangeError);
    }
    state = state.copyWith(downloading: true, clearError: true);
    try {
      final ({Uint8List bytes, String fileName}) file = await _source
          .downloadExcel(
            projectId: state.projectId,
            contractId: state.contractId,
            rfiCategory: state.categoryId,
            from: state.fromDate == null
                ? null
                : RfiSummaryReportState.apiDateFormat.format(state.fromDate!),
            to: state.toDate == null
                ? null
                : RfiSummaryReportState.apiDateFormat.format(state.toDate!),
          );
      state = state.copyWith(downloading: false, clearError: true);
      return file;
    } on Object catch (error) {
      state = state.copyWith(downloading: false, error: error);
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

  Future<void> _loadCategories({
    required String projectId,
    required String contractId,
  }) async {
    final int requestId = ++_categoriesRequestId;
    state = state.copyWith(loadingCategories: true, clearError: true);
    try {
      final List<ContractDetailOption> categories = await _source
          .fetchCategories(projectId: projectId, contractId: contractId);
      if (requestId != _categoriesRequestId) {
        return;
      }
      state = state.copyWith(
        categories: categories,
        loadingCategories: false,
        clearError: true,
      );
    } on Object catch (error) {
      if (requestId != _categoriesRequestId) {
        return;
      }
      state = state.copyWith(
        categories: const <ContractDetailOption>[],
        loadingCategories: false,
        error: error,
      );
    }
  }

  Future<void> _loadDateRange({
    required String projectId,
    required String contractId,
    required String rfiCategory,
  }) async {
    final int requestId = ++_dateRangeRequestId;
    state = state.copyWith(loadingDateRange: true, clearError: true);
    try {
      final RfiSummaryDateRange range = await _source.fetchDateRange(
        projectId: projectId,
        contractId: contractId,
        rfiCategory: rfiCategory,
      );
      if (requestId != _dateRangeRequestId) {
        return;
      }
      state = state.copyWith(
        dateRange: range,
        loadingDateRange: false,
        clearError: true,
      );
    } on Object catch (error) {
      if (requestId != _dateRangeRequestId) {
        return;
      }
      state = state.copyWith(
        clearDateRange: true,
        loadingDateRange: false,
        error: error,
      );
    }
  }
}
