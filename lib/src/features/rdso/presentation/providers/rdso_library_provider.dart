import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/rdso/data/datasources/rdso_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';

final rdsoLibraryControllerProvider =
    NotifierProvider.autoDispose<RdsoLibraryController, RdsoLibraryState>(
      RdsoLibraryController.new,
    );

class RdsoLibraryState {
  const RdsoLibraryState({
    required this.draft,
    required this.query,
    required this.mode,
    required this.categories,
    required this.subheadsByCategory,
    required this.subheadErrorsByCategory,
    required this.loadingSubheads,
    required this.selectedSubheadId,
    required this.selectedSubheadName,
    required this.treeDrawings,
    required this.searchSnapshot,
    required this.loading,
    required this.error,
  });

  factory RdsoLibraryState.initial() {
    return const RdsoLibraryState(
      draft: RdsoLibraryQuery(),
      query: RdsoLibraryQuery(),
      mode: RdsoLibraryListMode.tree,
      categories: <RdsoCategory>[],
      subheadsByCategory: <String, List<RdsoSubhead>>{},
      subheadErrorsByCategory: <String, Object>{},
      loadingSubheads: <String>{},
      selectedSubheadId: '',
      selectedSubheadName: '',
      treeDrawings: <RdsoDrawingRow>[],
      searchSnapshot: RdsoRevisionSnapshot.empty,
      loading: true,
      error: null,
    );
  }

  final RdsoLibraryQuery draft;
  final RdsoLibraryQuery query;
  final RdsoLibraryListMode mode;
  final List<RdsoCategory> categories;
  final Map<String, List<RdsoSubhead>> subheadsByCategory;
  final Map<String, Object> subheadErrorsByCategory;
  final Set<String> loadingSubheads;
  final String selectedSubheadId;
  final String selectedSubheadName;
  final List<RdsoDrawingRow> treeDrawings;
  final RdsoRevisionSnapshot searchSnapshot;
  final bool loading;
  final Object? error;

  List<RdsoDrawingRow> get visibleDrawings {
    if (mode != RdsoLibraryListMode.search) {
      return treeDrawings;
    }
    final List<RdsoDrawingRow> all = searchSnapshot.items;
    if (!query.usesDrawingSearchEndpoint) {
      return all;
    }
    final int pageSize = query.size < 1
        ? RdsoRevisionQuery.defaultSize
        : query.size;
    final int page = query.page < 1 ? 1 : query.page;
    final int start = (page - 1) * pageSize;
    if (start >= all.length) {
      return const <RdsoDrawingRow>[];
    }
    return all.sublist(start, math.min(start + pageSize, all.length));
  }

  int get total {
    if (mode != RdsoLibraryListMode.search) {
      return treeDrawings.length;
    }
    if (query.usesDrawingSearchEndpoint) {
      return searchSnapshot.items.length;
    }
    return searchSnapshot.total;
  }

