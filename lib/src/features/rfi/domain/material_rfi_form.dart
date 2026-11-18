class MaterialRfiOption {
  const MaterialRfiOption({required this.id, required this.label});

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialRfiOption && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}

class MaterialRfiDetail {
  const MaterialRfiDetail({
    required this.projectId,
    required this.projectName,
    required this.contractId,
    required this.contractName,
    required this.itemId,
    required this.materials,
    required this.batchLotNo,
    required this.location,
    required this.action,
    required this.typeOfRfi,
    required this.representativeId,
    required this.representativeName,
    required this.dateOfSubmission,
    required this.dateOfInspection,
    required this.timeOfInspection,
    required this.rfiDescriptionList,
    required this.enclosuresList,
    required this.description,
    required this.materialQuantities,
    required this.status,
  });

  final String projectId;
  final String projectName;
  final String contractId;
  final String contractName;
  final int itemId;
  final List<MaterialRfiMaterial> materials;
  final String batchLotNo;
  final String location;
  final String action;
  final String typeOfRfi;
  final String representativeId;
  final String representativeName;
  final String dateOfSubmission;
  final String dateOfInspection;
  final String timeOfInspection;
  final List<String> rfiDescriptionList;
  final List<String> enclosuresList;
  final String description;
  final List<MaterialRfiQuantityRow> materialQuantities;
  final String status;
}

class MaterialRfiMaterial {
  const MaterialRfiMaterial({required this.id, required this.name});

