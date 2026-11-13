import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';

void main() {
  test('binary downloads are not logged', () {
    final RequestOptions bytes = RequestOptions(
      path: '/api/rfiLog/previewFiles',
      responseType: ResponseType.bytes,
    );
    expect(shouldLogDioTraffic(bytes, const FilterArgs(false, null)), isFalse);
    expect(
      shouldLogDioTraffic(
        RequestOptions(path: '/x'),
        FilterArgs(true, Uint8List(10)),
      ),
      isFalse,
    );
  });

  test('normal JSON traffic is still logged', () {
    final RequestOptions json = RequestOptions(path: '/rfi/rfi-details/105');
    expect(shouldLogDioTraffic(json, const FilterArgs(false, null)), isTrue);
    expect(
      shouldLogDioTraffic(
        json,
        const FilterArgs(true, <String, dynamic>{'id': 105}),
      ),
      isTrue,
    );
  });
}
