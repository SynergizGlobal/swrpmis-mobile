import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/rdso/data/datasources/rdso_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';

final rdsoDrawingDetailProvider = NotifierProvider.autoDispose
    .family<RdsoDrawingDetailController, RdsoDrawingDetailState, RdsoDrawingRow>(
      RdsoDrawingDetailController.new,
    );

class RdsoDrawingDetailState {
  const RdsoDrawingDetailState({
    required this.drawing,
    required this.files,
    required this.posts,
    required this.loading,
    required this.posting,
    required this.error,
  });

  factory RdsoDrawingDetailState.initial(RdsoDrawingRow drawing) {
    return RdsoDrawingDetailState(
      drawing: drawing,
      files: const <RdsoDrawingFile>[],
      posts: const <RdsoPost>[],
      loading: true,
      posting: false,
      error: null,
    );
  }

  final RdsoDrawingRow drawing;
  final List<RdsoDrawingFile> files;
  final List<RdsoPost> posts;
  final bool loading;
  final bool posting;
  final Object? error;

  RdsoDrawingDetailState copyWith({
    List<RdsoDrawingFile>? files,
    List<RdsoPost>? posts,
    bool? loading,
    bool? posting,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return RdsoDrawingDetailState(
      drawing: drawing,
      files: files ?? this.files,
      posts: posts ?? this.posts,
      loading: loading ?? this.loading,
      posting: posting ?? this.posting,
      error: clearError
          ? null
          : identical(error, _keepError)
          ? this.error
          : error,
    );
  }
}

const Object _keepError = Object();

class RdsoDrawingDetailController
    extends AutoDisposeFamilyNotifier<RdsoDrawingDetailState, RdsoDrawingRow> {
  int _ticket = 0;
  bool _disposed = false;

  @override
  RdsoDrawingDetailState build(RdsoDrawingRow drawing) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    Future<void>.microtask(load);
    return RdsoDrawingDetailState.initial(drawing);
  }

  RdsoDrawingRow get _drawing => arg;

  RdsoRemoteDataSource get _source => ref.read(rdsoRemoteDataSourceProvider);

  Future<void> load() async {
    final int ticket = ++_ticket;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<Object> results = await Future.wait<Object>(
        <Future<Object>>[
          _source.fetchDrawingFiles(_drawing.id),
          _source.fetchDrawingPosts(_drawing.id),
        ],
      );
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(
        files: results[0] as List<RdsoDrawingFile>,
        posts: results[1] as List<RdsoPost>,
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

  Future<void> submitPost({
    required String postType,
    required String content,
  }) async {
    final String trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }
    state = state.copyWith(posting: true, clearError: true);
    try {
      await _source.createPost(
        drawingId: _drawing.id,
        postType: postType,
        content: trimmed,
      );
      final List<RdsoPost> posts = await _source.fetchDrawingPosts(_drawing.id);
      if (_disposed) {
        return;
      }
      state = state.copyWith(posts: posts, posting: false, clearError: true);
    } on Object catch (error) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(posting: false, error: error);
      rethrow;
    }
  }
}
