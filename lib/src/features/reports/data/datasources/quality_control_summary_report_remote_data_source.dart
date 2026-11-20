import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/quality_control_summary_report.dart';

final qualityControlSummaryReportRemoteDataSourceProvider =
    Provider<QualityControlSummaryReportRemoteDataSource>((Ref ref) {
      return QualityControlSummaryReportRemoteDataSource(
        ref.watch(dioProvider),
      );
    });

class QualityControlSummaryReportRemoteDataSource {
  QualityControlSummaryReportRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ContractDetailOption>> fetchProjects() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.materialReceiptDropdownProjectsPath,
      queryParameters: <String, dynamic>{
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return parseQualitySummaryProjects(response.data);
  }

  Future<List<ContractDetailOption>> fetchContracts(String projectId) async {
    final String id = projectId.trim();
    if (id.isEmpty) {
      return const <ContractDetailOption>[];
    }
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.qualityTestObligationContractsPath,
      queryParameters: <String, dynamic>{
        'projectId': id,
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return parseQualitySummaryContracts(response.data);
  }

  Future<QualityControlSummaryReport> fetchSummary({
    required String contractId,
    required String from,
    required String to,
    required String projectName,
    required String contractShortName,
    required String contractorName,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.qualitySummaryReportPath,
      queryParameters: <String, dynamic>{
        'contractId': contractId.trim(),
        'from': from.trim(),
        'to': to.trim(),
        'projectName': projectName.trim(),
        'contractShortName': contractShortName.trim(),
        'contractorName': contractorName.trim(),
        '_t': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return QualityControlSummaryReport.fromJson(response.data);
  }
}
