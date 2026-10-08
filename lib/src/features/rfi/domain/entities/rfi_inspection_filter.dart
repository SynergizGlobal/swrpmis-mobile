import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_catalog.dart';

class RfiInspectionFilter {
  const RfiInspectionFilter({
    this.rfiCategory,
    this.projectId,
    this.contractId,
    this.structureType,
    this.structureId,
    this.itemId,
    this.materialId,
    this.qualityOrSafetyId,
  });

  final String? rfiCategory;
  final String? projectId;
  final String? contractId;
  final String? structureType;
  final int? structureId;
  final int? itemId;
  final int? materialId;
  final int? qualityOrSafetyId;

  static const int categoryIndex = 0;
  static const int projectIndex = 1;
  static const int contractIndex = 2;
  static const int structureTypeIndex = 3;
  static const int structureIndex = 4;
  static const int itemIndex = 5;
  static const int materialIndex = 6;
  static const int qualityIndex = 7;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rfiCategory': rfiCategory,
      'projectId': projectId,
      'contractId': contractId,
      'structureType': structureType,
      'structureId': structureId,
      'itemId': itemId,
      'materialId': materialId,
      'qualityOrSafetyId': qualityOrSafetyId,
    };
  }

  factory RfiInspectionFilter.fromJson(Map<String, dynamic> json) {
    return RfiInspectionFilter(
      rfiCategory: _stringOrNull(json['rfiCategory']),
      projectId: _stringOrNull(json['projectId']),
      contractId: _stringOrNull(json['contractId']),
      structureType: _stringOrNull(json['structureType']),
      structureId: _intOrNull(json['structureId']),
      itemId: _intOrNull(json['itemId']),
      materialId: _intOrNull(json['materialId']),
      qualityOrSafetyId: _intOrNull(json['qualityOrSafetyId']),
    );
  }

  RfiInspectionFilter withCategory(String? category) {
    return RfiInspectionFilter(
      rfiCategory: category,
      projectId: projectId,
      contractId: contractId,
    );
  }

  RfiInspectionFilter selectAt(int index, {String? text, int? number}) {
    return RfiInspectionFilter(
      rfiCategory: index > categoryIndex
          ? rfiCategory
          : (index == categoryIndex ? text : null),
      projectId: index > projectIndex
          ? projectId
          : (index == projectIndex ? text : null),
      contractId: index > contractIndex
          ? contractId
          : (index == contractIndex ? text : null),
      structureType: index > structureTypeIndex
          ? structureType
          : (index == structureTypeIndex ? text : null),
      structureId: index > structureIndex
          ? structureId
          : (index == structureIndex ? number : null),
      itemId: index > itemIndex ? itemId : (index == itemIndex ? number : null),
      materialId: index > materialIndex
          ? materialId
          : (index == materialIndex ? number : null),
      qualityOrSafetyId: index > qualityIndex
          ? qualityOrSafetyId
          : (index == qualityIndex ? number : null),
    );
  }

  RfiInspectionFilter retainValid(RfiInspectionCatalog catalog) {
    return RfiInspectionFilter(
      rfiCategory: _keepText(rfiCategory, catalog.categories),
      projectId: _keepText(projectId, catalog.projects),
      contractId: _keepText(contractId, catalog.contracts),
      structureType: _keepText(structureType, catalog.structureTypes),
      structureId: _keepNumber(structureId, catalog.structures),
      itemId: _keepNumber(itemId, catalog.items),
      materialId: _keepNumber(materialId, catalog.materials),
      qualityOrSafetyId: _keepNumber(qualityOrSafetyId, catalog.qualitySafety),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RfiInspectionFilter &&
        other.rfiCategory == rfiCategory &&
        other.projectId == projectId &&
        other.contractId == contractId &&
        other.structureType == structureType &&
        other.structureId == structureId &&
        other.itemId == itemId &&
        other.materialId == materialId &&
        other.qualityOrSafetyId == qualityOrSafetyId;
  }

  @override
  int get hashCode => Object.hash(
    rfiCategory,
    projectId,
    contractId,
    structureType,
    structureId,
    itemId,
    materialId,
    qualityOrSafetyId,
  );
}

String? _keepText(String? value, List<RfiFilterOption> options) {
  if (value == null) {
    return null;
  }
  for (final RfiFilterOption option in options) {
    if (option.id == value) {
      return value;
    }
  }
  return null;
}

int? _keepNumber(int? value, List<RfiFilterOption> options) {
  if (value == null) {
    return null;
  }
  for (final RfiFilterOption option in options) {
    if (option.numberId == value) {
      return value;
    }
  }
  return null;
}

String? _stringOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  final String text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

int? _intOrNull(Object? value) {
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
