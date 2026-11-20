import 'package:swr_pmis_mobile/src/features/reports/domain/entities/bg_insurance_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

/// Reports → Contracts → Date of Completion Report
/// (web title: Contract Completion Report; formId 1337 / contract-report/9).
bool isContractCompletionReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '1337') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('generate-contract-completion')) {
    return true;
  }
  if (_isContractCompletionUrl(url)) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  // Exclude "Date of Completion Letters".
  if (name.contains('letter')) {
    return false;
  }
  return name == 'date of completion report' ||
      name == 'contract completion report';
}

bool _isContractCompletionUrl(String url) {
  // Web menu uses paths like `contract-report/9`.
  final RegExpMatch? match = RegExp(
    r'contract-report(?:/|#)?0*9(?:/|$|\?|#)',
    caseSensitive: false,
  ).firstMatch(url);
  return match != null;
}

List<ContractDetailOption> parseContractCompletionProjects(Object? data) {
  return parseBgInsuranceProjects(data);
}

/// Contractor options with label `CON0001 - M/s …` when id + name exist.
List<ContractDetailOption> parseContractCompletionContractors(Object? data) {
  return parseBgInsuranceContractors(data);
}

List<ContractDetailOption> parseContractCompletionHods(Object? data) {
  return parseContractDetailHods(data);
}

/// Status of Work options from `getContractStatusListInContractReport`
/// (`contract_status_fk`: Completed / In Progress / Not Awarded).
List<ContractDetailOption> parseContractCompletionContractStatuses(
  Object? data,
) {
  return parseBgInsuranceContractStatuses(data);
}
