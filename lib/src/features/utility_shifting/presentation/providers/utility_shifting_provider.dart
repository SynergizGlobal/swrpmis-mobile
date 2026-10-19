import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/data/datasources/utility_shifting_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/domain/utility_shifting_list.dart';

final utilityShiftingControllerProvider =
    NotifierProvider.autoDispose<
      UtilityShiftingController,
      UtilityShiftingState
    >(UtilityShiftingController.new);

final utilityShiftingUploadsControllerProvider =
    NotifierProvider.autoDispose<
      UtilityShiftingUploadsController,
      UtilityShiftingUploadsState
    >(UtilityShiftingUploadsController.new);

class UtilityShiftingState {
  const UtilityShiftingState({
    required this.query,
    required this.snapshot,
    required this.loading,
    required this.error,
  });

  factory UtilityShiftingState.initial() {
    return const UtilityShiftingState(
      query: UtilityShiftingListQuery(),
      snapshot: UtilityShiftingListSnapshot.empty,
      loading: true,
      error: null,
    );
  }

  final UtilityShiftingListQuery query;
  final UtilityShiftingListSnapshot snapshot;
  final bool loading;
  final Object? error;

  UtilityShiftingState copyWith({
    UtilityShiftingListQuery? query,
    UtilityShiftingListSnapshot? snapshot,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return UtilityShiftingState(
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

class UtilityShiftingUploadsState {
  const UtilityShiftingUploadsState({
    required this.rows,
    required this.loading,
    required this.error,
  });

  factory UtilityShiftingUploadsState.initial() {
    return const UtilityShiftingUploadsState(
      rows: <UtilityShiftingUploadRow>[],
      loading: true,
      error: null,
    );
  }

  final List<UtilityShiftingUploadRow> rows;
  final bool loading;
  final Object? error;

  UtilityShiftingUploadsState copyWith({
    List<UtilityShiftingUploadRow>? rows,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return UtilityShiftingUploadsState(
      rows: rows ?? this.rows,
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

class UtilityShiftingController
    extends AutoDisposeNotifier<UtilityShiftingState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  UtilityShiftingState build() {
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
    return UtilityShiftingState.initial();
  }

  UtilityShiftingRemoteDataSource get _source =>
      ref.read(utilityShiftingRemoteDataSourceProvider);

  void selectLocation(String value) {
    _apply(
      state.query.copyWith(locationName: value, page: 1),
      UtilityShiftingFilterField.location,
    );
  }

  void selectCategory(String value) {
    _apply(
      state.query.copyWith(utilityCategory: value, page: 1),
      UtilityShiftingFilterField.category,
    );
  }

  void selectUtilityType(String value) {
    _apply(
      state.query.copyWith(utilityType: value, page: 1),
      UtilityShiftingFilterField.utilityType,
    );
  }

  void selectStatus(String value) {
    _apply(
      state.query.copyWith(status: value, page: 1),
      UtilityShiftingFilterField.status,
    );
  }

  void clearFilters() {
    _apply(
      state.query.copyWith(
        locationName: '',
        utilityCategory: '',
        utilityType: '',
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

  void _apply(
    UtilityShiftingListQuery query,
    UtilityShiftingFilterField? changed,
  ) {
    state = state.copyWith(
      query: query,
      snapshot: state.snapshot.copyWith(
        rows: const <UtilityShiftingRow>[],
        total: 0,
      ),
      loading: true,
      clearError: true,
    );
    load(changed: changed);
  }

  Future<void> load({
    UtilityShiftingFilterField? changed,
    bool reloadFilters = true,
  }) async {
    final int ticket = ++_ticket;
    final UtilityShiftingListQuery query = state.query;
    final UtilityShiftingListSnapshot previous = state.snapshot;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final UtilityShiftingListSnapshot snapshot = await _source.fetch(
        query,
        changed: changed,
        previous: previous,
        reloadFilters: reloadFilters,
      );
      if (_disposed || ticket != _ticket) {
        return;
      }
      final UtilityShiftingListQuery cleaned = _retainSelections(
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

  UtilityShiftingListQuery _retainSelections(
    UtilityShiftingListQuery query,
    UtilityShiftingListSnapshot snapshot,
  ) {
    String retain(String value, List<UtilityShiftingOption> options) {
      if (value.isEmpty) {
        return '';
      }
      return options.any(
            (UtilityShiftingOption option) => option.value == value,
          )
          ? value
          : '';
    }

    return query.copyWith(
      locationName: retain(query.locationName, snapshot.locations),
      utilityCategory: retain(query.utilityCategory, snapshot.categories),
      utilityType: retain(query.utilityType, snapshot.utilityTypes),
      status: retain(query.status, snapshot.statuses),
    );
  }
}

class UtilityShiftingUploadsController
    extends AutoDisposeNotifier<UtilityShiftingUploadsState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  UtilityShiftingUploadsState build() {
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
    return UtilityShiftingUploadsState.initial();
  }

  UtilityShiftingRemoteDataSource get _source =>
      ref.read(utilityShiftingRemoteDataSourceProvider);

  Future<void> load() async {
    final int ticket = ++_ticket;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<UtilityShiftingUploadRow> rows = await _source.fetchUploads();
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(rows: rows, loading: false, clearError: true);
    } on Object catch (error) {
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(loading: false, error: error);
    }
  }
}
