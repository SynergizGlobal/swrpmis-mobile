import 'package:swr_pmis_mobile/src/features/issues/domain/issue_list.dart';

List<IssueOption> parseIssueContracts(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    return _option(
      _text(json['contract_id_fk']),
      _text(json['contract_short_name']),
    );
  });
}

List<IssueOption> parseIssueHods(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? name = _text(json['user_name']);
    final String? designation = _text(json['designation']);
    final String? label = name == null || designation == null
        ? null
        : '$name-$designation';
    return _option(_text(json['hod_user_id_fk']), label);
  });
}

List<IssueOption> parseIssueDepartments(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    return _option(
      _text(json['department_fk']),
      _text(json['department_name']),
    );
  });
}

List<IssueOption> parseIssueCategories(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? category = _text(json['category_fk']);
    return _option(category, category);
  });
}

List<IssueOption> parseIssueStatuses(dynamic data) {
  return _options(data, (Map<String, dynamic> json) {
    final String? status = _text(json['status_fk']);
    return _option(status, status);
  });
}

List<IssueRow> parseIssueRows(dynamic data) {
  final List<IssueRow> rows = <IssueRow>[];
  for (final Map<String, dynamic> json in _records(data)) {
    final String? issueId = _text(json['issue_id']);
    if (issueId == null) {
      continue;
    }
    rows.add(
      IssueRow(
        issueId: issueId,
        contract: _display(json['contract_short_name']),
        shortDescription: _display(json['title']),
        location: _display(json['location']),
        responsiblePerson: _first(json, const <String>[
          'other_org_resposible_person_name',
          'responsible_person',
        ]),
        department: _first(json, const <String>[
          'other_organization',
          'department_name',
        ]),
        status: _display(json['status_fk']),
        lastUpdate: _display(json['modified_date']),
      ),
    );
  }
  return rows;
}

List<IssueOption> _options(
  dynamic data,
  IssueOption? Function(Map<String, dynamic> json) read,
) {
  final Map<String, IssueOption> unique = <String, IssueOption>{};
  for (final Map<String, dynamic> json in _records(data)) {
    final IssueOption? option = read(json);
    if (option == null) {
      continue;
    }
    unique.putIfAbsent(option.value, () => option);
  }
  return unique.values.toList(growable: false);
}

IssueOption? _option(String? value, String? label) {
  if (value == null || label == null) {
    return null;
  }
  return IssueOption(value: value, label: label);
}

List<Map<String, dynamic>> _records(dynamic data) {
  if (data is List) {
    return _maps(data);
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    if (_isRecord(map)) {
      return <Map<String, dynamic>>[map];
    }
    for (final String key in const <String>[
      'data',
      'result',
      'content',
      'list',
      'records',
    ]) {
      final Object? nested = map[key];
      if (nested is List) {
        return _maps(nested);
      }
      if (nested is Map) {
        return <Map<String, dynamic>>[Map<String, dynamic>.from(nested)];
      }
    }
    return <Map<String, dynamic>>[map];
  }
  return const <Map<String, dynamic>>[];
}

bool _isRecord(Map<String, dynamic> json) {
  const Set<String> keys = <String>{
    'contract_id_fk',
    'contract_short_name',
    'hod_user_id_fk',
    'user_name',
    'designation',
    'department_fk',
    'department_name',
    'category_fk',
    'status_fk',
    'issue_id',
    'title',
  };
  for (final String key in keys) {
    if (json.containsKey(key)) {
      return true;
    }
  }
  return false;
}

List<Map<String, dynamic>> _maps(List<dynamic> data) {
  return data
      .whereType<Map>()
      .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

String _display(Object? value) => _text(value) ?? '';

String _first(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final String? text = _text(json[key]);
    if (text != null) {
      return text;
    }
  }
  return '';
}

String? _text(Object? value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}
