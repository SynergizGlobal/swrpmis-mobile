enum RfiReferenceForm {
  enclosureList,
  checklist,
  description;

  String get label => switch (this) {
    RfiReferenceForm.enclosureList => 'RFI Enclosure List',
    RfiReferenceForm.checklist => 'Checklist Description',
    RfiReferenceForm.description => 'RFI Description',
  };
}

class RfiReferenceCategory {
  const RfiReferenceCategory._();

  static const String work = 'WORK';
  static const String material = 'MATERIAL';
  static const String quality = 'Quality/Safety';

  static const List<String> values = <String>[work, material, quality];
}

const List<String> rfiReferenceActions = <String>['Open', 'Upload'];

class RfiEnclosure {
  const RfiEnclosure({
    required this.id,
    required this.encloserName,
    required this.action,
    required this.rfiCategory,
    required this.usedInRfiDescription,
  });

  final int? id;
  final String encloserName;
  final String action;
  final String rfiCategory;
  final bool usedInRfiDescription;

  String get categoryLabel => rfiReferenceCategoryLabel(rfiCategory);

  String get actionLabel => rfiReferenceActionLabel(action);

  factory RfiEnclosure.fromJson(Map<String, dynamic> json) {
    return RfiEnclosure(
      id: _int(json['id']),
      encloserName: _text(json['encloserName']),
      action: _text(json['action']),
      rfiCategory: _text(json['rfiCategory']),
      usedInRfiDescription: _flag(json['usedInRfiDescription']),
    );
  }
}

class RfiEnclosureNameOption {
  const RfiEnclosureNameOption({required this.id, required this.label});

  final String id;
  final String label;
}

class RfiChecklistDescription {
  const RfiChecklistDescription({
    required this.id,
    required this.checklistDescription,
    required this.canBeDeleted,
  });

  final int? id;
  final String checklistDescription;
  final bool canBeDeleted;

  factory RfiChecklistDescription.fromJson(Map<String, dynamic> json) {
    return RfiChecklistDescription(
      id: _int(json['id']),
      checklistDescription: _text(
        json['checklistDescription'] ?? json['checkListDescription'],
      ),
      canBeDeleted: _flag(json['canBeDeleted']),
    );
  }
}

class RfiReferenceDescription {
  const RfiReferenceDescription({
    required this.id,
    required this.activity,
    required this.rfiDescription,
    required this.enclosureIds,
    required this.enclosures,
    required this.rfiCategory,
    required this.canDelete,
  });

  final int? id;
  final String activity;
  final String rfiDescription;
  final String enclosureIds;
  final String enclosures;
  final String rfiCategory;
  final bool canDelete;

  String get categoryLabel => rfiReferenceCategoryLabel(rfiCategory);

  List<String> get enclosureIdList => rfiReferenceSplitIds(enclosureIds);

  factory RfiReferenceDescription.fromJson(Map<String, dynamic> json) {
    return RfiReferenceDescription(
      id: _int(json['id']),
      activity: _text(json['activity']),
      rfiDescription: _text(json['rfiDescription']),
      enclosureIds: _idsText(json['enclosureIds']),
      enclosures: _text(json['enclosures']),
      rfiCategory: _text(json['rfiCategory']),
      canDelete: _flag(json['canDelete']),
    );
  }
}

class RfiChecklistSaveResult {
  const RfiChecklistSaveResult({
    required this.saved,
    required this.duplicateChecklistDescriptions,
  });

  final List<String> saved;
  final List<String> duplicateChecklistDescriptions;
}

