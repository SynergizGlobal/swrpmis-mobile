import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/contracts/domain/contract_form.dart';
import 'package:swr_pmis_mobile/src/features/contracts/domain/contract_list.dart';
import 'package:swr_pmis_mobile/src/features/contracts/domain/contract_parse.dart';

final contractRemoteDataSourceProvider = Provider<ContractRemoteDataSource>((
  ref,
) {
  return ContractRemoteDataSource(ref.watch(dioProvider));
});

class ContractRemoteDataSource {
  ContractRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ContractListSnapshot> fetch(
    ContractListQuery query, {
    ContractFilterField? changed,
    ContractListSnapshot previous = ContractListSnapshot.empty,
    bool reloadFilters = true,
  }) async {
    final List<ContractListCall> calls = reloadFilters
        ? contractListCalls(changed: changed)
        : const <ContractListCall>[ContractListCall.list];
    List<ContractOption> projects = previous.projects;
    List<ContractOption> hods = previous.hods;
    List<ContractOption> dyHods = previous.dyHods;
    List<ContractOption> contractors = previous.contractors;
    List<ContractOption> contractStatuses = previous.contractStatuses;
    List<ContractOption> workStatuses = previous.workStatuses;
    List<ContractRow> rows = previous.rows;
    int total = previous.total;
    final List<Future<void>> jobs = <Future<void>>[];

    if (calls.contains(ContractListCall.projects)) {
      jobs.add(
        _get(
          ApiConstants.contractProjectsFilterPath,
          query.filterQueryParameters(includeProject: false),
        ).then((dynamic data) {
          projects = parseContractProjects(data);
        }),
      );
    }
    if (calls.contains(ContractListCall.hods)) {
      jobs.add(
        _get(
          ApiConstants.contractHodFilterPath,
          query.filterQueryParameters(includeDesignation: false),
        ).then((dynamic data) {
          hods = parseContractHods(data);
        }),
      );
    }
    if (calls.contains(ContractListCall.dyHods)) {
      jobs.add(
        _get(
          ApiConstants.contractDyHodFilterPath,
          query.filterQueryParameters(includeDyHod: false),
        ).then((dynamic data) {
          dyHods = parseContractDyHods(data);
        }),
      );
    }
    if (calls.contains(ContractListCall.contractors)) {
      jobs.add(
        _get(
          ApiConstants.contractContractorsFilterPath,
          query.filterQueryParameters(includeContractor: false),
        ).then((dynamic data) {
          contractors = parseContractContractors(data);
        }),
      );
    }
    if (calls.contains(ContractListCall.contractStatuses)) {
      jobs.add(
        _get(
          ApiConstants.contractStatusFilterPath,
          query.filterQueryParameters(includeContractStatus: false),
        ).then((dynamic data) {
          contractStatuses = parseContractStatuses(data);
        }),
      );
    }
    if (calls.contains(ContractListCall.workStatuses)) {
      jobs.add(
        _get(
          ApiConstants.contractWorkStatusFilterPath,
          query.filterQueryParameters(includeStatus: false),
        ).then((dynamic data) {
          workStatuses = parseContractWorkStatuses(data);
        }),
      );
    }
    if (calls.contains(ContractListCall.list)) {
      jobs.add(
        _postList(query).then((
          ({List<ContractRow> rows, int total}) result,
        ) {
          rows = result.rows;
          total = result.total;
        }),
      );
    }
    await Future.wait<void>(jobs);
    return ContractListSnapshot(
      projects: projects,
      hods: hods,
      dyHods: dyHods,
      contractors: contractors,
      contractStatuses: contractStatuses,
      workStatuses: workStatuses,
      rows: rows,
      total: total,
    );
  }

  Future<ContractFormMaster> fetchAddFormMaster() async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.contractAddFormPath,
      data: <String, dynamic>{},
      options: Options(contentType: Headers.jsonContentType),
    );
    return parseContractFormMaster(response.data);
  }

  Future<List<ContractFormOption>> fetchFormStatusesForAwarded({
    required String contractAwarded,
  }) async {
    final dynamic data = await _get(
      ApiConstants.contractFormStatusPath,
      <String, dynamic>{'contract_status': contractAwarded.trim()},
    );
    final List<ContractOption> options = parseContractWorkStatuses(data);
    if (options.isNotEmpty) {
      return options
          .map(
            (ContractOption o) =>
                ContractFormOption(id: o.value, label: o.label),
          )
          .toList(growable: false);
    }
    final List<ContractOption> statuses = parseContractStatuses(data);
    return statuses
        .map(
          (ContractOption o) => ContractFormOption(id: o.value, label: o.label),
        )
        .toList(growable: false);
  }

  Future<String> addContract({
    required Map<String, String> fields,
    List<({String path, String fileName})> files =
        const <({String path, String fileName})>[],
    List<String> executiveDepartments = const <String>[],
    List<String> executiveUserIds = const <String>[],
  }) async {
    final FormData form = FormData();
    fields.forEach((String key, String value) {
      form.fields.add(MapEntry<String, String>(key, value));
    });

    void addRepeated(String key, List<String> values) {
      if (values.isEmpty) {
        form.fields.add(MapEntry<String, String>(key, ''));
        return;
      }
      for (final String value in values) {
        form.fields.add(MapEntry<String, String>(key, value));
      }
    }

    addRepeated('department_fk', executiveDepartments);
    addRepeated('executive_user_id_fk', executiveUserIds);

    for (final ({String path, String fileName}) file in files) {
      form.files.add(
        MapEntry<String, MultipartFile>(
          'contractFiles',
          await MultipartFile.fromFile(
            file.path,
            filename: file.fileName.trim().isEmpty
                ? p.basename(file.path)
                : file.fileName,
          ),
        ),
      );
    }

    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.contractAddPath,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    if (!isContractMutationSuccess(response.data)) {
      throw StateError(
        parseContractMutationMessage(
          response.data,
          fallback: 'Could not add contract.',
        ),
      );
    }
    return parseContractMutationMessage(
      response.data,
      fallback: 'Contract added successfully',
    );
  }

  Future<({List<ContractRow> rows, int total})> _postList(
    ContractListQuery query,
  ) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      ApiConstants.contractListPath,
      queryParameters: query.listQueryParameters(),
      data: query.filterBody(),
    );
    return parseContractList(response.data);
  }

  Future<dynamic> _get(String path, Map<String, dynamic> queryParameters) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    return response.data;
  }
}
