class WorksProject {
  const WorksProject({
    required this.id,
    required this.name,
    required this.typeId,
  });

  final String id;
  final String name;
  final String typeId;

  factory WorksProject.fromJson(Map<String, dynamic> json) {
    return WorksProject(
      id: _text(json['project_id'] ?? json['projectId']),
      name: _text(json['project_name'] ?? json['projectName']),
      typeId: _id(json['project_type_id_fk'] ?? json['projectTypeIdFk']),
    );
  }
}

class WorksTypeSection {
  const WorksTypeSection({
    required this.id,
    required this.name,
    required this.projects,
  });

  final String id;
  final String name;
  final List<WorksProject> projects;
}

class WorksTree {
  const WorksTree({required this.sections});

  final List<WorksTypeSection> sections;

  bool get isEmpty => sections.isEmpty;

  factory WorksTree.fromApi({
    required List<Map<String, dynamic>> projectTypes,
    required List<Map<String, dynamic>> projects,
  }) {
    final List<WorksProject> parsed = projects
        .map(WorksProject.fromJson)
        .where((WorksProject project) => project.id.isNotEmpty)
        .toList(growable: false);

    final List<WorksTypeSection> sections = <WorksTypeSection>[];
    for (final Map<String, dynamic> type in projectTypes) {
      final String id = _id(type['project_type_id'] ?? type['id']);
      if (id.isEmpty) {
        continue;
      }
      final String name = _text(
        type['project_type_name'] ?? type['name'] ?? type['type_name'],
      );
      final List<WorksProject> matches = parsed
          .where((WorksProject project) => project.typeId == id)
          .toList(growable: false);
      sections.add(
        WorksTypeSection(
          id: id,
          name: name.isEmpty ? id : name,
          projects: matches,
        ),
      );
    }
    return WorksTree(sections: sections);
  }
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

String _id(Object? value) {
  final String text = _text(value);
  final num? number = num.tryParse(text);
  if (number != null && number == number.roundToDouble()) {
    return number.toInt().toString();
  }
  return text;
}
