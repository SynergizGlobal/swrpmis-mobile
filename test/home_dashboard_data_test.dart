import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/domain/entities/home_dashboard_data.dart';

void main() {
  test('KPIs follow web: count, sum(length), sum(commissioned_length)', () {
    final HomeDashboardData data = HomeDashboardData.fromApiLists(
      projectList: <Map<String, dynamic>>[
        <String, dynamic>{
          'project_id': 'P01',
          'project_name': 'Tumkuru - Chitradurga - Davangere New Line Project',
          'project_type_name': 'New Lines',
          'length': null,
          'total_length': '191.05',
          'commissioned_length': null,
        },
      ],
      usersByType: const <Map<String, dynamic>>[],
      projectTypes: const <Map<String, dynamic>>[],
      projectListByType: const <Map<String, dynamic>>[],
    );

    expect(data.totalProjects, 1);
    expect(data.totalLengthKm, 0);
    expect(data.commissionedKm, 0);
  });

  test('org chart groups CAO, HOD and reporting DYHOD users', () {
    final HomeDashboardData data = HomeDashboardData.fromApiLists(
      projectList: const <Map<String, dynamic>>[],
      usersByType: <Map<String, dynamic>>[
        <String, dynamic>{
          'userId': 'PMIS_SU_001',
          'userName': 'ABHAY KUMAR SHARMA',
          'designation': 'CAO/CN/BNC',
          'userTypeFk': 'CAO',
          'reportingToIdSrfk': 'PMIS_SU_001',
          'projectCount': 1,
        },
        <String, dynamic>{
          'userId': 'PMIS_CE_001',
          'userName': 'CE One',
          'designation': 'CE/CN/III/BNC',
          'userTypeFk': 'HOD',
          'reportingToIdSrfk': 'PMIS_SU_001',
          'projectCount': 1,
        },
        <String, dynamic>{
          'userId': 'PMIS_DY_001',
          'userName': 'Dy CE',
          'designation': 'Dy. CE',
          'userTypeFk': 'DYHOD',
          'reportingToIdSrfk': 'PMIS_CE_001',
          'projectCount': 1,
        },
      ],
      projectTypes: <Map<String, dynamic>>[
        <String, dynamic>{
          'project_type_id': '1',
          'project_type_name': 'New Lines',
        },
      ],
      projectListByType: const <Map<String, dynamic>>[],
    );

    expect(data.caoUsers.single.designation, 'CAO/CN/BNC');
    expect(data.hodUsers.single.userId, 'PMIS_CE_001');
    expect(data.dyhodsReportingTo('PMIS_CE_001').single.userId, 'PMIS_DY_001');
    expect(data.projectTypes.single.name, 'New Lines');
  });

  test('org child is nested under its parent and is not a sibling of the root', () {
    final HomeDashboardData data = HomeDashboardData.fromApiLists(
      projectList: const <Map<String, dynamic>>[],
      usersByType: <Map<String, dynamic>>[
        <String, dynamic>{
          'userId': 'PMIS_SU_001',
          'designation': 'CAO/CN/BNC',
          'userTypeFk': 'CAO',
          'reportingToIdSrfk': 'PMIS_SU_001',
          'projectCount': 1,
        },
        <String, dynamic>{
          'userId': 'PMIS_CE_001',
          'designation': 'CE/CN/I/BNC',
          'userTypeFk': 'HOD',
          'reportingToIdSrfk': 'PMIS_SU_001',
          'projectCount': 0,
        },
        <String, dynamic>{
          'userId': 'PMIS_CE_002',
          'designation': 'CE/CN/II/BNC',
          'userTypeFk': 'HOD',
          'reportingToIdSrfk': 'PMIS_SU_001',
          'projectCount': 0,
        },
        <String, dynamic>{
          'userId': 'PMIS_DY_001',
          'designation': 'Dy.CE/CE1/CN/BNC',
          'userTypeFk': 'DYHOD',
          'reportingToIdSrfk': 'PMIS_CE_001',
          'projectCount': 0,
        },
        <String, dynamic>{
          'userId': 'PMIS_TL_001',
          'designation': 'TEAM LEADER',
          'userTypeFk': 'OTHER',
          'reportingToIdSrfk': 'PMIS_CE_001',
          'projectCount': 0,
        },
      ],
      projectTypes: const <Map<String, dynamic>>[],
      projectListByType: const <Map<String, dynamic>>[],
    );

    final List<OrgChartNode> forest = data.orgForest;
    expect(
      forest.map((OrgChartNode node) => node.user.userId),
      <String>['PMIS_SU_001'],
    );
    final OrgChartNode root = forest.single;
    expect(
      root.children.map((OrgChartNode node) => node.user.userId).toList(),
      <String>['PMIS_CE_001', 'PMIS_CE_002'],
    );
    expect(
      root.children.first.children
          .map((OrgChartNode node) => node.user.userId)
          .toList(),
      <String>['PMIS_DY_001', 'PMIS_TL_001'],
    );
    expect(root.children.last.children, isEmpty);
    expect(
      forest.map((OrgChartNode node) => node.user.userId),
      isNot(contains('PMIS_DY_001')),
    );
    expect(
      root.children.map((OrgChartNode node) => node.user.userId),
      isNot(contains('PMIS_DY_001')),
    );
  });

  test('missing parent ids follow CAO then HOD then DYHOD', () {
    final HomeDashboardData data = HomeDashboardData.fromApiLists(
      projectList: const <Map<String, dynamic>>[],
      usersByType: const <Map<String, dynamic>>[
        <String, dynamic>{
          'userId': 'CAO_1',
          'designation': 'CAO/CN/BNC',
          'userTypeFk': 'CAO',
          'projectCount': 1,
        },
        <String, dynamic>{
          'userId': 'HOD_1',
          'designation': 'CE/CN/I/BNC',
          'userTypeFk': 'HOD',
          'projectCount': 0,
        },
        <String, dynamic>{
          'userId': 'DY_1',
          'designation': 'Dy. CE',
          'userTypeFk': 'DYHOD',
          'projectCount': 0,
        },
      ],
      projectTypes: <Map<String, dynamic>>[],
      projectListByType: <Map<String, dynamic>>[],
    );

    final OrgChartNode root = data.orgForest.single;
    expect(root.user.userId, 'CAO_1');
    expect(root.children.single.user.userId, 'HOD_1');
    expect(root.children.single.children.single.user.userId, 'DY_1');
    expect(
      root.children.map((OrgChartNode node) => node.user.userId),
      isNot(contains('DY_1')),
    );
  });
}
