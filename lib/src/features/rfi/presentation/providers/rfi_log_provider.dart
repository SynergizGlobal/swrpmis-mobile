import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_inspection_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_log_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_catalog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_log_row.dart';

final rfiLogControllerProvider =
    NotifierProvider.autoDispose<RfiLogController, RfiLogState>(
      RfiLogController.new,
    );

class RfiLogState {
  const RfiLogState({
    required this.filter,
    required this.catalog,
    required this.rows,
    required this.loading,
    required this.error,
  });

  factory RfiLogState.initial() {
    return const RfiLogState(
      filter: RfiInspectionFilter(),
      catalog: RfiInspectionCatalog(),
      rows: <RfiLogRow>[],
      loading: true,
      error: null,
    );
  }

  final RfiInspectionFilter filter;
  final RfiInspectionCatalog catalog;
  final List<RfiLogRow> rows;
  final bool loading;
  final Object? error;

  RfiLogState copyWith({
    RfiInspectionFilter? filter,
    RfiInspectionCatalog? catalog,
    List<RfiLogRow>? rows,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return RfiLogState(
      filter: filter ?? this.filter,
      catalog: catalog ?? this.catalog,
      rows: rows ?? this.rows,
      loading: loading ?? this.loading,
      error: clearError
          ? null
          : (identical(error, _keepError) ? this.error : error),
    );
  }
}

const Object _keepError = Object();

class RfiLogController extends AutoDisposeNotifier<RfiLogState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  RfiLogState build() {
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
    return RfiLogState.initial();
  }

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
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        ref.read(rfiInspectionRemoteDataSourceProvider).fetchFilters(requested),
        ref.read(rfiLogRemoteDataSourceProvider).fetchRows(requested),
      ]);
      if (_disposed || ticket != _ticket) {
        return;
      }
      final RfiInspectionCatalog catalog = results[0] as RfiInspectionCatalog;
      final List<RfiLogRow> rows = results[1] as List<RfiLogRow>;
      final RfiInspectionFilter pruned = requested.retainValid(catalog);
      if (pruned != requested) {
        state = state.copyWith(filter: pruned, loading: true, clearError: true);
        await load();
        return;
      }
      state = state.copyWith(
        filter: requested,
        catalog: catalog,
        rows: rows,
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
}
