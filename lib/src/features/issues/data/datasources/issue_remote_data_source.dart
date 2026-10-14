import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/core/network/dio_client.dart';
import 'package:swr_pmis_mobile/src/features/issues/domain/issue_list.dart';
import 'package:swr_pmis_mobile/src/features/issues/domain/issue_parse.dart';

final issueRemoteDataSourceProvider = Provider<IssueRemoteDataSource>((ref) {
  return IssueRemoteDataSource(ref.watch(dioProvider));
});

class IssueRemoteDataSource {
  IssueRemoteDataSource(this._dio);

  final Dio _dio;

  Future<IssueListSnapshot> fetch(
    IssueListQuery query, {
    IssueFilterField? changed,
    IssueListSnapshot previous = IssueListSnapshot.empty,
  }) async {
    final List<IssueListCall> calls = issueListCalls(changed: changed);
    final Map<String, String> body = query.toJson();
    List<IssueOption> contracts = previous.contracts;
    List<IssueOption> hods = previous.hods;
    List<IssueOption> departments = previous.departments;
    List<IssueOption> categories = previous.categories;
    List<IssueOption> statuses = previous.statuses;
    List<IssueRow> issues = previous.issues;
    final List<Future<void>> jobs = <Future<void>>[];

    void addOptions(
      IssueListCall call,
      String path,
      List<IssueOption> Function(dynamic data) parse,
      void Function(List<IssueOption> value) assign,
    ) {
      if (!calls.contains(call)) {
        return;
      }
      jobs.add(
        _post(path, body).then((dynamic data) {
          assign(parse(data));
        }),
      );
    }

    addOptions(
      IssueListCall.contracts,
      ApiConstants.issueContractsFilterPath,
      parseIssueContracts,
      (List<IssueOption> value) => contracts = value,
    );
    addOptions(
      IssueListCall.hods,
      ApiConstants.issueHodFilterPath,
      parseIssueHods,
      (List<IssueOption> value) => hods = value,
    );
    addOptions(
      IssueListCall.departments,
      ApiConstants.issueDepartmentsFilterPath,
      parseIssueDepartments,
      (List<IssueOption> value) => departments = value,
    );
    addOptions(
      IssueListCall.categories,
      ApiConstants.issueCategoryFilterPath,
      parseIssueCategories,
      (List<IssueOption> value) => categories = value,
    );
    addOptions(
      IssueListCall.statuses,
      ApiConstants.issueStatusFilterPath,
      parseIssueStatuses,
      (List<IssueOption> value) => statuses = value,
    );
    if (calls.contains(IssueListCall.issues)) {
      jobs.add(
        _post(ApiConstants.issueListPath, body).then((dynamic data) {
          issues = parseIssueRows(data);
        }),
      );
    }
    await Future.wait<void>(jobs);
    return IssueListSnapshot(
      contracts: contracts,
      hods: hods,
      departments: departments,
      categories: categories,
      statuses: statuses,
      issues: issues,
    );
  }

  Future<dynamic> fetchAddIssueForm() {
    return _post(ApiConstants.issueAddFormPath, const <String, String>{});
  }

  Future<dynamic> fetchIssueFormContracts(String projectIdFk) {
    return _post(ApiConstants.issueFormContractsPath, <String, String>{
      'project_id_fk': projectIdFk,
    });
  }

  Future<dynamic> fetchIssueFormCategories(String contractTypeFk) {
    return _post(ApiConstants.issueFormCategoriesPath, <String, String>{
      'contract_type_fk': contractTypeFk,
    });
  }

  Future<dynamic> fetchIssueFormTitles(String categoryFk) {
    return _post(ApiConstants.issueFormTitlesPath, <String, String>{
      'category_fk': categoryFk,
    });
  }

  Future<dynamic> fetchIssueFormStructures(String contractIdFk) {
    return _post(ApiConstants.issueFormStructuresPath, <String, String>{
      'contract_id_fk': contractIdFk,
    });
  }

  Future<dynamic> fetchIssueFormComponents({
    required String contractIdFk,
    required String structure,
  }) {
    return _post(ApiConstants.issueFormComponentsPath, <String, String>{
      'contract_id_fk': contractIdFk,
      'structure': structure,
    });
  }

  Future<void> submitAddIssue(Map<String, String> fields) async {
    final FormData formData = FormData();
    for (final MapEntry<String, String> field in fields.entries) {
      formData.fields.add(field);
    }
    await _dio.post<dynamic>(
      ApiConstants.issueAddPath,
      data: formData,
      options: Options(contentType: null),
    );
  }

  Future<dynamic> _post(String path, Map<String, String> body) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      path,
      data: body,
    );
    return response.data;
  }
}
