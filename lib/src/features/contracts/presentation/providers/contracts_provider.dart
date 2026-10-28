import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/contracts/data/datasources/contract_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/contracts/domain/contract_list.dart';

final contractsControllerProvider =
    NotifierProvider.autoDispose<ContractsController, ContractsState>(
      ContractsController.new,
    );

class ContractsState {
  const ContractsState({
    required this.query,
    required this.snapshot,
    required this.loading,
    required this.error,
  });

  factory ContractsState.initial() {
    return const ContractsState(
      query: ContractListQuery(),
      snapshot: ContractListSnapshot.empty,
      loading: true,
      error: null,
    );
  }

  final ContractListQuery query;
  final ContractListSnapshot snapshot;
  final bool loading;
  final Object? error;

  ContractsState copyWith({
    ContractListQuery? query,
    ContractListSnapshot? snapshot,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return ContractsState(
      query: query ?? this.query,
      snapshot: snapshot ?? this.snapshot,
      loading: loading ?? this.loading,
      error: clearError
          ? null
          : identical(error, _keepError)
          ? this.error
          : error,
    );
  }
}

const Object _keepError = Object();

class ContractsController extends AutoDisposeNotifier<ContractsState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  ContractsState build() {
    final int life = ++_life;
    _disposed = false;
    ref.onDispose(() {
      if (_life == life) {
        _disposed = true;
      }
    });
    Future<void>.microtask(() {
      if (_disposed || _life != life) {
        return;
      }
      load();
    });
    return ContractsState.initial();
  }

  ContractRemoteDataSource get _source =>
      ref.read(contractRemoteDataSourceProvider);

  void selectProject(String value) {
    _apply(
      state.query.copyWith(projectIdFk: value, page: 1),
      ContractFilterField.project,
    );
  }

  void selectHod(String value) {
    _apply(
      state.query.copyWith(designation: value, page: 1),
      ContractFilterField.hod,
    );
  }

  void selectDyHod(String value) {
    _apply(
      state.query.copyWith(dyHod: value, page: 1),
      ContractFilterField.dyHod,
    );
  }

  void selectContractor(String value) {
    _apply(
      state.query.copyWith(contractorIdFk: value, page: 1),
      ContractFilterField.contractor,
    );
  }

  void selectContractStatus(String value) {
    _apply(
      state.query.copyWith(contractStatus: value, page: 1),
      ContractFilterField.contractStatus,
    );
  }

  void selectWorkStatus(String value) {
    _apply(
      state.query.copyWith(status: value, page: 1),
      ContractFilterField.workStatus,
    );
  }

  void clearFilters() {
    _apply(
      state.query.copyWith(
        projectIdFk: '',
        designation: '',
        dyHod: '',
        contractorIdFk: '',
        contractStatus: '',
        status: '',
        page: 1,
      ),
      null,
    );
  }

  void setSearch(String value) {
    final String search = value.trim();
    if (search == state.query.search) {
      return;
    }
    state = state.copyWith(
      query: state.query.copyWith(search: search, page: 1),
      loading: true,
      clearError: true,
    );
    load(reloadFilters: false);
  }

  void setPage(int page) {
    if (page < 1 || page == state.query.page) {
      return;
    }
    state = state.copyWith(
      query: state.query.copyWith(page: page),
      loading: true,
      clearError: true,
    );
    load(reloadFilters: false);
  }

  void setPageSize(int pageSize) {
    if (pageSize < 1 || pageSize == state.query.pageSize) {
      return;
    }
    state = state.copyWith(
      query: state.query.copyWith(pageSize: pageSize, page: 1),
      loading: true,
      clearError: true,
    );
    load(reloadFilters: false);
  }

  void _apply(ContractListQuery query, ContractFilterField? changed) {
    state = state.copyWith(
      query: query,
      snapshot: state.snapshot.copyWith(
        rows: const <ContractRow>[],
        total: 0,
      ),
      loading: true,
      clearError: true,
    );
    load(changed: changed);
  }

  Future<void> load({
    ContractFilterField? changed,
    bool reloadFilters = true,
  }) async {
    final int ticket = ++_ticket;
    final ContractListQuery query = state.query;
    final ContractListSnapshot previous = state.snapshot;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final ContractListSnapshot snapshot = await _source.fetch(
        query,
        changed: changed,
        previous: previous,
        reloadFilters: reloadFilters,
      );
      if (_disposed || ticket != _ticket) {
        return;
      }
      final ContractListQuery cleaned = _retainSelections(query, snapshot);
      state = state.copyWith(
        query: cleaned,
        snapshot: snapshot,
        loading: false,
        clearError: true,
      );
    } on Object catch (error) {
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(loading: false, error: error);
    }
  }

  ContractListQuery _retainSelections(
    ContractListQuery query,
    ContractListSnapshot snapshot,
  ) {
    String retain(String value, List<ContractOption> options) {
      if (value.isEmpty) {
        return '';
      }
      return options.any((ContractOption option) => option.value == value)
          ? value
          : '';
    }

    return query.copyWith(
      projectIdFk: retain(query.projectIdFk, snapshot.projects),
      designation: retain(query.designation, snapshot.hods),
      dyHod: retain(query.dyHod, snapshot.dyHods),
      contractorIdFk: retain(query.contractorIdFk, snapshot.contractors),
      contractStatus: retain(query.contractStatus, snapshot.contractStatuses),
      status: retain(query.status, snapshot.workStatuses),
    );
  }
}
