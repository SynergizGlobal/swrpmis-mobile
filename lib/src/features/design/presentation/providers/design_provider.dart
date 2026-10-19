import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/design/data/datasources/design_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/design/domain/design_list.dart';

final designsControllerProvider =
    NotifierProvider.autoDispose<DesignsController, DesignsState>(
      DesignsController.new,
    );

final designUploadsControllerProvider =
    NotifierProvider.autoDispose<DesignUploadsController, DesignUploadsState>(
      DesignUploadsController.new,
    );

class DesignsState {
  const DesignsState({
    required this.query,
    required this.snapshot,
    required this.loading,
    required this.error,
  });

  factory DesignsState.initial() {
    return const DesignsState(
      query: DesignListQuery(),
      snapshot: DesignListSnapshot.empty,
      loading: true,
      error: null,
    );
  }

  final DesignListQuery query;
  final DesignListSnapshot snapshot;
  final bool loading;
  final Object? error;

  DesignsState copyWith({
    DesignListQuery? query,
    DesignListSnapshot? snapshot,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return DesignsState(
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

class DesignUploadsState {
  const DesignUploadsState({
    required this.rows,
    required this.loading,
    required this.error,
  });

  factory DesignUploadsState.initial() {
    return const DesignUploadsState(
      rows: <DesignUploadRow>[],
      loading: true,
      error: null,
    );
  }

  final List<DesignUploadRow> rows;
  final bool loading;
  final Object? error;

  DesignUploadsState copyWith({
    List<DesignUploadRow>? rows,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return DesignUploadsState(
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

class DesignsController extends AutoDisposeNotifier<DesignsState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  DesignsState build() {
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
    return DesignsState.initial();
  }

  DesignRemoteDataSource get _source =>
      ref.read(designRemoteDataSourceProvider);

  void selectContract(String value) {
    _apply(
      state.query.copyWith(contractId: value, page: 1),
      DesignFilterField.contract,
    );
  }

  void selectStructureType(String value) {
    _apply(
      state.query.copyWith(structureType: value, page: 1),
      DesignFilterField.structureType,
    );
  }

  void selectDrawingType(String value) {
    _apply(
      state.query.copyWith(drawingType: value, page: 1),
      DesignFilterField.drawingType,
    );
  }

  void clearFilters() {
    _apply(
      state.query.copyWith(
        contractId: '',
        structureType: '',
        drawingType: '',
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

  void _apply(DesignListQuery query, DesignFilterField? changed) {
    state = state.copyWith(
      query: query,
      snapshot: state.snapshot.copyWith(rows: const <DesignRow>[], total: 0),
      loading: true,
      clearError: true,
    );
    load(changed: changed);
  }

  Future<void> load({
    DesignFilterField? changed,
    bool reloadFilters = true,
  }) async {
    final int ticket = ++_ticket;
    final DesignListQuery query = state.query;
    final DesignListSnapshot previous = state.snapshot;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final DesignListSnapshot snapshot = await _source.fetch(
        query,
        changed: changed,
        previous: previous,
        reloadFilters: reloadFilters,
      );
      if (_disposed || ticket != _ticket) {
        return;
      }
      final DesignListQuery cleaned = _retainSelections(query, snapshot);
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

  DesignListQuery _retainSelections(
    DesignListQuery query,
    DesignListSnapshot snapshot,
  ) {
    String retain(String value, List<DesignOption> options) {
      if (value.isEmpty) {
        return '';
      }
      return options.any((DesignOption option) => option.value == value)
          ? value
          : '';
    }

    return query.copyWith(
      contractId: retain(query.contractId, snapshot.contracts),
      structureType: retain(query.structureType, snapshot.structureTypes),
      drawingType: retain(query.drawingType, snapshot.drawingTypes),
    );
  }
}

class DesignUploadsController extends AutoDisposeNotifier<DesignUploadsState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  DesignUploadsState build() {
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
    return DesignUploadsState.initial();
  }

  DesignRemoteDataSource get _source =>
      ref.read(designRemoteDataSourceProvider);

  Future<void> load() async {
    final int ticket = ++_ticket;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<DesignUploadRow> rows = await _source.fetchUploads();
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
