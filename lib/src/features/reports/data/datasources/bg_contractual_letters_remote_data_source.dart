import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/bg_contractual_letters.dart';

final bgContractualLettersRemoteDataSourceProvider =
    Provider<BgContractualLettersRemoteDataSource>((Ref ref) {
      return BgContractualLettersRemoteDataSource(ref.watch(dioProvider));
    });

class BgContractualLettersRemoteDataSource {
  BgContractualLettersRemoteDataSource(this._dio);

  final Dio _dio;

  /// POST `/ajax/generate-bg-contractual-letters` with form fields
  /// `date_of_start` and `bg_date` (`yyyy-MM-dd`).
  Future<List<BgContractualLetterRow>> search({
    required String dateOfStart,
    required String bgDate,
  }) async {
    final String start = dateOfStart.trim();
    final String end = bgDate.trim();
    if (start.isEmpty || end.isEmpty) {
      throw StateError('Start Date and End Date are required.');
    }

    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.bgContractualLettersPath,
      data: <String, dynamic>{
        'date_of_start': start,
        'bg_date': end,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.json,
      ),
    );

    final dynamic payload = response.data;
    if (payload is String) {
      final String trimmed = payload.trimLeft();
      if (trimmed.startsWith('<') ||
          trimmed.toLowerCase().startsWith('<!doctype')) {
        throw StateError(
          'Unexpected HTML response from BG Contractual Letters. '
          'Try again or use the web report.',
        );
      }
    }
    return parseBgContractualLetters(payload);
  }
}
