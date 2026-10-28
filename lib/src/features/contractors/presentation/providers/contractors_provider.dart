import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/contractors/data/datasources/contractor_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/contractors/domain/contractor_list.dart';

final contractorsControllerProvider =
    NotifierProvider.autoDispose<ContractorsController, ContractorsState>(
      ContractorsController.new,
    );

class ContractorsState {
  const ContractorsState({
    required this.query,
    required this.snapshot,
    required this.loading,
    required this.error,
  });

  factory ContractorsState.initial() {
    return const ContractorsState(
      query: ContractorListQuery(),
      snapshot: ContractorListSnapshot.empty,
      loading: true,
      error: null,
    );
  }

  final ContractorListQuery query;
  final ContractorListSnapshot snapshot;
  final bool loading;
  final Object? error;

  ContractorsState copyWith({
    ContractorListQuery? query,
    ContractorListSnapshot? snapshot,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return ContractorsState(
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

class ContractorsController extends AutoDisposeNotifier<ContractorsState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  ContractorsState build() {
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
    return ContractorsState.initial();
  }

  ContractorRemoteDataSource get _source =>
      ref.read(contractorRemoteDataSourceProvider);

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
      final ContractorListSnapshot snapshot = await _source.fetchList();
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
