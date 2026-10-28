import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/data/datasources/structure_form_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/domain/structure_form_list.dart';

final structureFormListControllerProvider =
    NotifierProvider.autoDispose<
      StructureFormListController,
      StructureFormListState
    >(StructureFormListController.new);

class StructureFormListState {
  const StructureFormListState({
    required this.query,
    required this.snapshot,
    required this.loading,
    required this.error,
  });

  factory StructureFormListState.initial() {
    return const StructureFormListState(
      query: StructureFormListQuery(),
      snapshot: StructureFormListSnapshot.empty,
      loading: true,
      error: null,
    );
  }

  final StructureFormListQuery query;
  final StructureFormListSnapshot snapshot;
  final bool loading;
  final Object? error;

  StructureFormListState copyWith({
    StructureFormListQuery? query,
    StructureFormListSnapshot? snapshot,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return StructureFormListState(
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

class StructureFormListController
    extends AutoDisposeNotifier<StructureFormListState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  StructureFormListState build() {
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
    return StructureFormListState.initial();
  }

  StructureFormRemoteDataSource get _source =>
      ref.read(structureFormRemoteDataSourceProvider);

  void selectContract(String value) {
    _apply(
      state.query.copyWith(contractIdFk: value, page: 1),
      StructureFormFilterField.contract,
    );
  }

  void selectStructureType(String value) {
    _apply(
      state.query.copyWith(structureTypeFk: value, page: 1),
      StructureFormFilterField.structureType,
    );
  }

  void selectWorkStatus(String value) {
    _apply(
      state.query.copyWith(workStatusFk: value, page: 1),
      StructureFormFilterField.workStatus,
    );
  }

  void clearFilters() {
    _apply(
      state.query.copyWith(
        contractIdFk: '',
        structureTypeFk: '',
        workStatusFk: '',
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

  void _apply(
    StructureFormListQuery query,
    StructureFormFilterField? changed,
  ) {
    state = state.copyWith(
      query: query,
      snapshot: state.snapshot.copyWith(
        rows: const <StructureFormRow>[],
        total: 0,
      ),
      loading: true,
      clearError: true,
    );
    load(changed: changed);
  }

  Future<void> load({
    StructureFormFilterField? changed,
    bool reloadFilters = true,
  }) async {
    final int ticket = ++_ticket;
    final StructureFormListQuery query = state.query;
    final StructureFormListSnapshot previous = state.snapshot;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final StructureFormListSnapshot snapshot = await _source.fetch(
        query,
        changed: changed,
        previous: previous,
        reloadFilters: reloadFilters,
      );
      if (_disposed || ticket != _ticket) {
        return;
      }
      final StructureFormListQuery cleaned = _retainSelections(query, snapshot);
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

  StructureFormListQuery _retainSelections(
    StructureFormListQuery query,
    StructureFormListSnapshot snapshot,
  ) {
    String retain(String value, List<StructureFormOption> options) {
      if (value.isEmpty) {
        return '';
      }
      return options.any((StructureFormOption option) => option.value == value)
          ? value
          : '';
    }

    return query.copyWith(
      contractIdFk: retain(query.contractIdFk, snapshot.contracts),
      structureTypeFk: retain(query.structureTypeFk, snapshot.structureTypes),
      workStatusFk: retain(query.workStatusFk, snapshot.workStatuses),
    );
  }
}
