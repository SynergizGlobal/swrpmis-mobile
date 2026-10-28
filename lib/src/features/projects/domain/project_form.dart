import 'package:swr_pmis_mobile/src/features/projects/domain/project_list.dart';

class ProjectFormMaster {
  const ProjectFormMaster({
    this.projectTypes = const <ProjectOption>[],
    this.railwayZones = const <ProjectOption>[],
    this.years = const <ProjectOption>[],
    this.divisions = const <ProjectOption>[],
    this.sections = const <ProjectOption>[],
  });

  static const ProjectFormMaster empty = ProjectFormMaster();

  final List<ProjectOption> projectTypes;
  final List<ProjectOption> railwayZones;
  final List<ProjectOption> years;
  final List<ProjectOption> divisions;
  final List<ProjectOption> sections;

  ProjectFormMaster copyWith({
    List<ProjectOption>? projectTypes,
    List<ProjectOption>? railwayZones,
    List<ProjectOption>? years,
    List<ProjectOption>? divisions,
    List<ProjectOption>? sections,
  }) {
    return ProjectFormMaster(
      projectTypes: projectTypes ?? this.projectTypes,
      railwayZones: railwayZones ?? this.railwayZones,
      years: years ?? this.years,
      divisions: divisions ?? this.divisions,
      sections: sections ?? this.sections,
    );
  }
}

class ProjectFormPrefill {
  const ProjectFormPrefill({this.row});

  static const ProjectFormPrefill empty = ProjectFormPrefill();

  final ProjectRow? row;

  factory ProjectFormPrefill.fromRow(ProjectRow row) {
    return ProjectFormPrefill(row: row);
  }
}

DateTime? parseProjectFormDate(String? raw) {
  final String text = (raw ?? '').trim();
  if (text.isEmpty) {
    return null;
  }
  final DateTime? iso = DateTime.tryParse(text);
  if (iso != null) {
    return DateTime(iso.year, iso.month, iso.day);
  }
  final List<String> parts = text.split(RegExp(r'[/-]'));
  if (parts.length == 3) {
    final int? a = int.tryParse(parts[0]);
    final int? b = int.tryParse(parts[1]);
    final int? c = int.tryParse(parts[2]);
    if (a != null && b != null && c != null) {
      if (parts[0].length == 4) {
        return DateTime(a, b, c);
      }
      if (parts[2].length == 4) {
        return DateTime(c, b, a);
      }
    }
  }
  return null;
}

String formatProjectApiDate(DateTime? date) {
  if (date == null) {
    return '';
  }
  final String y = date.year.toString().padLeft(4, '0');
  final String m = date.month.toString().padLeft(2, '0');
  final String d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

num? parseProjectNumber(String? raw) {
  final String text = (raw ?? '').trim().replaceAll(',', '');
  if (text.isEmpty) {
    return null;
  }
  return num.tryParse(text);
}
