import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_validation_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_catalog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_filter.dart';

final rfiValidationControllerProvider =
    NotifierProvider.autoDispose<RfiValidationController, RfiValidationState>(
      RfiValidationController.new,
    );

class RfiValidationState {
  const RfiValidationState({
    required this.filter,
    required this.catalog,
    required this.loading,
    required this.error,
    required this.generation,
  });

  factory RfiValidationState.initial() {
    return const RfiValidationState(
      filter: RfiValidationFilter(),
      catalog: RfiValidationCatalog(),
      loading: true,
      error: null,
      generation: 0,
    );
  }

  final RfiValidationFilter filter;
  final RfiValidationCatalog catalog;
  final bool loading;
  final Object? error;
  final int generation;

  RfiValidationState copyWith({
    RfiValidationFilter? filter,
    RfiValidationCatalog? catalog,
    bool? loading,
    Object? error = _keepError,
    bool clearError = false,
    int? generation,
  }) {
    return RfiValidationState(
      filter: filter ?? this.filter,
      catalog: catalog ?? this.catalog,
      loading: loading ?? this.loading,
      error: clearError
          ? null
          : (identical(error, _keepError) ? this.error : error),
      generation: generation ?? this.generation,
    );
  }
}

const Object _keepError = Object();

class RfiValidationController extends AutoDisposeNotifier<RfiValidationState> {
  int _ticket = 0;
  int _life = 0;
  bool _disposed = false;

  @override
  RfiValidationState build() {
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
    return RfiValidationState.initial();
  }

  RfiValidationRemoteDataSource get _source =>
      ref.read(rfiValidationRemoteDataSourceProvider);

  void clearFilters() {
    apply(const RfiValidationFilter());
  }

  void selectCategory(String? value) {
    apply(state.filter.withCategory(value ?? ''));
  }

  void selectProject(String? value) {
    apply(state.filter.withProject(value ?? ''));
  }

  void selectContract(String? value) {
    apply(state.filter.withContract(value ?? ''));
  }

  void apply(RfiValidationFilter filter) {
    state = state.copyWith(filter: filter, clearError: true);
    load();
  }

  Future<void> load() async {
    final int ticket = ++_ticket;
    final RfiValidationFilter requested = state.filter;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final RfiValidationCatalog catalog = await _source.fetch(requested);
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(
        filter: requested,
        catalog: catalog,
        loading: false,
        clearError: true,
        generation: state.generation + 1,
      );
    } on Object catch (error) {
      if (_disposed || ticket != _ticket) {
        return;
      }
      state = state.copyWith(loading: false, error: error);
    }
  }

  Future<void> submit(Map<String, String> fields) {
    return _source.validate(fields);
  }
}
