import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_dashboard_counts.dart';

final rfiDashboardRemoteDataSourceProvider =
    Provider<RfiDashboardRemoteDataSource>((ref) {
      return RfiDashboardRemoteDataSource(ref.watch(dioProvider));
    });

class RfiDashboardRemoteDataSource {
  RfiDashboardRemoteDataSource(this._dio);

  final Dio _dio;

  Future<RfiDashboardCounts> fetchCounts() async {
    final List<Response<dynamic>> responses =
        await Future.wait<Response<dynamic>>(<Future<Response<dynamic>>>[
          _dio.get<dynamic>(ApiConstants.rfiInspectionCountPath),
          _dio.get<dynamic>(ApiConstants.rfiStatusCountsPath),
        ]);
    return RfiDashboardCounts.fromResponses(
      inspectionCount: responses[0].data,
      statusCounts: responses[1].data,
    );
  }
}
