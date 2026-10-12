import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/features/rfi/data/datasources/rfi_reference_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_reference.dart';

final rfiReferenceControllerProvider =
    NotifierProvider.autoDispose<RfiReferenceController, RfiReferenceState>(
      RfiReferenceController.new,
    );

class RfiReferenceState {
  const RfiReferenceState({
    this.form,
    this.loading = false,
    this.error,
    this.enclosures = const <RfiEnclosure>[],
    this.subOptions = const <RfiEnclosure>[],
    this.selectedEnclosureId,
    this.checklist = const <RfiChecklistDescription>[],
    this.descriptions = const <RfiReferenceDescription>[],
  });

  final RfiReferenceForm? form;
  final bool loading;
  final Object? error;
  final List<RfiEnclosure> enclosures;
  final List<RfiEnclosure> subOptions;
  final int? selectedEnclosureId;
  final List<RfiChecklistDescription> checklist;
  final List<RfiReferenceDescription> descriptions;

  RfiEnclosure? get selectedEnclosure {
    final int? id = selectedEnclosureId;
    if (id == null) {
      return null;
    }
    for (final RfiEnclosure option in subOptions) {
      if (option.id == id) {
        return option;
      }
    }
    return null;
  }

  RfiReferenceState copyWith({
    RfiReferenceForm? form,
    bool? loading,
    Object? error = _keep,
    List<RfiEnclosure>? enclosures,
    List<RfiEnclosure>? subOptions,
    Object? selectedEnclosureId = _keep,
    List<RfiChecklistDescription>? checklist,
    List<RfiReferenceDescription>? descriptions,
    bool clearError = false,
    bool clearForm = false,
  }) {
    return RfiReferenceState(
      form: clearForm ? null : (form ?? this.form),
      loading: loading ?? this.loading,
      error: clearError ? null : (identical(error, _keep) ? this.error : error),
      enclosures: enclosures ?? this.enclosures,
      subOptions: subOptions ?? this.subOptions,
      selectedEnclosureId: identical(selectedEnclosureId, _keep)
          ? this.selectedEnclosureId
          : selectedEnclosureId as int?,
      checklist: checklist ?? this.checklist,
      descriptions: descriptions ?? this.descriptions,
    );
  }
}

const Object _keep = Object();

class RfiReferenceController extends AutoDisposeNotifier<RfiReferenceState> {
  int _life = 0;
  int _ticket = 0;
  bool _disposed = false;

  @override
  RfiReferenceState build() {
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
      ref.read(rfiReferenceRemoteDataSourceProvider).warmProjectLookups();
    });
    return const RfiReferenceState();
  }

  Future<void> selectForm(RfiReferenceForm? form) async {
    final int ticket = ++_ticket;
    if (form == null) {
      state = const RfiReferenceState();
      return;
    }
    state = RfiReferenceState(form: form, loading: true);
    await _load(ticket);
  }

  Future<void> selectEnclosure(int? id) async {
    if (state.form != RfiReferenceForm.checklist) {
      return;
    }
    final int ticket = ++_ticket;
    if (id == null) {
      state = state.copyWith(
        selectedEnclosureId: null,
        checklist: const <RfiChecklistDescription>[],
        loading: false,
        clearError: true,
      );
      return;
    }
    state = state.copyWith(
      selectedEnclosureId: id,
      checklist: const <RfiChecklistDescription>[],
      loading: true,
      clearError: true,
    );
    await _load(ticket);
  }

  Future<bool> refresh() async {
    if (state.form == null) {
      return true;
    }
    final int ticket = ++_ticket;
    state = state.copyWith(loading: true, clearError: true);
    return _load(ticket);
  }

  Future<bool> _load(int ticket) async {
    if (ticket != _ticket || _disposed) {
      return false;
    }
    final RfiReferenceForm? form = state.form;
    if (form == null) {
      return true;
    }
    final RfiReferenceRemoteDataSource dataSource = ref.read(
      rfiReferenceRemoteDataSourceProvider,
    );
    try {
      switch (form) {
        case RfiReferenceForm.enclosureList:
          final List<RfiEnclosure> rows = await dataSource.fetchEnclosureList();
          if (ticket != _ticket || _disposed) {
            return false;
          }
          state = state.copyWith(
            enclosures: rows,
            loading: false,
            clearError: true,
          );
        case RfiReferenceForm.checklist:
          final int? enclosureId = state.selectedEnclosureId;
          if (enclosureId == null) {
            final List<RfiEnclosure> options = await dataSource
                .fetchEnclosuresByAction();
            if (ticket != _ticket || _disposed) {
              return false;
            }
            state = state.copyWith(
              subOptions: options,
              loading: false,
              clearError: true,
            );
          } else {
            final List<RfiChecklistDescription> rows = await dataSource
                .fetchChecklist(enclosureId);
            if (ticket != _ticket || _disposed) {
              return false;
            }
            state = state.copyWith(
              checklist: rows,
              loading: false,
              clearError: true,
            );
          }
        case RfiReferenceForm.description:
          final List<RfiReferenceDescription> rows = await dataSource
              .fetchDescriptions();
          if (ticket != _ticket || _disposed) {
            return false;
          }
          state = state.copyWith(
            descriptions: rows,
            loading: false,
            clearError: true,
          );
      }
      return state.error == null;
    } on Object catch (error) {
      if (ticket != _ticket || _disposed) {
        return false;
      }
      state = state.copyWith(loading: false, error: error);
      return false;
    }
  }
}
