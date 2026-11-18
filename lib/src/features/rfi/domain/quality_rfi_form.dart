import 'package:flutter/foundation.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/work_rfi_form.dart';

/// Shared option for Quality/Safety RFI dropdowns and multi-selects.
class QualityRfiOption {
  const QualityRfiOption({required this.id, required this.label});

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QualityRfiOption && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}

class QualityRfiDetail {
  const QualityRfiDetail({
    required this.id,
    required this.rfiId,
    required this.project,
    required this.contract,
    required this.structureType,
    required this.structure,
    required this.structureId,
    required this.action,
    required this.typeOfRfi,
    required this.userIdOfRepresentative,
    required this.nameOfRepresentative,
    required this.dateOfSubmission,
    required this.dateOfInspection,
    required this.timeOfInspection,
    required this.rfiDescriptionList,
    required this.enclosuresList,
    required this.description,
    required this.status,
  });

  final int? id;
  final String rfiId;
  final String project;
  final String contract;
  final String structureType;
  final String structure;
  final String structureId;
  final String action;
  final String typeOfRfi;
  final String userIdOfRepresentative;
  final String nameOfRepresentative;
  final String dateOfSubmission;
  final String dateOfInspection;
  final String timeOfInspection;
  final List<String> rfiDescriptionList;
  final List<String> enclosuresList;
  final String description;
  final String status;
}

class QualityRfiSubmitDraft {
  const QualityRfiSubmitDraft({
    required this.project,
    required this.contract,
    required this.structureType,
    required this.structure,
    required this.action,
    required this.typeOfRfi,
    required this.contractorRepresentative,
    required this.dateOfSubmission,
    required this.dateOfInspection,
    required this.timeOfInspection,
    required this.rfiDescriptions,
    required this.enclosures,
    required this.description,
    required this.editing,
  });

  final String project;
  final String contract;
  final String structureType;
  final String structure;
  final String action;
  final String typeOfRfi;
  final String contractorRepresentative;
  final String dateOfSubmission;
  final String dateOfInspection;
  final String timeOfInspection;
  final List<String> rfiDescriptions;
  final List<String> enclosures;
  final String description;
  final bool editing;
}

const String qualityRfiCategory = 'QUALITY_OR_SAFETY';
const String qualityRfiFixedAction = 'Create';
const String qualityRfiActionUpdate = 'Update';
const String qualityRfiActionReassign = 'Reassign';
const String qualityRfiActionReschedule = 'Reschedule';

const List<QualityRfiOption> qualityRfiEditActions = <QualityRfiOption>[
  QualityRfiOption(id: qualityRfiActionReschedule, label: qualityRfiActionReschedule),
  QualityRfiOption(id: qualityRfiActionUpdate, label: qualityRfiActionUpdate),
  QualityRfiOption(id: qualityRfiActionReassign, label: qualityRfiActionReassign),
];

const String qualityRfiDefaultEditAction = qualityRfiActionUpdate;

const List<QualityRfiOption> qualityRfiTypeOptions = <QualityRfiOption>[
  QualityRfiOption(id: 'Spot RFI', label: 'Spot RFI'),
  QualityRfiOption(id: 'Regular RFI', label: 'Regular RFI'),
];

bool qualityRfiActionUnlocksRepresentative(String action) =>
    action == qualityRfiActionReassign;

bool qualityRfiActionUnlocksSchedule(String action) =>
    action == qualityRfiActionReschedule;

bool qualityRfiActionUnlocksDescriptions(String action) =>
    action == qualityRfiActionUpdate || action == qualityRfiActionReschedule;

bool qualityRfiActionUnlocksDescriptionText(String action) =>
    action == qualityRfiActionUpdate || action == qualityRfiActionReschedule;

List<QualityRfiOption> parseQualityRfiProjects(dynamic data) {
  try {
    final List<Map<String, dynamic>> rows = _asMaps(data);
    if (rows.isEmpty && data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);
      final String id = _text(map['projectId'] ?? map['project']);
      final String label = _text(map['projectName'] ?? map['name'] ?? id);
      if (id.isNotEmpty) {
        return <QualityRfiOption>[QualityRfiOption(id: id, label: label)];
      }
    }
    return _dedupeOptions(<QualityRfiOption>[
      for (final Map<String, dynamic> row in rows)
        if (_text(row['projectId'] ?? row['project']).isNotEmpty)
          QualityRfiOption(
            id: _text(row['projectId'] ?? row['project']),
            label: _text(row['projectName'] ?? row['name'] ?? row['projectId']),
          ),
    ]);
  } on Object catch (error, stackTrace) {
    debugPrint('parseQualityRfiProjects failed: $error\n$stackTrace');
    return const <QualityRfiOption>[];
  }
}

