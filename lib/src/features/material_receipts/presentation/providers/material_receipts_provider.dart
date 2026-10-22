import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/data/datasources/material_receipt_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_list.dart';

final materialReceiptsControllerProvider =
    NotifierProvider.autoDispose<
      MaterialReceiptsController,
      MaterialReceiptsState
    >(MaterialReceiptsController.new);

class MaterialReceiptsState {
  const MaterialReceiptsState({
    required this.query,
    required this.snapshot,
    required this.loading,
    required this.error,
  });

  factory MaterialReceiptsState.initial() {
    return const MaterialReceiptsState(
      query: MaterialReceiptListQuery(),
      snapshot: MaterialReceiptListSnapshot.empty,
      loading: true,
      error: null,
    );
  }

  final MaterialReceiptListQuery query;
  final MaterialReceiptListSnapshot snapshot;
  final bool loading;
  final Object? error;

  MaterialReceiptsState copyWith({
    MaterialReceiptListQuery? query,
    MaterialReceiptListSnapshot? snapshot,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return MaterialReceiptsState(
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

class MaterialReceiptsController
    extends AutoDisposeNotifier<MaterialReceiptsState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  MaterialReceiptsState build() {
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
    return MaterialReceiptsState.initial();
  }

  MaterialReceiptRemoteDataSource get _source =>
      ref.read(materialReceiptRemoteDataSourceProvider);

  void selectProject(String value) {
    _apply(state.query.copyWith(projectId: value, page: 1));
  }

  void selectSection(String value) {
    _apply(state.query.copyWith(sectionId: value, page: 1));
  }

  void selectContract(String value) {
    _apply(state.query.copyWith(contractId: value, page: 1));
  }

  void selectMaterial(String value) {
    _apply(state.query.copyWith(materialId: value, page: 1));
  }

  void selectDateRange({required String from, required String to}) {
    _apply(
      state.query.copyWith(
        deliveryDateFrom: from,
        deliveryDateTo: to,
        page: 1,
      ),
    );
  }

  void clearFilters() {
    _apply(
      state.query.copyWith(
        projectId: '',
        sectionId: '',
        contractId: '',
        materialId: '',
        deliveryDateFrom: '',
        deliveryDateTo: '',
        page: 1,
      ),
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

  void _apply(MaterialReceiptListQuery query) {
    state = state.copyWith(
      query: query,
      snapshot: state.snapshot.copyWith(
        rows: const <MaterialReceiptRow>[],
        total: 0,
      ),
      loading: true,
      clearError: true,
    );
    load();
  }

  Future<void> load({bool reloadFilters = true}) async {
    final int ticket = ++_ticket;
    final MaterialReceiptListQuery query = state.query;
    final MaterialReceiptListSnapshot previous = state.snapshot;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final MaterialReceiptListSnapshot snapshot = await _source.fetch(
        query,
        previous: previous,
        reloadFilters: reloadFilters,
      );
      if (_disposed || ticket != _ticket) {
        return;
      }
      final MaterialReceiptListQuery cleaned = _retainSelections(
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

  MaterialReceiptListQuery _retainSelections(
    MaterialReceiptListQuery query,
    MaterialReceiptListSnapshot snapshot,
  ) {
    String retain(String value, List<MaterialReceiptOption> options) {
      if (value.isEmpty) {
        return '';
      }
      return options.any(
            (MaterialReceiptOption option) => option.value == value,
          )
          ? value
          : '';
    }

    return query.copyWith(
      projectId: retain(query.projectId, snapshot.projects),
      sectionId: retain(query.sectionId, snapshot.sections),
      contractId: retain(query.contractId, snapshot.contracts),
      materialId: retain(query.materialId, snapshot.materials),
    );
  }
}