  RdsoLibraryState copyWith({
    RdsoLibraryQuery? draft,
    RdsoLibraryQuery? query,
    RdsoLibraryListMode? mode,
    List<RdsoCategory>? categories,
    Map<String, List<RdsoSubhead>>? subheadsByCategory,
    Map<String, Object>? subheadErrorsByCategory,
    Set<String>? loadingSubheads,
    String? selectedSubheadId,
    String? selectedSubheadName,
    List<RdsoDrawingRow>? treeDrawings,
    RdsoRevisionSnapshot? searchSnapshot,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return RdsoLibraryState(
      draft: draft ?? this.draft,
      query: query ?? this.query,
      mode: mode ?? this.mode,
      categories: categories ?? this.categories,
      subheadsByCategory: subheadsByCategory ?? this.subheadsByCategory,
      subheadErrorsByCategory:
          subheadErrorsByCategory ?? this.subheadErrorsByCategory,
      loadingSubheads: loadingSubheads ?? this.loadingSubheads,
      selectedSubheadId: selectedSubheadId ?? this.selectedSubheadId,
      selectedSubheadName: selectedSubheadName ?? this.selectedSubheadName,
      treeDrawings: treeDrawings ?? this.treeDrawings,
      searchSnapshot: searchSnapshot ?? this.searchSnapshot,
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

class RdsoLibraryController extends AutoDisposeNotifier<RdsoLibraryState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  RdsoLibraryState build() {
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
      loadCategories();
    });
    return RdsoLibraryState.initial();
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

  Future<void> loadCategories() async {
    final int ticket = ++_ticket;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<RdsoCategory> categories = await _source.fetchCategories();
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(
        categories: categories,
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

  Future<void> loadSubheads(String categoryId) async {
    final String id = categoryId.trim();
    if (id.isEmpty) {
      return;
    }
    final List<RdsoSubhead>? cached = state.subheadsByCategory[id];
    if (cached != null && cached.isNotEmpty) {
      return;
    }
    if (state.loadingSubheads.contains(id)) {
      return;
    }
    final Set<String> loading = Set<String>.from(state.loadingSubheads)..add(id);
    final Map<String, Object> errors =
        Map<String, Object>.from(state.subheadErrorsByCategory)..remove(id);
    state = state.copyWith(
      loadingSubheads: loading,
      subheadErrorsByCategory: errors,
      clearError: true,
    );
    try {
      final List<RdsoSubhead> subheads = await _source.fetchSubheads(id);
      if (_disposed) {
        return;
      }
      final Set<String> done = Set<String>.from(state.loadingSubheads)..remove(id);
      final Map<String, List<RdsoSubhead>> map =
          Map<String, List<RdsoSubhead>>.from(state.subheadsByCategory);
      map[id] = subheads;
      state = state.copyWith(
        subheadsByCategory: map,
        loadingSubheads: done,
        clearError: true,
      );
    } on Object catch (error) {
      if (_disposed) {
        return;
      }
      final Set<String> done = Set<String>.from(state.loadingSubheads)..remove(id);
      final Map<String, Object> errMap =
          Map<String, Object>.from(state.subheadErrorsByCategory);
      errMap[id] = error;
      state = state.copyWith(
        loadingSubheads: done,
        subheadErrorsByCategory: errMap,
        error: error,
      );
    }
  }

  Future<void> selectSubhead(RdsoSubhead subhead) async {
    final int ticket = ++_ticket;
    state = state.copyWith(
      mode: RdsoLibraryListMode.tree,
      selectedSubheadId: subhead.id,
      selectedSubheadName: subhead.name,
      treeDrawings: const <RdsoDrawingRow>[],
      loading: true,
      clearError: true,
    );
    try {
      final List<RdsoDrawingRow> rows = await _source.fetchSubheadDrawings(
        subhead.id,
      );
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(
        treeDrawings: rows,
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

  void applySearch() {
    final RdsoLibraryQuery next = state.draft.copyWith(
      q: state.draft.q.trim(),
      page: 1,
      size: state.query.size,
    );
    state = state.copyWith(
      draft: next,
      query: next,
      mode: RdsoLibraryListMode.search,
      selectedSubheadId: '',
      selectedSubheadName: '',
      treeDrawings: const <RdsoDrawingRow>[],
      searchSnapshot: state.searchSnapshot.copyWith(
        items: const <RdsoDrawingRow>[],
        total: 0,
      ),
      loading: true,
      clearError: true,
    );
    _loadSearch();
  }

  void resetFilters() {
    final RdsoLibraryQuery next = RdsoLibraryQuery(size: state.query.size);
    state = state.copyWith(
      draft: next,
      query: next,
      mode: RdsoLibraryListMode.tree,
      selectedSubheadId: '',
      selectedSubheadName: '',
      treeDrawings: const <RdsoDrawingRow>[],
      searchSnapshot: RdsoRevisionSnapshot.empty,
      loading: false,
      clearError: true,
    );
  }

  void setPage(int page) {
    if (state.mode != RdsoLibraryListMode.search ||
        page < 1 ||
        page == state.query.page) {
      return;
    }
    state = state.copyWith(
      query: state.query.copyWith(page: page),
      clearError: true,
    );
    if (!state.query.usesDrawingSearchEndpoint) {
      state = state.copyWith(loading: true);
      _loadSearch();
    }
  }

  void setPageSize(int size) {
    if (state.mode != RdsoLibraryListMode.search ||
        size < 1 ||
        size == state.query.size) {
      return;
    }
    final RdsoLibraryQuery next = state.query.copyWith(size: size, page: 1);
    state = state.copyWith(
      draft: state.draft.copyWith(size: size),
      query: next,
      clearError: true,
    );
    if (!state.query.usesDrawingSearchEndpoint) {
      state = state.copyWith(loading: true);
      _loadSearch();
    }
  }

  Future<void> retrySearch() {
    if (state.mode != RdsoLibraryListMode.search) {
      return loadCategories();
    }
    state = state.copyWith(loading: true, clearError: true);
    return _loadSearch();
  }

  Future<void> _loadSearch() async {
    final int ticket = ++_ticket;
    final RdsoLibraryQuery query = state.query;
    state = state.copyWith(loading: true, clearError: true);
    try {
      if (!query.hasSearchFilters) {
        if (_disposed || ticket != _ticket) {
          return;
        }
        state = state.copyWith(
          searchSnapshot: RdsoRevisionSnapshot.empty,
          loading: false,
          clearError: true,
        );
        return;
      }

      final Future<RdsoRevisionSnapshot> registerFuture =
          query.usesDrawingSearchEndpoint
          ? _source.fetchDrawingSearch(query)
          : _source.fetchLibraryRegister(query);

      final List<Object> results = await Future.wait<Object>(
        <Future<Object>>[
          state.categories.isEmpty
              ? _source.fetchCategories()
              : Future<Object>.value(state.categories),
          registerFuture,
        ],
      );
      if (_disposed || ticket != _ticket) {
        return;
      }
      final List<RdsoCategory> categories =
          results[0] as List<RdsoCategory>;
      final RdsoRevisionSnapshot register = results[1] as RdsoRevisionSnapshot;
      final RdsoLibraryQuery cleaned = _retainCategory(query, categories);
      state = state.copyWith(
        categories: categories,
        draft: state.draft.copyWith(categoryId: cleaned.categoryId),
        query: cleaned,
        searchSnapshot: register.copyWith(categories: categories),
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

  RdsoLibraryQuery _retainCategory(
    RdsoLibraryQuery query,
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
