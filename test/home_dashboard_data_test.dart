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
}
