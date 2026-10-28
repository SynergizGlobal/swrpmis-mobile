class StructureOption {
  const StructureOption({required this.value, required this.label});

  final String value;
  final String label;
}

class StructureTypeCount {
  const StructureTypeCount({
    required this.structureType,
    required this.count,
  });

  final String structureType;
  final int count;

  String get displayLabel {
    final String type = structureType.trim();
    if (type.isEmpty) {
      return count.toString();
    }
    return '$type - $count';
  }
}

class StructureSummaryRow {
  const StructureSummaryRow({
    required this.projectId,
    required this.structureTypes,
  });

  final String projectId;
  final List<StructureTypeCount> structureTypes;
}

class StructureListQuery {
  const StructureListQuery({
    this.projectId = '',
    this.search = '',
  });

  final String projectId;
  final String search;

  StructureListQuery copyWith({
    String? projectId,
    String? search,
  }) {
    return StructureListQuery(
      projectId: projectId ?? this.projectId,
      search: search ?? this.search,
    );
  }
}

class StructureListSnapshot {
  const StructureListSnapshot({
    this.rows = const <StructureSummaryRow>[],
    this.projects = const <StructureOption>[],
  });

  static const StructureListSnapshot empty = StructureListSnapshot();

  final List<StructureSummaryRow> rows;
  final List<StructureOption> projects;
}

bool structureRowMatches(StructureSummaryRow row, StructureListQuery query) {
  final String projectFilter = query.projectId.trim();
  if (projectFilter.isNotEmpty && row.projectId.trim() != projectFilter) {
    return false;
  }
  final String search = query.search.trim().toLowerCase();
  if (search.isEmpty) {
    return true;
  }
  if (row.projectId.toLowerCase().contains(search)) {
    return true;
  }
  for (final StructureTypeCount item in row.structureTypes) {
    if (item.structureType.toLowerCase().contains(search) ||
        item.displayLabel.toLowerCase().contains(search)) {
      return true;
    }
  }
  return false;
}
