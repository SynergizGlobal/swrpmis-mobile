import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/structures/data/datasources/structure_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/structures/domain/structure_list.dart';

final structuresControllerProvider =
    NotifierProvider.autoDispose<StructuresController, StructuresState>(
      StructuresController.new,
    );

class StructuresState {
  const StructuresState({
    required this.query,
    required this.snapshot,
    required this.loading,
    required this.error,
  });

  factory StructuresState.initial() {
    return const StructuresState(
      query: StructureListQuery(),
      snapshot: StructureListSnapshot.empty,
      loading: true,
      error: null,
    );
  }

  final StructureListQuery query;
  final StructureListSnapshot snapshot;
  final bool loading;
  final Object? error;

  StructuresState copyWith({
    StructureListQuery? query,
    StructureListSnapshot? snapshot,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return StructuresState(
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

class StructuresController extends AutoDisposeNotifier<StructuresState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  StructuresState build() {
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
    return StructuresState.initial();
  }

  StructureRemoteDataSource get _source =>
      ref.read(structureRemoteDataSourceProvider);

  void selectProject(String value) {
    state = state.copyWith(
      query: state.query.copyWith(projectId: value),
      clearError: true,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      query: state.query.copyWith(projectId: ''),
      clearError: true,
    );
  }

  void setSearch(String value) {
    final String search = value.trim();
    if (search == state.query.search) {
      return;
    }
    state = state.copyWith(
      query: state.query.copyWith(search: search),
      clearError: true,
    );
  }

  Future<void> load() async {
    final int ticket = ++_ticket;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final StructureListSnapshot snapshot = await _source.fetchSummaries();
      if (_disposed || ticket != _ticket) {
        return;
      }
      final String selected = state.query.projectId.trim();
      final bool keep = selected.isEmpty ||
          snapshot.projects.any(
            (StructureOption option) => option.value == selected,
          ) ||
          snapshot.rows.any(
            (StructureSummaryRow row) => row.projectId == selected,
          );
      state = state.copyWith(
        query: keep
            ? state.query
            : state.query.copyWith(projectId: ''),
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
}