class RfiDescriptionDeleteResult {
  const RfiDescriptionDeleteResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

List<RfiEnclosureNameOption> parseRfiEnclosureNames(dynamic data) {
  final List<RfiEnclosureNameOption> options = <RfiEnclosureNameOption>[];
  for (final Object? item in _nameItems(data)) {
    if (item is String) {
      final String text = _text(item);
      if (text.isEmpty) {
        continue;
      }
      options.add(RfiEnclosureNameOption(id: text, label: text));
      continue;
    }
    if (item is! Map) {
      continue;
    }
    final Map<String, dynamic> map = Map<String, dynamic>.from(item);
    final String id = _text(map['id']);
    final String label = _text(
      map['encloserName'] ?? map['enclosureName'] ?? map['name'],
    );
    if (id.isEmpty && label.isEmpty) {
      continue;
    }
    options.add(
      RfiEnclosureNameOption(
        id: id.isEmpty ? label : id,
        label: label.isEmpty ? id : label,
      ),
    );
  }
  return options;
}

Map<String, String> rfiReferenceDescriptionPayload({
  required String rfiCategory,
  required String activity,
  required String rfiDescription,
  required String enclosures,
}) {
  return <String, String>{
    'rfiCategory': rfiCategory,
    'activity': activity,
    'rfiDescription': rfiDescription,
    'enclosures': enclosures,
  };
}

String rfiReferenceActivityPayload(String? category, String typed) {
  if (rfiReferenceCategoryWire(category ?? '') == RfiReferenceCategory.work) {
    return typed.trim();
  }
  return '';
}

List<RfiEnclosure> parseRfiEnclosures(dynamic data) {
  return _maps(data, _isEnclosure, const <String>[
    'enclosures',
    'enclosureList',
  ]).map(RfiEnclosure.fromJson).toList(growable: false);
}

List<RfiChecklistDescription> parseRfiChecklistDescriptions(dynamic data) {
  return _maps(data, _isChecklist, const <String>[
    'checklistDescriptions',
    'checklists',
  ]).map(RfiChecklistDescription.fromJson).toList(growable: false);
}

List<RfiReferenceDescription> parseRfiDescriptions(dynamic data) {
  return _maps(data, _isDescription, const <String>[
    'descriptions',
  ]).map(RfiReferenceDescription.fromJson).toList(growable: false);
}

RfiChecklistSaveResult parseRfiChecklistSave(dynamic data) {
  if (data is! Map) {
    return const RfiChecklistSaveResult(
      saved: <String>[],
      duplicateChecklistDescriptions: <String>[],
    );
  }
  final Map<String, dynamic> map = Map<String, dynamic>.from(data);
  return RfiChecklistSaveResult(
    saved: _phrases(map['saved']),
    duplicateChecklistDescriptions: _phrases(
      map['duplicateChecklistDescriptions'],
    ),
  );
}

RfiDescriptionDeleteResult parseRfiDescriptionDelete(dynamic data) {
  if (data is! Map) {
    return const RfiDescriptionDeleteResult(
      success: true,
      message: 'RFI Description deleted successfully',
    );
  }
  final Map<String, dynamic> map = Map<String, dynamic>.from(data);
  final Object? success = map['success'];
  final bool ok =
      success == true || success?.toString().toLowerCase() == 'true';
  final String message = _text(map['message']);
  return RfiDescriptionDeleteResult(
    success: ok,
    message: message.isEmpty && ok
        ? 'RFI Description deleted successfully'
        : message,
  );
}

String? rfiReferenceCategoryWire(String raw) {
  final String text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  switch (text.toLowerCase().replaceAll(' ', '')) {
    case 'work':
      return RfiReferenceCategory.work;
    case 'material':
      return RfiReferenceCategory.material;
    case 'quality/safety':
    case 'qualitysafety':
      return RfiReferenceCategory.quality;
    default:
      return text;
  }
}

String rfiReferenceCategoryLabel(String raw) {
  return switch (rfiReferenceCategoryWire(raw)) {
    RfiReferenceCategory.work => 'Work',
    RfiReferenceCategory.material => 'Material',
    RfiReferenceCategory.quality => 'Quality/Safety',
    null => '',
    final String value => value,
  };
}

bool rfiReferenceSameCategory(String left, String right) {
  final String? a = rfiReferenceCategoryWire(left);
  final String? b = rfiReferenceCategoryWire(right);
  if (a == null || b == null) {
    return false;
  }
  if (RfiReferenceCategory.values.contains(a) &&
      RfiReferenceCategory.values.contains(b)) {
    return a == b;
  }
  return a.toLowerCase() == b.toLowerCase();
}

String? rfiReferenceActionWire(String raw) {
  final String text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  for (final String option in rfiReferenceActions) {
    if (option.toLowerCase() == text.toLowerCase()) {
      return option;
    }
  }
  return text;
}

String rfiReferenceActionLabel(String raw) {
  return rfiReferenceActionWire(raw) ?? '';
}

List<String> rfiReferenceSplitIds(String raw) {
  return raw
      .split(',')
      .map((String part) => part.trim())
      .where((String part) => part.isNotEmpty)
      .toList(growable: false);
}

String rfiReferenceJoinIds(Iterable<String> ids) {
  return ids
      .map((String id) => id.trim())
      .where((String id) => id.isNotEmpty)
      .join(',');
}

List<Object?> _nameItems(dynamic data) {
  if (data is List) {
    return data;
  }
  if (data is String) {
    return <Object?>[data];
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in <String>[
      ..._wrapperKeys,
      'enclosures',
      'names',
      'enclosureNames',
    ]) {
      final Object? nested = map[key];
      if (nested is List || nested is Map || nested is String) {
        final List<Object?> found = _nameItems(nested);
        if (found.isNotEmpty) {
          return found;
        }
      }
    }
    if (map.containsKey('id') ||
        map.containsKey('encloserName') ||
        map.containsKey('enclosureName') ||
        map.containsKey('name')) {
      return <Object?>[map];
    }
  }
  return const <Object?>[];
}

