import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/issues/data/datasources/issue_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/issues/domain/issue_list.dart';

final issuesControllerProvider =
    NotifierProvider.autoDispose<IssuesController, IssuesState>(
      IssuesController.new,
    );

class IssuesState {
  const IssuesState({
    required this.query,
    required this.snapshot,
    required this.loading,
    required this.error,
  });

  factory IssuesState.initial() {
    return const IssuesState(
      query: IssueListQuery(),
      snapshot: IssueListSnapshot.empty,
      loading: true,
      error: null,
    );
  }

  final IssueListQuery query;
  final IssueListSnapshot snapshot;
  final bool loading;
  final Object? error;

  IssuesState copyWith({
    IssueListQuery? query,
    IssueListSnapshot? snapshot,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return IssuesState(
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

class IssuesController extends AutoDisposeNotifier<IssuesState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  IssuesState build() {
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
    return IssuesState.initial();
  }

  IssueRemoteDataSource get _source => ref.read(issueRemoteDataSourceProvider);

  void selectContract(String value) {
    _apply(state.query.copyWith(contractId: value), IssueFilterField.contract);
  }

  void selectHod(String value) {
    _apply(state.query.copyWith(hodId: value), IssueFilterField.hod);
  }

  void selectDepartment(String value) {
    _apply(
      state.query.copyWith(departmentId: value),
      IssueFilterField.department,
    );
  }

  void selectCategory(String value) {
    _apply(state.query.copyWith(categoryId: value), IssueFilterField.category);
  }

  void selectStatus(String value) {
    _apply(state.query.copyWith(statusId: value), IssueFilterField.status);
  }

  void clearFilters() {
    _apply(const IssueListQuery(), null);
  }

  void _apply(IssueListQuery query, IssueFilterField? changed) {
    state = state.copyWith(
      query: query,
      snapshot: state.snapshot.copyWith(issues: const <IssueRow>[]),
      loading: true,
      clearError: true,
    );
    load(changed: changed);
  }

  Future<void> load({IssueFilterField? changed}) async {
    final int ticket = ++_ticket;
    final IssueListQuery query = state.query;
    final IssueListSnapshot previous = state.snapshot;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final IssueListSnapshot snapshot = await _source.fetch(
        query,
        changed: changed,
        previous: previous,
      );
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(
        query: query,
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
