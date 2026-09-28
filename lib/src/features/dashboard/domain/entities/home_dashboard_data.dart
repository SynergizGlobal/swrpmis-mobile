class HomeDashboardData {
  const HomeDashboardData({
    required this.totalProjects,
    required this.totalLengthKm,
    required this.commissionedKm,
    required this.orgUsers,
    required this.projects,
    required this.projectTypes,
    required this.projectsByType,
  });

  final int totalProjects;
  final double totalLengthKm;
  final double commissionedKm;

  final List<DashboardOrgUser> orgUsers;
  final List<DashboardProject> projects;
  final List<DashboardProjectType> projectTypes;
  final List<DashboardProject> projectsByType;

  List<DashboardOrgUser> get caoUsers => _byType('CAO');

  List<DashboardOrgUser> get hodUsers => _byType('HOD');

  List<DashboardOrgUser> get dyhodUsers => _byType('DYHOD');

  List<DashboardOrgUser> get otherUsers {
    return orgUsers
        .where(
          (DashboardOrgUser user) =>
              user.userTypeFk != 'CAO' &&
              user.userTypeFk != 'HOD' &&
              user.userTypeFk != 'DYHOD',
        )
        .toList(growable: false);
  }

  List<DashboardOrgUser> dyhodsReportingTo(String userId) {
    return dyhodUsers
        .where((DashboardOrgUser user) => user.reportingToId == userId)
        .toList(growable: false);
  }

  List<DashboardOrgUser> _byType(String type) {
    return orgUsers
        .where((DashboardOrgUser user) => user.userTypeFk == type)
        .toList(growable: false);
  }

  factory HomeDashboardData.fromApiLists({
    required List<Map<String, dynamic>> projectList,
    required List<Map<String, dynamic>> usersByType,
    required List<Map<String, dynamic>> projectTypes,
    required List<Map<String, dynamic>> projectListByType,
  }) {
    final List<DashboardProject> projects = projectList
        .map(DashboardProject.fromJson)
        .where((DashboardProject item) => item.projectId.isNotEmpty)
        .toList(growable: false);
    return HomeDashboardData(
      totalProjects: projects.length,
      totalLengthKm: projects.fold<double>(
        0,
        (double sum, DashboardProject item) => sum + item.lengthKm,
      ),
      commissionedKm: projects.fold<double>(
        0,
        (double sum, DashboardProject item) => sum + item.commissionedLengthKm,
      ),
      orgUsers: DashboardOrgUser.uniqueFromRows(usersByType),
      projects: projects,
      projectTypes: projectTypes
          .map(DashboardProjectType.fromJson)
          .where((DashboardProjectType item) => item.id.isNotEmpty)
          .toList(growable: false),
      projectsByType: projectListByType
          .map(DashboardProject.fromJson)
          .where((DashboardProject item) => item.projectId.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class DashboardProjectType {
  const DashboardProjectType({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory DashboardProjectType.fromJson(Map<String, dynamic> json) {
    return DashboardProjectType(
      id: _read(json, const <String>['project_type_id', 'id']),
      name: _read(
        json,
        const <String>['project_type_name', 'name', 'type_name'],
      ),
    );
  }
}

class DashboardProject {
  const DashboardProject({
    required this.projectId,
    required this.projectName,
    required this.projectTypeId,
    required this.projectTypeName,
    required this.status,
    required this.lengthKm,
    required this.commissionedLengthKm,
    required this.structureType,
    required this.scope,
    required this.completed,
  });

  final String projectId;
  final String projectName;
  final String projectTypeId;
  final String projectTypeName;
  final String status;
  final double lengthKm;
  final double commissionedLengthKm;
  final String structureType;
  final String scope;
  final String completed;

  factory DashboardProject.fromJson(Map<String, dynamic> json) {
    return DashboardProject(
      projectId: _read(json, const <String>['project_id', 'projectId']),
      projectName: _read(json, const <String>['project_name', 'projectName']),
      projectTypeId: _read(
        json,
        const <String>[
          'project_type_id_fk',
          'project_type_id',
          'projectTypeIdFk',
          'projectTypeId',
        ],
      ),
      projectTypeName: _read(
        json,
        const <String>['project_type_name', 'projectTypeName'],
      ),
      status: _read(json, const <String>['project_status', 'status']),
      lengthKm: _toDouble(json['length']),
      commissionedLengthKm: _toDouble(json['commissioned_length']),
      structureType: _read(
        json,
        const <String>['structure_type', 'structureType'],
      ),
      scope: _read(json, const <String>['scope']),
      completed: _read(json, const <String>['completed']),
    );
  }
}

class DashboardOrgUser {
  const DashboardOrgUser({
    required this.userId,
    required this.userName,
    required this.designation,
    required this.userTypeFk,
    required this.reportingToId,
    required this.projectCount,
    required this.projectName,
  });

  final String userId;
  final String userName;
  final String designation;
  final String userTypeFk;
  final String reportingToId;
  final int projectCount;
  final String projectName;

  static List<DashboardOrgUser> uniqueFromRows(
    List<Map<String, dynamic>> rows,
  ) {
    final Map<String, DashboardOrgUser> byId = <String, DashboardOrgUser>{};
    final List<String> order = <String>[];
    for (final Map<String, dynamic> row in rows) {
      final DashboardOrgUser user = DashboardOrgUser.fromJson(row);
      if (user.userId.isEmpty) {
        continue;
      }
      final DashboardOrgUser? existing = byId[user.userId];
      if (existing == null) {
        order.add(user.userId);
        byId[user.userId] = user;
      } else if (user.projectCount > existing.projectCount) {
        byId[user.userId] = user;
      }
    }
    return order
        .map((String id) => byId[id]!)
        .toList(growable: false);
  }

  factory DashboardOrgUser.fromJson(Map<String, dynamic> json) {
    return DashboardOrgUser(
      userId: _read(json, const <String>['userId', 'user_id']),
      userName: _read(json, const <String>['userName', 'user_name']),
      designation: _read(json, const <String>['designation']),
      userTypeFk: _read(
        json,
        const <String>['userTypeFk', 'user_type_fk'],
      ).toUpperCase(),
      reportingToId: _read(
        json,
        const <String>['reportingToIdSrfk', 'reporting_to_id_srfk'],
      ),
      projectCount: _toInt(json['projectCount'] ?? json['project_count']),
      projectName: _read(
        json,
        const <String>['projectName', 'project_name'],
      ),
    );
  }
}

String _read(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final Object? value = json[key];
    if (value == null) {
      continue;
    }
    final String text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

double _toDouble(Object? value) {
  if (value == null) {
    return 0;
  }
  return double.tryParse(value.toString().trim()) ?? 0;
}

int _toInt(Object? value) {
  if (value == null) {
    return 0;
  }
  return int.tryParse(value.toString().trim().split('.').first) ?? 0;
}