const List<String> _wrapperKeys = <String>[
  'data',
  'result',
  'content',
  'list',
  'records',
  'items',
];

List<Map<String, dynamic>> _maps(
  dynamic data,
  bool Function(Map<String, dynamic> map) isRow,
  List<String> extraKeys,
) {
  if (data is List) {
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    for (final Object? item in data) {
      rows.addAll(_maps(item, isRow, extraKeys));
    }
    return rows;
  }
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in <String>[..._wrapperKeys, ...extraKeys]) {
      final Object? nested = map[key];
      if (nested is List || nested is Map) {
        final List<Map<String, dynamic>> found = _maps(
          nested,
          isRow,
          extraKeys,
        );
        if (found.isNotEmpty) {
          return found;
        }
      }
    }
    if (isRow(map)) {
      return <Map<String, dynamic>>[map];
    }
  }
  return const <Map<String, dynamic>>[];
}

bool _isEnclosure(Map<String, dynamic> map) {
  return map.containsKey('encloserName');
}

bool _isChecklist(Map<String, dynamic> map) {
  return map.containsKey('checklistDescription') ||
      map.containsKey('checkListDescription');
}

bool _isDescription(Map<String, dynamic> map) {
  return map.containsKey('rfiDescription') || map.containsKey('enclosureIds');
}

List<String> _phrases(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  final List<String> phrases = <String>[];
  for (final Object? item in value) {
    if (item is Map) {
      final String text = _text(
        item['checklistDescription'] ??
            item['checkListDescription'] ??
            item['description'] ??
            item['message'],
      );
      if (text.isNotEmpty) {
        phrases.add(text);
      }
      continue;
    }
    final String text = _text(item);
    if (text.isNotEmpty) {
      phrases.add(text);
    }
  }
  return phrases;
}

String _idsText(Object? value) {
  if (value is List) {
    return rfiReferenceJoinIds(value.map((Object? item) => _text(item)));
  }
  return _text(value);
}

String _text(Object? value) {
  if (value == null) {
    return '';
  }
  final String text = value.toString().trim();
  if (text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

int? _int(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final String text = value.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return int.tryParse(text);
  }
  return null;
}

bool _flag(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final String text = value.trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }
  return false;
}
