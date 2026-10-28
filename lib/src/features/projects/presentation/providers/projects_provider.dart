import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/projects/data/datasources/project_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/projects/domain/project_list.dart';

final projectsControllerProvider =
    NotifierProvider.autoDispose<ProjectsController, ProjectsState>(
      ProjectsController.new,
    );

class ProjectsState {
  const ProjectsState({
    required this.query,
    required this.snapshot,
    required this.loading,
    required this.error,
  });

  factory ProjectsState.initial() {
    return const ProjectsState(
      query: ProjectListQuery(),
      snapshot: ProjectListSnapshot.empty,
      loading: true,
      error: null,
    );
  }

  final ProjectListQuery query;
  final ProjectListSnapshot snapshot;
  final bool loading;
  final Object? error;

  ProjectsState copyWith({
    ProjectListQuery? query,
    ProjectListSnapshot? snapshot,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return ProjectsState(
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

class ProjectsController extends AutoDisposeNotifier<ProjectsState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  ProjectsState build() {
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
    return ProjectsState.initial();
  }

  ProjectRemoteDataSource get _source =>
      ref.read(projectRemoteDataSourceProvider);

  void selectStatus(String value) {
    state = state.copyWith(
      query: state.query.copyWith(projectStatus: value),
      clearError: true,
    );
  }

  void selectType(String value) {
    state = state.copyWith(
      query: state.query.copyWith(projectTypeId: value),
      clearError: true,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      query: state.query.copyWith(projectStatus: '', projectTypeId: ''),
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
      final ProjectListSnapshot snapshot = await _source.fetchList();
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(snapshot: snapshot, loading: false);
    } on Object catch (error) {
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(loading: false, error: error);
    }
  }
}
