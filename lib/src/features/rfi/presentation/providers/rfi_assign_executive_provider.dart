import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_assign_executive_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_assign_executive.dart';

final rfiAssignFormControllerProvider =
    NotifierProvider.autoDispose<RfiAssignFormController, RfiAssignFormState>(
      RfiAssignFormController.new,
    );

final rfiAssignLogControllerProvider =
    NotifierProvider.autoDispose<RfiAssignLogController, RfiAssignLogState>(
      RfiAssignLogController.new,
    );

class RfiAssignFormState {
  const RfiAssignFormState({
    this.projects = const <RfiAssignProject>[],
    this.contracts = const <RfiAssignContract>[],
    this.projectId,
    this.contractId,
    this.loadingProjects = true,
    this.loadingContracts = false,
    this.projectError,
    this.contractError,
  });

  final List<RfiAssignProject> projects;
  final List<RfiAssignContract> contracts;
  final String? projectId;
  final String? contractId;
  final bool loadingProjects;
  final bool loadingContracts;
  final Object? projectError;
  final Object? contractError;

  RfiAssignFormState copyWith({
    List<RfiAssignProject>? projects,
    List<RfiAssignContract>? contracts,
    Object? projectId = _keep,
    Object? contractId = _keep,
    bool? loadingProjects,
    bool? loadingContracts,
    Object? projectError = _keep,
    Object? contractError = _keep,
    bool clearProjectError = false,
    bool clearContractError = false,
  }) {
    return RfiAssignFormState(
      projects: projects ?? this.projects,
      contracts: contracts ?? this.contracts,
      projectId: identical(projectId, _keep)
          ? this.projectId
          : projectId as String?,
      contractId: identical(contractId, _keep)
          ? this.contractId
          : contractId as String?,
      loadingProjects: loadingProjects ?? this.loadingProjects,
      loadingContracts: loadingContracts ?? this.loadingContracts,
      projectError: clearProjectError
          ? null
          : (identical(projectError, _keep) ? this.projectError : projectError),
      contractError: clearContractError
          ? null
          : (identical(contractError, _keep)
                ? this.contractError
                : contractError),
    );
  }
}

class RfiAssignLogState {
  const RfiAssignLogState({
    this.rows = const <RfiAssignExecutiveLog>[],
    this.loading = true,
    this.error,
  });

  final List<RfiAssignExecutiveLog> rows;
  final bool loading;
  final Object? error;

  RfiAssignLogState copyWith({
    List<RfiAssignExecutiveLog>? rows,
    bool? loading,
    Object? error = _keep,
    bool clearError = false,
  }) {
    return RfiAssignLogState(
      rows: rows ?? this.rows,
      loading: loading ?? this.loading,
      error: clearError ? null : (identical(error, _keep) ? this.error : error),
    );
  }
}

const Object _keep = Object();

class RfiAssignFormController extends AutoDisposeNotifier<RfiAssignFormState> {
  int _life = 0;
  bool _disposed = false;
  int _contractTicket = 0;

  @override
  RfiAssignFormState build() {
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
      loadProjects();
    });
    return const RfiAssignFormState();
  }

  Future<void> refresh() async {
    await loadProjects();
    if (_disposed || state.projectError != null) {
      return;
    }
    final String? projectId = state.projectId;
    if (projectId == null) {
      return;
    }
    final bool stillListed = state.projects.any(
      (RfiAssignProject project) => project.projectId == projectId,
    );
    if (!stillListed) {
      state = state.copyWith(
        projectId: null,
        contractId: null,
        contracts: const <RfiAssignContract>[],
        loadingContracts: false,
        clearContractError: true,
      );
      return;
    }
    await reloadContracts(keepSelection: true);
  }

  Future<void> loadProjects() async {
    state = state.copyWith(loadingProjects: true, clearProjectError: true);
    try {
      final List<RfiAssignProject> projects = await ref
          .read(rfiAssignExecutiveRemoteDataSourceProvider)
          .fetchProjects();
      if (_disposed) {
        return;
      }
      state = state.copyWith(projects: projects, loadingProjects: false);
    } on Object catch (error) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(loadingProjects: false, projectError: error);
    }
  }

  Future<void> selectProject(String? projectId) async {
    if (projectId == state.projectId) {
      return;
    }
    final int ticket = ++_contractTicket;
    state = state.copyWith(
      projectId: projectId,
      contractId: null,
      contracts: const <RfiAssignContract>[],
      loadingContracts: projectId != null && projectId.isNotEmpty,
      clearContractError: true,
    );
    if (projectId == null || projectId.isEmpty) {
      return;
    }
    await _loadContracts(projectId, ticket, keepSelection: false);
  }

  Future<void> reloadContracts({required bool keepSelection}) async {
    final String? projectId = state.projectId;
    if (projectId == null || projectId.isEmpty) {
      return;
    }
    final int ticket = ++_contractTicket;
    state = state.copyWith(loadingContracts: true, clearContractError: true);
    await _loadContracts(projectId, ticket, keepSelection: keepSelection);
  }

  void selectContract(String? contractId) {
    state = state.copyWith(contractId: contractId);
  }

  Future<void> _loadContracts(
    String projectId,
    int ticket, {
    required bool keepSelection,
  }) async {
    final String? previous = keepSelection ? state.contractId : null;
    try {
      final List<RfiAssignContract> contracts = await ref
          .read(rfiAssignExecutiveRemoteDataSourceProvider)
          .fetchContracts(projectId);
      if (_disposed || ticket != _contractTicket) {
        return;
      }
      final bool keep =
          previous != null &&
          contracts.any(
            (RfiAssignContract contract) => contract.contractIdFk == previous,
          );
      state = state.copyWith(
        contracts: contracts,
        contractId: keep ? previous : null,
        loadingContracts: false,
        clearContractError: true,
      );
    } on Object catch (error) {
      if (_disposed || ticket != _contractTicket) {
        return;
      }
      state = state.copyWith(
        contracts: const <RfiAssignContract>[],
        contractId: null,
        loadingContracts: false,
        contractError: error,
      );
    }
  }
}

class RfiAssignLogController extends AutoDisposeNotifier<RfiAssignLogState> {
  int _life = 0;
  bool _disposed = false;
  int _ticket = 0;

  @override
  RfiAssignLogState build() {
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
    return const RfiAssignLogState();
  }

  Future<void> load() async {
    final int ticket = ++_ticket;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<RfiAssignExecutiveLog> rows = await ref
          .read(rfiAssignExecutiveRemoteDataSourceProvider)
          .fetchLogs();
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(rows: rows, loading: false, clearError: true);
    } on Object catch (error) {
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(loading: false, error: error);
    }
  }

  Future<void> deleteAssignment(int id) {
    return ref
        .read(rfiAssignExecutiveRemoteDataSourceProvider)
        .deleteAssignment(id);
  }
}