  final int id;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialRfiMaterial && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class MaterialRfiQuantityRow {
  const MaterialRfiQuantityRow({
    required this.materialId,
    required this.materialName,
    this.quantity = '',
  });

  final int materialId;
  final String materialName;
  final String quantity;
}

List<MaterialRfiOption> parseMaterialRfiProjects(dynamic data) {
  return _uniqueOptions(<MaterialRfiOption>[
    for (final Map<String, dynamic> row in _asMaps(data))
      if (_text(row['projectId']).isNotEmpty)
        MaterialRfiOption(
          id: _text(row['projectId']),
          label: _text(row['projectName']).isEmpty
              ? _text(row['projectId'])
              : _text(row['projectName']),
        ),
  ]);
}

List<MaterialRfiOption> parseMaterialRfiContracts(dynamic data) {
  return _uniqueOptions(<MaterialRfiOption>[
    for (final Map<String, dynamic> row in _asMaps(data))
      if (_text(row['contractId']).isNotEmpty)
        MaterialRfiOption(
          id: _text(row['contractId']),
          label: _text(row['contractName']).isEmpty
              ? _text(row['contractId'])
              : _text(row['contractName']),
        ),
  ]);
}

List<MaterialRfiOption> parseMaterialRfiInspectionItems(dynamic data) {
  return _uniqueOptions(<MaterialRfiOption>[
    for (final Map<String, dynamic> row in _asMaps(data))
      if (_itemIdOf(row) != null)
        MaterialRfiOption(
          id: _itemIdOf(row)!.toString(),
          label: _text(row['itemName']).isEmpty
              ? _itemIdOf(row)!.toString()
              : _text(row['itemName']),
        ),
  ]);
}

List<MaterialRfiOption> parseMaterialRfiInspectionTypes(dynamic data) {
  return _uniqueOptions(<MaterialRfiOption>[
    for (final Map<String, dynamic> row in _asMaps(data))
      if (_text(row['type']).isNotEmpty)
        MaterialRfiOption(
          id: _text(row['type']),
          label: _text(row['type']),
        ),
  ]);
}

List<MaterialRfiMaterial> parseMaterialRfiMaterials(dynamic data) {
  final Set<int> seen = <int>{};
  final List<MaterialRfiMaterial> out = <MaterialRfiMaterial>[];
  for (final Map<String, dynamic> row in _asMaps(data)) {
    final int? id = _intOf(row['subCategoryId']);
    if (id == null || id <= 0 || !seen.add(id)) {
      continue;
    }
    final String name = _text(row['subCategoryName']);
    out.add(MaterialRfiMaterial(id: id, name: name.isEmpty ? '$id' : name));
  }
  return out;
}

List<MaterialRfiOption> parseMaterialRfiRepresentatives(dynamic data) {
  return _uniqueOptions(<MaterialRfiOption>[
    for (final Map<String, dynamic> row in _asMaps(data))
      if (_text(row['userId']).isNotEmpty)
        MaterialRfiOption(
          id: _text(row['userId']),
          label: _text(row['userName']).isEmpty
              ? _text(row['userId'])
              : _text(row['userName']),
        ),
  ]);
}

List<MaterialRfiOption> parseMaterialRfiDescriptions(dynamic data) {
  return _uniqueOptions(<MaterialRfiOption>[
    for (final Map<String, dynamic> row in _asMaps(data))
      if (_text(row['id']).isNotEmpty)
        MaterialRfiOption(
          id: _text(row['id']),
          label: _text(row['rfiDescription']).isEmpty
              ? _text(row['id'])
              : _text(row['rfiDescription']),
        ),
  ]);
}

List<MaterialRfiOption> parseMaterialRfiEnclosures(dynamic data) {
  return _uniqueOptions(<MaterialRfiOption>[
    for (final Map<String, dynamic> row in _asMaps(data))
      if (_text(row['id']).isNotEmpty)
        MaterialRfiOption(
          id: _text(row['id']),
          label: _text(row['encloserName'] ?? row['enclosureName']).isEmpty
              ? _text(row['id'])
              : _text(row['encloserName'] ?? row['enclosureName']),
        ),
  ]);
}

MaterialRfiDetail? parseMaterialRfiDetail(dynamic data) {
  final Map<String, dynamic>? map = _detailMap(data);
  if (map == null) {
    return null;
  }

  final List<MaterialRfiQuantityRow> quantities = <MaterialRfiQuantityRow>[];
  final List<MaterialRfiMaterial> materials = <MaterialRfiMaterial>[];

  if (map['materialsRfiList'] is List) {
    for (final dynamic m in map['materialsRfiList'] as List) {
      if (m is Map) {
        final int matId = _intOf(m['materialName']) ?? 0;
        final num? qty = m['inspectionQuantity'] is num
            ? m['inspectionQuantity'] as num
            : num.tryParse('${m['inspectionQuantity']}');
        final String qtyStr = qty != null ? qty.toStringAsFixed(0) : '';
        materials.add(MaterialRfiMaterial(id: matId, name: ''));
        quantities.add(
          MaterialRfiQuantityRow(
            materialId: matId,
            materialName: '',
            quantity: qtyStr,
          ),
        );
      }
    }
  }

  final String materialCsv = _text(map['material']);
  if (materials.isEmpty && materialCsv.isNotEmpty) {
    for (final String part in materialCsv.split(',')) {
      final int? id = int.tryParse(part.trim());
      if (id != null) {
        materials.add(MaterialRfiMaterial(id: id, name: ''));
      }
    }
  }

  return MaterialRfiDetail(
    projectId: _text(map['projectId']),
    projectName: _text(map['projectName']),
    contractId: _text(map['contractId']),
    contractName: _text(map['contractName']),
    itemId: _intOf(map['item']) ?? 0,
    materials: materials,
    batchLotNo: _text(map['batchLotNo']),
    location: _text(map['location']),
    action: _text(map['action']),
    typeOfRfi: _text(map['typeOfRFI']),
    representativeId: _text(map['userIdOfRepresentative']),
    representativeName: _text(map['nameOfRepresentative']),
    dateOfSubmission: _text(map['dateOfSubmission']),
    dateOfInspection: _text(map['dateOfInspection']),
    timeOfInspection: _text(map['timeOfInspection']),
    rfiDescriptionList: _textList(map['rfiDescriptionList']),
    enclosuresList: _textList(map['enclosuresList']),
    description: _text(map['description']),
    materialQuantities: quantities,
    status: _text(map['status']),
  );
}

List<MaterialRfiOption> _uniqueOptions(List<MaterialRfiOption> options) {
  final Set<String> seen = <String>{};
  return <MaterialRfiOption>[
    for (final MaterialRfiOption option in options)
      if (option.id.isNotEmpty && seen.add(option.id)) option,
  ];
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
  if (data is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    for (final String key in <String>['data', 'content', 'result']) {
      final Object? nested = map[key];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return map;
  }
  return null;
}

int? _itemIdOf(Map<String, dynamic> row) => _intOf(row['itemId']);

int? _intOf(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse('$value');
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

List<String> _textList(Object? value) {
  if (value is List) {
    return value
        .map((dynamic e) => _text(e))
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}
