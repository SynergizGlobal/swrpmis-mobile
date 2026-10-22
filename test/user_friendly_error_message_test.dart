import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';

void main() {
  test('unknown DioException with FormatException cause', () {
    final DioException error = DioException(
      requestOptions: RequestOptions(path: '/logs'),
      type: DioExceptionType.unknown,
      error: const FormatException('Unexpected character'),
    );
    expect(
      userFriendlyErrorMessage(error),
      'Server returned an unexpected response format.',
    );
  });
}
