import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_assign_executive.dart';

final rfiAssignExecutiveRemoteDataSourceProvider =
    Provider<RfiAssignExecutiveRemoteDataSource>((ref) {
      return RfiAssignExecutiveRemoteDataSource(ref.watch(dioProvider));
    });

class RfiAssignExecutiveRemoteDataSource {
  RfiAssignExecutiveRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<RfiAssignProject>> fetchProjects() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiProjectNamesPath,
    );
    return parseRfiAssignProjects(response.data);
  }

  Future<List<RfiAssignContract>> fetchContracts(String projectId) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiContractNamesPath,
      queryParameters: <String, String>{'projectId': projectId},
    );
    return parseRfiAssignContracts(response.data);
  }

  Future<List<RfiAssignExecutiveLog>> fetchLogs() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      ApiConstants.rfiAssignedExecutiveLogsPath,
    );
    return parseRfiAssignExecutiveLogs(response.data);
  }

  Future<void> deleteAssignment(int id) async {
    await _dio.post<dynamic>(ApiConstants.rfiAssignExecutiveDeletePath(id));
  }
}
