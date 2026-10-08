import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_inspection_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_catalog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_row.dart';

final rfiInspectionControllerProvider =
    NotifierProvider.autoDispose<RfiInspectionController, RfiInspectionState>(
      RfiInspectionController.new,
    );

class RfiInspectionState {
  const RfiInspectionState({
    required this.filter,
    required this.catalog,
    required this.loading,
    required this.error,
  });

  factory RfiInspectionState.initial() {
    return const RfiInspectionState(
      filter: RfiInspectionFilter(),
      catalog: RfiInspectionCatalog(),
      loading: true,
      error: null,
    );
  }

  final RfiInspectionFilter filter;
  final RfiInspectionCatalog catalog;
  final bool loading;
  final Object? error;

  RfiInspectionState copyWith({
    RfiInspectionFilter? filter,
    RfiInspectionCatalog? catalog,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return RfiInspectionState(
      filter: filter ?? this.filter,
      catalog: catalog ?? this.catalog,
      loading: loading ?? this.loading,
      error: clearError
          ? null
          : (identical(error, _keepError) ? this.error : error),
    );
  }
}

const Object _keepError = Object();

class RfiInspectionController extends AutoDisposeNotifier<RfiInspectionState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  RfiInspectionState build() {
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
    return RfiInspectionState.initial();
  }

  RfiInspectionRemoteDataSource get _source =>
      ref.read(rfiInspectionRemoteDataSourceProvider);

  void clearFilters() {
    apply(const RfiInspectionFilter());
  }

  void selectCategory(String? value) {
    apply(state.filter.withCategory(value));
  }

  void selectProject(String? value) {
    apply(state.filter.selectAt(RfiInspectionFilter.projectIndex, text: value));
  }

  void selectContract(String? value) {
    apply(
      state.filter.selectAt(RfiInspectionFilter.contractIndex, text: value),
    );
  }

  void selectStructureType(String? value) {
    apply(
      state.filter.selectAt(
        RfiInspectionFilter.structureTypeIndex,
        text: value,
      ),
    );
  }

  void selectStructure(int? value) {
    apply(
      state.filter.selectAt(RfiInspectionFilter.structureIndex, number: value),
    );
  }

  void selectItem(int? value) {
    apply(state.filter.selectAt(RfiInspectionFilter.itemIndex, number: value));
  }

  void selectMaterial(int? value) {
    apply(
      state.filter.selectAt(RfiInspectionFilter.materialIndex, number: value),
    );
  }

  void selectQuality(int? value) {
    apply(
      state.filter.selectAt(RfiInspectionFilter.qualityIndex, number: value),
    );
  }

  void apply(RfiInspectionFilter filter) {
    state = state.copyWith(filter: filter, clearError: true);
    load();
  }

  Future<void> load() async {
    final int ticket = ++_ticket;
    final RfiInspectionFilter requested = state.filter;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final RfiInspectionCatalog catalog = await _source.fetch(requested);
      if (_disposed || ticket != _ticket) {
        return;
      }
      final RfiInspectionFilter pruned = requested.retainValid(catalog);
      if (pruned != requested) {
        state = state.copyWith(filter: pruned, loading: true, clearError: true);
        await load();
        return;
      }
      state = state.copyWith(
        filter: requested,
        catalog: catalog,
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

  Future<void> refreshDetails() async {
    final int ticket = ++_ticket;
    final RfiInspectionFilter requested = state.filter;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<RfiInspectionRow> rows = await _source.fetchDetails(requested);
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(
        catalog: state.catalog.copyWithRows(rows),
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

  Future<RfiBulkSubmitResult> submitReady() {
    return _source.bulkSubmit();
  }
}
