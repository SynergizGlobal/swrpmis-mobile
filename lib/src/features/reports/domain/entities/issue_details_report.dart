import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/pending_issues_report.dart';

/// Reports → Issues → Issue Details Report (formId 298 / issue-details-report).
///
/// UI title may read "Issues Details Report". Distinct from Pending Issues
/// (hod **name** in generate) — here `hod_user_id_fk` is the **user id**.
bool isIssueDetailsReport({
  required String formId,
  required String formName,
  required String webFormUrl,
}) {
  final String id = formId.trim();
  if (id == '298') {
    return true;
  }

  final String url = webFormUrl.trim().toLowerCase();
  if (url.contains('issue-details-report') ||
      url.contains('issues-details-report') ||
      url.contains('issues-details-report/generate') ||
      url.contains('/api/issues-details-report')) {
    return true;
  }

  final String name = formName.trim().toLowerCase();
  final bool detailsName =
      name.contains('issue details') || name.contains('issues details');
  return detailsName && name.contains('report');
}

/// Location & Description row from `POST /api/issues-report/title-list`.
class IssueDetailsTitleOption {
  const IssueDetailsTitleOption({
    required this.issueId,
    required this.title,
    this.location = '',
  });

  final String issueId;
  final String title;
  final String location;

  /// Prefer title; fall back to location, then issue id.
  String get label {
    if (title.isNotEmpty) {
      return title;
    }
    if (location.isNotEmpty) {
      return location;
    }
    return issueId;
  }
}

/// Reuses Pending Issues HOD parser (same `getHodList` shape).
List<PendingIssuesHodOption> parseIssueDetailsHods(Object? data) =>
    parsePendingIssuesHods(data);

/// Reuses Pending Issues contract parser (same `getContractList` shape).
List<ContractDetailOption> parseIssueDetailsContracts(Object? data) =>
    parsePendingIssuesContracts(data);

List<ContractDetailOption> parseIssueDetailsStatuses(Object? data) {
  return _parseSimpleOptions(
    data,
    idKeys: const <String>['status_fk', 'status', 'id', 'value'],
    labelKeys: const <String>[
      'status_name',
      'status_label',
      'label',
      'name',
      'status_fk',
      'status',
    ],
  );
}

List<ContractDetailOption> parseIssueDetailsLocations(Object? data) {
  return _parseSimpleOptions(
    data,
    idKeys: const <String>['location', 'id', 'value'],
    labelKeys: const <String>['location', 'label', 'name'],
  );
}

List<ContractDetailOption> parseIssueDetailsCategories(Object? data) {
  return _parseSimpleOptions(
    data,
    idKeys: const <String>['category_fk', 'category', 'id', 'value'],
    labelKeys: const <String>[
      'category_name',
      'category_label',
      'label',
      'name',
      'category_fk',
      'category',
    ],
  );
}

List<IssueDetailsTitleOption> parseIssueDetailsTitles(Object? data) {
  final List<IssueDetailsTitleOption> out = <IssueDetailsTitleOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final String issueId = _firstText(map, const <String>[
      'issue_id',
      'issueId',
      'id',
    ]);
    final String title = _firstText(map, const <String>[
      'title',
      'issue_title',
      'description',
      'name',
      'label',
    ]);
    final String location = _firstText(map, const <String>[
      'location',
      'location_description',
    ]);
    if (issueId.isEmpty && title.isEmpty && location.isEmpty) {
      continue;
    }
    final String key = issueId.isNotEmpty
        ? issueId
        : (title.isNotEmpty ? title : location);
    if (!seen.add(key)) {
      continue;
    }
    out.add(
      IssueDetailsTitleOption(
        issueId: issueId.isEmpty ? key : issueId,
        title: title,
        location: location,
      ),
    );
  }
  return out;
}

/// Generate body: all six keys; empty string when uncleared.
/// [hodUserId] is the HOD **user id** (e.g. PMIS_SU_002), not display name.
Map<String, dynamic> buildIssueDetailsGenerateBody({
  required String hodUserId,
  required String contractId,
  required String status,
  required String location,
  required String category,
  required String issueId,
}) {
  return <String, dynamic>{
    'hod_user_id_fk': hodUserId.trim(),
    'contract_id_fk': contractId.trim(),
    'status_fk': status.trim(),
    'location': location.trim(),
    'category_fk': category.trim(),
    'issue_id': issueId.trim(),
  };
}

List<ContractDetailOption> _parseSimpleOptions(
  Object? data, {
  required List<String> idKeys,
  required List<String> labelKeys,
}) {
  final List<ContractDetailOption> out = <ContractDetailOption>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> map in _asMaps(data)) {
    final String id = _firstText(map, idKeys);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final String label = _firstText(map, labelKeys);
    out.add(ContractDetailOption(id: id, label: label.isEmpty ? id : label));
  }
  return out;
}

List<Map<String, dynamic>> _asMaps(Object? data) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in const <String>[
      'data',
      'result',
      'content',
      'list',
      'records',
      'options',
      'statuses',
      'locations',
      'categories',
      'titles',
      'issues',
    ]) {
      final Object? nested = map[key];
      if (nested is List || nested is Map) {
        return _asMaps(nested);
      }
    }
    if (_firstText(map, const <String>[
      'status_fk',
      'status',
      'location',
      'category_fk',
      'category',
      'issue_id',
      'title',
      'id',
      'name',
      'label',
    ]).isNotEmpty) {
      return <Map<String, dynamic>>[map];
    }
  }
  return const <Map<String, dynamic>>[];
}

String _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String value = _text(json[key]);
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

String _text(Object? value) {
  if (value == null) {
    return '';
  }
  final String text = '$value'.trim();
  if (text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}
