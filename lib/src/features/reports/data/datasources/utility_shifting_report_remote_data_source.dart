import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/utility_shifting_report.dart';

final utilityShiftingReportRemoteDataSourceProvider =
    Provider<UtilityShiftingReportRemoteDataSource>((Ref ref) {
      return UtilityShiftingReportRemoteDataSource(ref.watch(dioProvider));
    });

class UtilityShiftingReportRemoteDataSource {
  UtilityShiftingReportRemoteDataSource(this._dio);

  final Dio _dio;

  /// Loads Project, Execution Agency, Impacted Contract, and HOD in one GET.
  Future<UtilityShiftingReportFilters> fetchFilters() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.utilityReportFiltersPath,
    );
    return parseUtilityShiftingReportFilters(response.data);
  }

  /// TODO(utility-report): Wire the real download endpoint when backend ships it.
  ///
  /// Do **not** invent a generate URL or body shape beyond the documented keys.
  /// When the API arrives, send filter values via [buildUtilityShiftingGenerateBody]:
  /// - project: `project_id_fk` (e.g. P26)
  /// - execution agency: `execution_agency_fk` (e.g. MPPKVVCL)
  /// - impacted contract: `contract_id_fk` (e.g. P01EN02)
  /// - hod: `hod_user_id_fk` (e.g. PMIS_IU_039)
  Future<({Uint8List bytes, String fileName})> generateReport({
    required String projectId,
    required String executionAgency,
    required String contractId,
    required String hodUserId,
  }) async {
    // Documented filter payload kept ready for the real POST/GET download.
    final Map<String, dynamic> prepared =
        buildUtilityShiftingGenerateBody(
          projectId: projectId,
          executionAgency: executionAgency,
          contractId: contractId,
          hodUserId: hodUserId,
        );
    throw UnimplementedError(
      'Utility Shifting Report download endpoint is not available yet. '
      'Contact backend for the generate API. Prepared filters: $prepared',
    );
  }
}
