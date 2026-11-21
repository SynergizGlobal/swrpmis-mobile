import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/issue_details_report_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/issue_details_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/pending_issues_report.dart';

final issueDetailsReportControllerProvider =
    StateNotifierProvider.autoDispose<
      IssueDetailsReportController,
      IssueDetailsReportState
    >((Ref ref) {
      final IssueDetailsReportController controller =
          IssueDetailsReportController(
            ref.watch(issueDetailsReportRemoteDataSourceProvider),
          );
      controller.load();
      return controller;
    });

class IssueDetailsReportState {
  const IssueDetailsReportState({
    this.hods = const <PendingIssuesHodOption>[],
    this.contracts = const <ContractDetailOption>[],
    this.statuses = const <ContractDetailOption>[],
    this.locations = const <ContractDetailOption>[],
    this.categories = const <ContractDetailOption>[],
    this.titles = const <IssueDetailsTitleOption>[],
    this.hodSelectionId = '',
    this.contractId = '',
    this.statusId = '',
    this.locationId = '',
    this.categoryId = '',
    this.issueId = '',
    this.loading = false,
    this.generating = false,
    this.error,
  });

  final List<PendingIssuesHodOption> hods;
  final List<ContractDetailOption> contracts;
  final List<ContractDetailOption> statuses;
  final List<ContractDetailOption> locations;
  final List<ContractDetailOption> categories;
  final List<IssueDetailsTitleOption> titles;
  final String hodSelectionId;
  final String contractId;
  final String statusId;
  final String locationId;
  final String categoryId;
  final String issueId;
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

  ContractDetailOption? get selectedStatus {
    for (final ContractDetailOption item in statuses) {
      if (item.id == statusId) {
        return item;
      }
    }
    return null;
  }

  ContractDetailOption? get selectedLocation {
    for (final ContractDetailOption item in locations) {
      if (item.id == locationId) {
        return item;
      }
    }
    return null;
  }

  ContractDetailOption? get selectedCategory {
    for (final ContractDetailOption item in categories) {
      if (item.id == categoryId) {
        return item;
      }
    }
    return null;
  }

  IssueDetailsTitleOption? get selectedTitle {
    for (final IssueDetailsTitleOption item in titles) {
      if (item.issueId == issueId) {
        return item;
      }
    }
    return null;
  }

  /// Filters are optional; generate always allowed (empty strings for cleared).
  bool get canGenerate => !loading && !generating;

  IssueDetailsReportState copyWith({
    List<PendingIssuesHodOption>? hods,
    List<ContractDetailOption>? contracts,
    List<ContractDetailOption>? statuses,
    List<ContractDetailOption>? locations,
    List<ContractDetailOption>? categories,
    List<IssueDetailsTitleOption>? titles,
    String? hodSelectionId,
    String? contractId,
    String? statusId,
    String? locationId,
    String? categoryId,
    String? issueId,
    bool? loading,
    bool? generating,
    Object? error = _sentinel,
    bool clearError = false,
  }) {
    return IssueDetailsReportState(
      hods: hods ?? this.hods,
      contracts: contracts ?? this.contracts,
      statuses: statuses ?? this.statuses,
      locations: locations ?? this.locations,
      categories: categories ?? this.categories,
      titles: titles ?? this.titles,
      hodSelectionId: hodSelectionId ?? this.hodSelectionId,
      contractId: contractId ?? this.contractId,
      statusId: statusId ?? this.statusId,
      locationId: locationId ?? this.locationId,
      categoryId: categoryId ?? this.categoryId,
      issueId: issueId ?? this.issueId,
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

class IssueDetailsReportController
    extends StateNotifier<IssueDetailsReportState> {
  IssueDetailsReportController(this._source)
    : super(const IssueDetailsReportState());

  final IssueDetailsReportRemoteDataSource _source;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        _source.fetchHods(),
        _source.fetchContracts(),
        _source.fetchStatuses(),
        _source.fetchLocations(),
        _source.fetchCategories(),
        _source.fetchTitles(),
      ]);
      state = state.copyWith(
        hods: results[0] as List<PendingIssuesHodOption>,
        contracts: results[1] as List<ContractDetailOption>,
        statuses: results[2] as List<ContractDetailOption>,
        locations: results[3] as List<ContractDetailOption>,
        categories: results[4] as List<ContractDetailOption>,
        titles: results[5] as List<IssueDetailsTitleOption>,
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

  void setStatus(String? id) {
    state = state.copyWith(statusId: id?.trim() ?? '', clearError: true);
  }

  void setLocation(String? id) {
    state = state.copyWith(locationId: id?.trim() ?? '', clearError: true);
  }

  void setCategory(String? id) {
    state = state.copyWith(categoryId: id?.trim() ?? '', clearError: true);
  }

  void setIssue(String? id) {
    state = state.copyWith(issueId: id?.trim() ?? '', clearError: true);
  }

  void clearFilters() {
    state = state.copyWith(
      hodSelectionId: '',
      contractId: '',
      statusId: '',
      locationId: '',
      categoryId: '',
      issueId: '',
      clearError: true,
    );
  }

  Future<({Uint8List bytes, String fileName})> generate() async {
    // HOD generate value is user id (not display name — unlike Pending Issues).
    final String hodUserId = state.selectedHod?.userId.trim() ??
        state.hodSelectionId.trim();
    state = state.copyWith(generating: true, clearError: true);
    try {
      final ({Uint8List bytes, String fileName}) file = await _source.generate(
        hodUserId: hodUserId,
        contractId: state.contractId,
        status: state.statusId,
        location: state.locationId,
        category: state.categoryId,
        issueId: state.issueId,
      );
      state = state.copyWith(generating: false);
      return file;
    } on Object catch (error) {
      state = state.copyWith(generating: false, error: error);
      rethrow;
    }
  }
}