List<QualityRfiOption> parseQualityRfiContracts(dynamic data) {
  try {
    return _dedupeOptions(<QualityRfiOption>[
      for (final Map<String, dynamic> row in _asMaps(data))
        if (_text(row['contractId'] ?? row['contract']).isNotEmpty)
          QualityRfiOption(
            id: _text(row['contractId'] ?? row['contract']),
            label: _text(
              row['contractName'] ?? row['name'] ?? row['contractId'],
            ),
          ),
    ]);
  } on Object catch (error, stackTrace) {
    debugPrint('parseQualityRfiContracts failed: $error\n$stackTrace');
    return const <QualityRfiOption>[];
  }
}

List<QualityRfiOption> parseQualityRfiStructureTypes(dynamic data) {
  return parseWorkRfiStructureTypes(data)
      .map(
        (WorkRfiOption o) => QualityRfiOption(id: o.id, label: o.label),
      )
      .toList(growable: false);
}

List<QualityRfiOption> parseQualityRfiStructures(dynamic data) {
  return parseWorkRfiStructures(data)
      .map(
        (WorkRfiOption o) => QualityRfiOption(id: o.id, label: o.label),
      )
      .toList(growable: false);
}

List<QualityRfiOption> parseQualityRfiRepresentatives(dynamic data) {
  try {
    if (data is Map) {
      final String id = _text(data['userId']);
      final String name = _text(data['userName']);
      if (id.isNotEmpty) {
        return <QualityRfiOption>[
          QualityRfiOption(id: id, label: name.isEmpty ? id : name),
        ];
      }
    }
    return _dedupeOptions(<QualityRfiOption>[
      for (final Map<String, dynamic> row in _asMaps(data))
        if (_text(row['userId']).isNotEmpty)
          QualityRfiOption(
            id: _text(row['userId']),
            label: _text(row['userName']).isEmpty
                ? _text(row['userId'])
                : _text(row['userName']),
          ),
    ]);
  } on Object catch (error, stackTrace) {
    debugPrint('parseQualityRfiRepresentatives failed: $error\n$stackTrace');
    return const <QualityRfiOption>[];
  }
}

List<QualityRfiOption> parseQualityRfiDescriptions(dynamic data) {
  try {
    return _dedupeOptions(<QualityRfiOption>[
      for (final Map<String, dynamic> row in _asMaps(data))
        if (_text(row['rfiDescription']).isNotEmpty)
          QualityRfiOption(
            id: _text(row['id']),
            label: _text(row['rfiDescription']),
          ),
    ]).where((QualityRfiOption o) => o.id.isNotEmpty).toList(growable: false);
  } on Object catch (error, stackTrace) {
    debugPrint('parseQualityRfiDescriptions failed: $error\n$stackTrace');
    return const <QualityRfiOption>[];
  }
}

List<QualityRfiOption> parseQualityRfiEnclosures(dynamic data) {
  try {
    return _dedupeOptions(<QualityRfiOption>[
      for (final Map<String, dynamic> row in _asMaps(data))
        if (_text(row['encloserName'] ?? row['enclosureName']).isNotEmpty)
          QualityRfiOption(
            id: _text(row['id']),
            label: _text(row['encloserName'] ?? row['enclosureName']),
          ),
    ]).where((QualityRfiOption o) => o.id.isNotEmpty).toList(growable: false);
  } on Object catch (error, stackTrace) {
    debugPrint('parseQualityRfiEnclosures failed: $error\n$stackTrace');
    return const <QualityRfiOption>[];
  }
}

QualityRfiDetail? parseQualityRfiDetail(dynamic data) {
  try {
    final Map<String, dynamic>? map = _detailMap(data);
    if (map == null) {
      debugPrint('parseQualityRfiDetail: no detail map in ${data.runtimeType}');
      return null;
    }
    final String project =
        _firstText(map, const <String>['project', 'projectId']);
    final String contract =
        _firstText(map, const <String>['contract', 'contractId']);
    // Prefer numeric/API structureId for dropdown values; keep structure as
    // the stored strip-chart label when the API sends both.
    final String structureId =
        _firstText(map, const <String>['structureId', 'structure_id']);
    final String structureLabel = _text(map['structure']);
    final QualityRfiDetail detail = QualityRfiDetail(
      id: _readId(map['id']),
      rfiId: _firstText(map, const <String>['rfi_Id', 'rfiId', 'rfiID']),
      project: project,
      contract: contract,
      structureType: _text(map['structureType'] ?? map['structure_type']),
      structure: structureLabel.isNotEmpty
          ? structureLabel
          : (structureId.isNotEmpty
              ? structureId
              : _text(map['structure'])),
      structureId: structureId.isNotEmpty
          ? structureId
          : _firstText(map, const <String>['structure', 'structureId']),
      action: _text(map['action']),
      typeOfRfi: _firstText(map, const <String>['typeOfRFI', 'typeOfRfi']),
      userIdOfRepresentative: _firstText(map, const <String>[
        'userIdOfRepresentative',
        'contractorRepresentative',
        'userId',
      ]),
      nameOfRepresentative: _text(map['nameOfRepresentative']),
      dateOfSubmission: _text(map['dateOfSubmission']),
      dateOfInspection: _text(map['dateOfInspection']),
      timeOfInspection: _text(map['timeOfInspection']),
      rfiDescriptionList: _idList(
        map['rfiDescriptionList'] ??
            map['rfiDescriptions'] ??
            map['selectedRfiDescriptions'],
      ),
      enclosuresList: _idList(map['enclosuresList'] ?? map['enclosures']),
      description: _text(map['description']),
      status: _text(map['status'] ?? map['rfiStatus']),
    );
    if (detail.id == null &&
        detail.project.isEmpty &&
        detail.contract.isEmpty &&
        detail.rfiId.isEmpty) {
      debugPrint('parseQualityRfiDetail: empty detail payload keys=${map.keys}');
      return null;
    }
    return detail;
  } on Object catch (error, stackTrace) {
    debugPrint('parseQualityRfiDetail failed: $error\n$stackTrace');
    return null;
  }
}

