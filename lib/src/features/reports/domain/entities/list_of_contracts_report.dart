import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';

/// Reports → Contracts → List of Contracts (formId 1335 / contract-report/7).
///
/// Does **not** match List of Contractors (formId 290 / contractorslist).
bool isListOfContractsReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  // Explicit exclude: List of Contractors.
  if (id == '290') {
    return false;
  }
  if (id == '1335') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('contractorslist')) {
    return false;
  }
  if (_isListOfContractsUrl(url)) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  if (name == 'list of contractors') {
    return false;
  }
  return name == 'list of contracts';
}

bool _isListOfContractsUrl(String url) {
  if (url.contains('generate-list-of-contracts')) {
    return true;
  }
  // Web menu uses paths like `contract-report/7`.
  final RegExpMatch? match = RegExp(
    r'contract-report(?:/|#)?0*7(?:/|$|\?|#)',
    caseSensitive: false,
  ).firstMatch(url);
  return match != null;
}

/// Status of Work options from `getStatsuListInContractReport` (`status`).
List<ContractDetailOption> parseListOfContractsWorkStatuses(Object? data) {
  return parseContractDetailStatuses(data);
}

/// Contract Status options from `getContractStatusListInContractReport`.
List<ContractDetailOption> parseListOfContractsContractStatuses(Object? data) {
  return parseContractDetailStatuses(data);
}
