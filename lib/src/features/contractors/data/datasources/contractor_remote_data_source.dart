import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/contractors/domain/contractor_list.dart';
import 'package:swr_pmis_mobile/src/features/contractors/domain/contractor_parse.dart';

final contractorRemoteDataSourceProvider =
    Provider<ContractorRemoteDataSource>((ref) {
      return ContractorRemoteDataSource(ref.watch(dioProvider));
    });

class ContractorRemoteDataSource {
  ContractorRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ContractorListSnapshot> fetchList() async {
    final dynamic data = await _get(
      ApiConstants.contractorsPath,
      queryParameters: <String, dynamic>{'_t': _cacheBust()},
    );
    return ContractorListSnapshot(rows: parseContractorRows(data));
  }

  Future<List<String>> fetchSpecializations() async {
    final dynamic data = await _get(
      ApiConstants.contractorsSpecializationsPath,
      queryParameters: <String, dynamic>{'_t': _cacheBust()},
    );
    return parseContractorSpecializations(data);
  }

  Future<ContractorRow> create(Map<String, dynamic> body) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        ApiConstants.contractorsPath,
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );
      final ContractorRow? row = parseContractorRow(response.data);
      if (row != null) {
        return row;
      }
      return ContractorRow(
        contractorId: '',
        contractorName: '${body['contractorName'] ?? ''}',
        specialization: '${body['specilaization'] ?? ''}',
        address: '${body['address'] ?? ''}',
        primaryContact: '${body['primaryContact'] ?? ''}',
        phoneNumber: '${body['phoneNumber'] ?? ''}',
        email: '${body['email'] ?? ''}',
        panNumber: '${body['panNumber'] ?? ''}',
        gstNumber: '${body['gstNumber'] ?? ''}',
        bankName: '${body['bankName'] ?? ''}',
        accountNo: '${body['accountNo'] ?? ''}',
        ifscCode: '${body['ifscCode'] ?? ''}',
        bankAddress: '${body['bankAddress'] ?? ''}',
        remarks: '${body['remarks'] ?? ''}',
        contractorShortCode: '${body['contractorShortCode'] ?? ''}',
      );
    } on DioException catch (error) {
      final String? message = contractorApiMessage(error.response?.data);
      if (message != null && message.isNotEmpty) {
        throw StateError(message);
      }
      rethrow;
    }
  }

  Future<ContractorRow> update({
    required String contractorId,
    required Map<String, dynamic> body,
  }) async {
    final String id = contractorId.trim();
    if (id.isEmpty) {
      throw StateError('Missing contractor id.');
    }
    try {
      final Response<dynamic> response = await _dio.put<dynamic>(
        ApiConstants.contractorByIdPath(id),
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );
      final ContractorRow? row = parseContractorRow(response.data);
      if (row != null) {
        return row;
      }
      return ContractorRow(
        contractorId: id,
        contractorName: '${body['contractorName'] ?? ''}',
        specialization: '${body['specilaization'] ?? ''}',
        address: '${body['address'] ?? ''}',
        primaryContact: '${body['primaryContact'] ?? ''}',
        phoneNumber: '${body['phoneNumber'] ?? ''}',
        email: '${body['email'] ?? ''}',
        panNumber: '${body['panNumber'] ?? ''}',
        gstNumber: '${body['gstNumber'] ?? ''}',
        bankName: '${body['bankName'] ?? ''}',
        accountNo: '${body['accountNo'] ?? ''}',
        ifscCode: '${body['ifscCode'] ?? ''}',
        bankAddress: '${body['bankAddress'] ?? ''}',
        remarks: '${body['remarks'] ?? ''}',
        contractorShortCode: '${body['contractorShortCode'] ?? ''}',
        searchStr: body['searchStr']?.toString(),
      );
    } on DioException catch (error) {
      final String? message = contractorApiMessage(error.response?.data);
      if (message != null && message.isNotEmpty) {
        throw StateError(message);
      }
      rethrow;
    }
  }

  Future<dynamic> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    return response.data;
  }

  String _cacheBust() => DateTime.now().millisecondsSinceEpoch.toString();
}
