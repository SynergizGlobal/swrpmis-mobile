import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/activities_export_option.dart';

void main() {
  test('detects Contract-wise Activities report from menu fields', () {
    expect(
      isActivitiesExportReport(
        formId: '1319',
        formName: 'Contract-wise Activities',
        webFormUrl: 'activities-export-report',
      ),
      isTrue,
    );
    expect(
      isActivitiesExportReport(
        formId: '999',
        formName: 'Other',
        webFormUrl: 'la-report',
      ),
      isFalse,
    );
    expect(
      isActivitiesExportReport(
        formId: '',
        formName: 'TPC',
        webFormUrl: '/api/activities-export/tpc-status-report',
      ),
      isFalse,
    );
    expect(
      isActivitiesExportReport(
        formId: '',
        formName: 'Station Improvement Progress Report',
        webFormUrl: '/api/activities-export/station-improvements-report',
      ),
      isFalse,
    );
  });

  test('parses projects and contracts from sample API rows', () {
    final List<ActivitiesExportProject> projects = parseActivitiesExportProjects(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'project_id': 'P01',
          'project_name': 'Bengaluru Railway Projects',
          'contract_id': null,
        },
      ],
    );
    expect(projects, hasLength(1));
    expect(projects.single.projectId, 'P01');
    expect(projects.single.label, 'Bengaluru Railway Projects');

    final List<ActivitiesExportContract> contracts =
        parseActivitiesExportContracts(<Map<String, dynamic>>[
          <String, dynamic>{
            'contract_id_fk': 'P02EN03',
            'project_id_fk': 'P02',
            'project_name': 'Panna - Kajuraho Section New B.G. Line Project',
            'contract_short_name':
                'Earthwork, Minor and Major bridges bwn Ch: 120.0KM',
          },
        ]);
    expect(contracts, hasLength(1));
    expect(contracts.single.contractId, 'P02EN03');
    expect(contracts.single.projectId, 'P02');
    expect(
      contracts.single.label,
      'Earthwork, Minor and Major bridges bwn Ch: 120.0KM',
    );
  });

  test('parses a single object payload as one option', () {
    final List<ActivitiesExportProject> projects = parseActivitiesExportProjects(
      <String, dynamic>{
        'project_id': 'P01',
        'project_name': 'Bengaluru Railway Projects',
      },
    );
    expect(projects.single.projectId, 'P01');
  });
}
