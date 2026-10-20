import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/rdso/data/datasources/rdso_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';

final rdsoRevisionControllerProvider =
    NotifierProvider.autoDispose<RdsoRevisionController, RdsoRevisionState>(
      RdsoRevisionController.new,
    );

class RdsoRevisionState {
  const RdsoRevisionState({
    required this.draft,
    required this.query,
    required this.snapshot,
    required this.loading,
    required this.error,
  });

  factory RdsoRevisionState.initial() {
    return const RdsoRevisionState(
      draft: RdsoRevisionQuery(),
      query: RdsoRevisionQuery(),
      snapshot: RdsoRevisionSnapshot.empty,
      loading: true,
      error: null,
    );
  }

  final RdsoRevisionQuery draft;
  final RdsoRevisionQuery query;
  final RdsoRevisionSnapshot snapshot;
  final bool loading;
  final Object? error;

  RdsoRevisionState copyWith({
    RdsoRevisionQuery? draft,
    RdsoRevisionQuery? query,
    RdsoRevisionSnapshot? snapshot,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return RdsoRevisionState(
      draft: draft ?? this.draft,
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

class RdsoRevisionController extends AutoDisposeNotifier<RdsoRevisionState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  RdsoRevisionState build() {
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
      load(reloadCategories: true);
    });
    return RdsoRevisionState.initial();
  }

  RdsoRemoteDataSource get _source => ref.read(rdsoRemoteDataSourceProvider);

  void setDraftSearch(String value) {
    state = state.copyWith(draft: state.draft.copyWith(q: value));
  }

  void setDraftCategory(String value) {
    state = state.copyWith(draft: state.draft.copyWith(categoryId: value));
  }

  void setDraftStatus(String value) {
    state = state.copyWith(draft: state.draft.copyWith(status: value));
  }

  void setDraftDate(String value) {
    state = state.copyWith(draft: state.draft.copyWith(date: value));
  }

  void applySearch() {
    final RdsoRevisionQuery next = state.draft.copyWith(
      q: state.draft.q.trim(),
      page: 1,
      size: state.query.size,
    );
    state = state.copyWith(
      draft: next,
      query: next,
      snapshot: state.snapshot.copyWith(
        items: const <RdsoDrawingRow>[],
        total: 0,
      ),
      loading: true,
      clearError: true,
    );
    load(reloadCategories: false);
  }

  void resetFilters() {
    final RdsoRevisionQuery next = RdsoRevisionQuery(size: state.query.size);
    state = state.copyWith(
      draft: next,
      query: next,
      snapshot: state.snapshot.copyWith(
        items: const <RdsoDrawingRow>[],
        total: 0,
      ),
      loading: true,
      clearError: true,
    );
    load(reloadCategories: false);
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
    load(reloadCategories: false);
  }

  void setPageSize(int size) {
    if (size < 1 || size == state.query.size) {
      return;
    }
    final RdsoRevisionQuery next = state.query.copyWith(size: size, page: 1);
    state = state.copyWith(
      draft: state.draft.copyWith(size: size),
      query: next,
      loading: true,
      clearError: true,
    );
    load(reloadCategories: false);
  }

  Future<void> load({bool reloadCategories = true}) async {
    final int ticket = ++_ticket;
    final RdsoRevisionQuery query = state.query;
    final List<RdsoCategory> previousCategories = state.snapshot.categories;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<Object> results = await Future.wait<Object>(
        <Future<Object>>[
          if (reloadCategories || previousCategories.isEmpty)
            _source.fetchCategories()
          else
            Future<Object>.value(previousCategories),
          _source.fetchRegister(query),
        ],
      );
      if (_disposed || ticket != _ticket) {
        return;
      }
      final List<RdsoCategory> categories =
          results[0] as List<RdsoCategory>;
      final RdsoRevisionSnapshot register = results[1] as RdsoRevisionSnapshot;
      final RdsoRevisionQuery cleaned = _retainCategory(query, categories);
      state = state.copyWith(
        draft: state.draft.copyWith(categoryId: cleaned.categoryId),
        query: cleaned,
        snapshot: register.copyWith(categories: categories),
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

  RdsoRevisionQuery _retainCategory(
    RdsoRevisionQuery query,
    List<RdsoCategory> categories,
  ) {
    final String id = query.categoryId.trim();
    if (id.isEmpty) {
      return query;
    }
    final bool ok = categories.any((RdsoCategory c) => c.id == id);
    return ok ? query : query.copyWith(categoryId: '');
  }
}
