import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/data/datasources/ncr_observation_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/domain/ncr_observation_list.dart';

final ncrObservationControllerProvider =
    NotifierProvider.autoDispose<NcrObservationController, NcrObservationState>(
      NcrObservationController.new,
    );

class NcrObservationState {
  const NcrObservationState({
    required this.query,
    required this.snapshot,
    required this.loading,
    required this.error,
  });

  factory NcrObservationState.initial() {
    return const NcrObservationState(
      query: NcrObservationListQuery(),
      snapshot: NcrObservationSnapshot.empty,
      loading: true,
      error: null,
    );
  }

  final NcrObservationListQuery query;
  final NcrObservationSnapshot snapshot;
  final bool loading;
  final Object? error;

  NcrObservationState copyWith({
    NcrObservationListQuery? query,
    NcrObservationSnapshot? snapshot,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return NcrObservationState(
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

class NcrObservationController
    extends AutoDisposeNotifier<NcrObservationState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  NcrObservationState build() {
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
    return NcrObservationState.initial();
  }

  NcrObservationRemoteDataSource get _source =>
      ref.read(ncrObservationRemoteDataSourceProvider);

  void selectProject(String value) {
    _apply(
      state.query.copyWith(
        projectId: value,
        sectionId: '',
        contractId: '',
        page: 1,
      ),
      reloadFilters: true,
    );
  }

  void selectSection(String value) {
    _apply(state.query.copyWith(sectionId: value, page: 1));
  }

  void selectContract(String value) {
    _apply(state.query.copyWith(contractId: value, page: 1));
  }

  void selectType(String value) {
    _apply(state.query.copyWith(ncrType: value, page: 1));
  }

  void selectStatus(String value) {
    _apply(state.query.copyWith(status: value, page: 1));
  }

  void selectDateRange({required String from, required String to}) {
    _apply(state.query.copyWith(dateFrom: from, dateTo: to, page: 1));
  }

  void clearFilters() {
    _apply(
      state.query.copyWith(
        projectId: '',
        sectionId: '',
        contractId: '',
        ncrType: '',
        status: '',
        dateFrom: '',
        dateTo: '',
        search: '',
        page: 1,
      ),
      reloadFilters: true,
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
    NcrObservationListQuery query, {
    bool reloadFilters = true,
  }) {
    state = state.copyWith(
      query: query,
      snapshot: state.snapshot.copyWith(
        rows: const <NcrObservationRow>[],
        total: 0,
      ),
      loading: true,
      clearError: true,
    );
    load(reloadFilters: reloadFilters);
  }

  Future<void> load({bool reloadFilters = true}) async {
    final int ticket = ++_ticket;
    final NcrObservationListQuery query = state.query;
    final NcrObservationSnapshot previous = state.snapshot;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final NcrObservationSnapshot snapshot = await _source.fetch(
        query,
        previous: previous,
        reloadFilters: reloadFilters,
      );
      if (_disposed || ticket != _ticket) {
        return;
      }
      final NcrObservationListQuery cleaned = _retainSelections(
        query,
        snapshot,
      );
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

  NcrObservationListQuery _retainSelections(
    NcrObservationListQuery query,
    NcrObservationSnapshot snapshot,
  ) {
    String retain(String value, List<NcrOption> options) {
      if (value.isEmpty) {
        return '';
      }
      return options.any((NcrOption option) => option.value == value)
          ? value
          : '';
    }

    return query.copyWith(
      projectId: retain(query.projectId, snapshot.projects),
      sectionId: retain(query.sectionId, snapshot.sections),
      contractId: retain(query.contractId, snapshot.contracts),
    );
  }
}
