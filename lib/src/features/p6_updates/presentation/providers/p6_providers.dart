import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/data/datasources/p6_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/domain/p6_list.dart';

final p6HistoryControllerProvider =
    NotifierProvider.autoDispose<P6HistoryController, P6HistoryState>(
      P6HistoryController.new,
    );

final p6NewDataControllerProvider =
    NotifierProvider.autoDispose<P6NewDataController, P6NewDataState>(
      P6NewDataController.new,
    );

class P6HistoryState {
  const P6HistoryState({
    required this.query,
    required this.snapshot,
    required this.loading,
    required this.error,
  });

  factory P6HistoryState.initial() {
    return const P6HistoryState(
      query: P6HistoryQuery(),
      snapshot: P6HistorySnapshot.empty,
      loading: true,
      error: null,
    );
  }

  final P6HistoryQuery query;
  final P6HistorySnapshot snapshot;
  final bool loading;
  final Object? error;

  P6HistoryState copyWith({
    P6HistoryQuery? query,
    P6HistorySnapshot? snapshot,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
  }) {
    return P6HistoryState(
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

class P6NewDataState {
  const P6NewDataState({
    required this.master,
    required this.loading,
    required this.error,
    required this.contractsByKind,
    required this.loadingContractsByKind,
  });

  factory P6NewDataState.initial() {
    return const P6NewDataState(
      master: P6FormMaster.empty,
      loading: true,
      error: null,
      contractsByKind: <P6UploadKind, List<P6Option>>{},
      loadingContractsByKind: <P6UploadKind, bool>{},
    );
  }

  final P6FormMaster master;
  final bool loading;
  final Object? error;
  final Map<P6UploadKind, List<P6Option>> contractsByKind;
  final Map<P6UploadKind, bool> loadingContractsByKind;

  List<P6Option> contractsFor(P6UploadKind kind) {
    return contractsByKind[kind] ?? const <P6Option>[];
  }

  bool isLoadingContracts(P6UploadKind kind) {
    return loadingContractsByKind[kind] ?? false;
  }

  P6NewDataState copyWith({
    P6FormMaster? master,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
    Map<P6UploadKind, List<P6Option>>? contractsByKind,
    Map<P6UploadKind, bool>? loadingContractsByKind,
  }) {
    return P6NewDataState(
      master: master ?? this.master,
      loading: loading ?? this.loading,
      error: clearError
          ? null
          : identical(error, _keepError)
          ? this.error
          : error,
      contractsByKind: contractsByKind ?? this.contractsByKind,
      loadingContractsByKind:
          loadingContractsByKind ?? this.loadingContractsByKind,
    );
  }
}

const Object _keepError = Object();

class P6HistoryController extends AutoDisposeNotifier<P6HistoryState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  P6HistoryState build() {
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
    return P6HistoryState.initial();
  }

  P6RemoteDataSource get _source => ref.read(p6RemoteDataSourceProvider);

  void selectContract(String value) {
    _apply(
      state.query.copyWith(contractId: value),
      P6HistoryFilterField.contract,
    );
  }

  void selectUploadType(String value) {
    _apply(
      state.query.copyWith(uploadType: value),
      P6HistoryFilterField.uploadType,
    );
  }

  void selectStatus(String value) {
    _apply(state.query.copyWith(status: value), P6HistoryFilterField.status);
  }

  void clearFilters() {
    _apply(const P6HistoryQuery(), null);
  }

  void _apply(P6HistoryQuery query, P6HistoryFilterField? changed) {
    state = state.copyWith(
      query: query,
      snapshot: state.snapshot.copyWith(rows: const <P6HistoryRow>[]),
      loading: true,
      clearError: true,
    );
    load(changed: changed);
  }

  Future<void> load({P6HistoryFilterField? changed}) async {
    final int ticket = ++_ticket;
    final P6HistoryQuery query = state.query;
    final P6HistorySnapshot previous = state.snapshot;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final P6HistorySnapshot snapshot = await _source.fetchHistory(
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

class P6NewDataController extends AutoDisposeNotifier<P6NewDataState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;
  final Map<P6UploadKind, int> _contractTickets = <P6UploadKind, int>{};

  @override
  P6NewDataState build() {
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
    return P6NewDataState.initial();
  }

  P6RemoteDataSource get _source => ref.read(p6RemoteDataSourceProvider);

  Future<void> load() async {
    final int ticket = ++_ticket;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final P6FormMaster master = await _source.fetchFormMaster();
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(
        master: master,
        loading: false,
        clearError: true,
        contractsByKind: const <P6UploadKind, List<P6Option>>{},
        loadingContractsByKind: const <P6UploadKind, bool>{},
      );
    } on Object catch (error) {
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(loading: false, error: error);
    }
  }

  Future<void> loadContractsForProject({
    required P6UploadKind kind,
    required String projectId,
  }) async {
    final String id = projectId.trim();
    final int ticket = (_contractTickets[kind] ?? 0) + 1;
    _contractTickets[kind] = ticket;
    final Map<P6UploadKind, List<P6Option>> contracts =
        Map<P6UploadKind, List<P6Option>>.from(state.contractsByKind);
    final Map<P6UploadKind, bool> loading =
        Map<P6UploadKind, bool>.from(state.loadingContractsByKind);
    contracts[kind] = const <P6Option>[];
    loading[kind] = id.isNotEmpty;
    state = state.copyWith(
      contractsByKind: contracts,
      loadingContractsByKind: loading,
      clearError: true,
    );
    if (id.isEmpty) {
      loading[kind] = false;
      state = state.copyWith(loadingContractsByKind: loading);
      return;
    }
    try {
      final List<P6Option> options = await _source.fetchContractsForProject(id);
      if (_disposed || _contractTickets[kind] != ticket) {
        return;
      }
      contracts[kind] = options;
      loading[kind] = false;
      state = state.copyWith(
        contractsByKind: Map<P6UploadKind, List<P6Option>>.from(contracts),
        loadingContractsByKind: Map<P6UploadKind, bool>.from(loading),
      );
    } on Object catch (error) {
      if (_disposed || _contractTickets[kind] != ticket) {
        return;
      }
      loading[kind] = false;
      state = state.copyWith(
        loadingContractsByKind: Map<P6UploadKind, bool>.from(loading),
        error: error,
      );
    }
  }

  Future<String> upload({
    required P6UploadKind kind,
    required String projectId,
    required String contractId,
    required String dataDateIso,
    required String filePath,
  }) {
    return _source.uploadP6NewData(
      projectId: projectId,
      contractId: contractId,
      dataDateIso: dataDateIso,
      filePath: filePath,
      uploadType: kind.uploadType,
    );
  }
}