String? qualityRfiValidationMessage(QualityRfiSubmitDraft draft) {
  if (draft.project.trim().isEmpty) {
    return 'Please select a Project.';
  }
  if (draft.contract.trim().isEmpty) {
    return 'Please select a Contract.';
  }
  if (draft.structureType.trim().isEmpty) {
    return 'Please select a Structure Type.';
  }
  if (draft.structure.trim().isEmpty) {
    return 'Please select a Structure.';
  }
  if (draft.action.trim().isEmpty) {
    return 'Please select an Action.';
  }
  if (draft.contractorRepresentative.trim().isEmpty) {
    return "Please select Name of Contractor's Representative.";
  }
  if (workRfiApiDate(draft.dateOfInspection).isEmpty) {
    return 'Please select Date of Inspection.';
  }
  if (workRfiApiTime(draft.timeOfInspection).isEmpty) {
    return 'Please select Time of Inspection.';
  }
  return null;
}

Map<String, dynamic> buildQualityRfiPayload(QualityRfiSubmitDraft draft) {
  final String inspectionDate = workRfiApiDate(draft.dateOfInspection);
  final String submissionDate = draft.editing
      ? workRfiApiDate(draft.dateOfSubmission)
      : '';
  return <String, dynamic>{
    'project': draft.project.trim(),
    'contract': draft.contract.trim(),
    'structureType': draft.structureType.trim(),
    'structure': draft.structure.trim(),
    'action': draft.action.trim(),
    'typeOfRfi': draft.typeOfRfi.trim(),
    'contractorRepresentative': draft.contractorRepresentative.trim(),
    'dateOfSubmission': submissionDate,
    'timeOfInspection': workRfiApiTime(draft.timeOfInspection),
    'dateOfInspection': inspectionDate,
    'description': draft.description,
    'rfiDescriptions': draft.rfiDescriptions,
    'enclosures': draft.enclosures,
    'structureId': null,
  };
}

List<Map<String, dynamic>> _asMaps(dynamic data) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in <String>['data', 'content', 'list', 'items']) {
      final Object? nested = map[key];
      if (nested is List || nested is Map) {
        return _asMaps(nested);
      }
    }
    return <Map<String, dynamic>>[map];
  }
  return const <Map<String, dynamic>>[];
}

Map<String, dynamic>? _detailMap(dynamic data) {
  if (data is List) {
    for (final Object? item in data) {
      final Map<String, dynamic>? nested = _detailMap(item);
      if (nested != null) {
        return nested;
      }
    }
    return null;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in <String>['data', 'content', 'result', 'body']) {
      final Object? nested = map[key];
      if (nested is Map || nested is List) {
        final Map<String, dynamic>? unwrapped = _detailMap(nested);
        if (unwrapped != null) {
          return unwrapped;
        }
      }
    }
    return map;
  }
  return null;
}

List<QualityRfiOption> _dedupeOptions(List<QualityRfiOption> options) {
  final Set<String> seen = <String>{};
  final List<QualityRfiOption> unique = <QualityRfiOption>[];
  for (final QualityRfiOption option in options) {
    if (option.id.isEmpty || !seen.add(option.id)) {
      continue;
    }
    unique.add(option);
  }
  return unique;
}

String _text(Object? value) {
  if (value == null) {
    return '';
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

String _firstText(Map<String, dynamic> map, List<String> keys) {
  for (final String key in keys) {
    final String text = _text(map[key]);
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

int? _readId(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_text(value));
}

List<String> _idList(Object? value) {
  if (value is List) {
    return value
        .map((dynamic e) => _text(e))
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);
  }
  final String csv = _text(value);
  if (csv.isEmpty) {
    return const <String>[];
  }
  return csv
      .split(',')
      .map((String part) => part.trim())
      .where((String s) => s.isNotEmpty)
      .toList(growable: false);
}
