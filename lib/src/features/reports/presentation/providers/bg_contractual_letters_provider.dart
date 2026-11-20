import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/features/reports/data/datasources/bg_contractual_letters_remote_data_source.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/bg_contractual_letters.dart';

final bgContractualLettersControllerProvider =
    StateNotifierProvider.autoDispose<
      BgContractualLettersController,
      BgContractualLettersState
    >((Ref ref) {
      return BgContractualLettersController(
        ref.watch(bgContractualLettersRemoteDataSourceProvider),
      );
    });

class BgContractualLettersState {
  const BgContractualLettersState({
    this.startDate,
    this.endDate,
    this.rows = const <BgContractualLetterRow>[],
    this.searched = false,
    this.loading = false,
    this.error,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final List<BgContractualLetterRow> rows;
  final bool searched;
  final bool loading;
  final Object? error;

  /// API body uses `yyyy-MM-dd`.
  static final DateFormat apiDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat displayDateFormat = DateFormat('dd/MM/yyyy');

  String? get startDateLabel =>
      startDate == null ? null : displayDateFormat.format(startDate!);
  String? get endDateLabel =>
      endDate == null ? null : displayDateFormat.format(endDate!);

  String? get startDateApi =>
      startDate == null ? null : apiDateFormat.format(startDate!);
  String? get endDateApi =>
      endDate == null ? null : apiDateFormat.format(endDate!);

  BgContractualLettersState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
    List<BgContractualLetterRow>? rows,
    bool? searched,
    bool? loading,
    Object? error = _sentinel,
    bool clearError = false,
  }) {
    return BgContractualLettersState(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      rows: rows ?? this.rows,
      searched: searched ?? this.searched,
      loading: loading ?? this.loading,
      error: clearError
          ? null
          : identical(error, _sentinel)
          ? this.error
          : error,
    );
  }
}

const Object _sentinel = Object();

class BgContractualLettersController
    extends StateNotifier<BgContractualLettersState> {
  BgContractualLettersController(this._source)
    : super(const BgContractualLettersState());

  final BgContractualLettersRemoteDataSource _source;

  void setStartDate(DateTime? value) {
    state = state.copyWith(
      startDate: value,
      clearStartDate: value == null,
      clearError: true,
    );
  }

  void setEndDate(DateTime? value) {
    state = state.copyWith(
      endDate: value,
      clearEndDate: value == null,
      clearError: true,
    );
  }

  Future<void> search() async {
    final String? start = state.startDateApi;
    final String? end = state.endDateApi;
    if (start == null || end == null) {
      throw StateError('Please select Start Date and End Date.');
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<BgContractualLetterRow> rows = await _source.search(
        dateOfStart: start,
        bgDate: end,
      );
      state = state.copyWith(
        rows: rows,
        searched: true,
        loading: false,
        clearError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(
        loading: false,
        searched: true,
        rows: const <BgContractualLetterRow>[],
        error: error,
      );
      rethrow;
    }
  }
}
