import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/land_acquisition_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/utility_shifting_report.dart';

void main() {
  test('detects Utility Shifting Report by formId, url, name', () {
    expect(
      isUtilityShiftingReport(
        formId: '1317',
        formName: 'Utility Shifting',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isUtilityShiftingReport(
        formId: '1401',
        formName: 'Utility Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isUtilityShiftingReport(
        formId: '',
        formName: 'Utility Shifting Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isUtilityShiftingReport(
        formId: '',
        formName: 'Other',
        webFormUrl: '/utility-report',
      ),
      isTrue,
    );
  });

  test('does not collide with Land Acquisition', () {
    expect(
      isUtilityShiftingReport(
        formId: '1316',
        formName: 'Land Acquisition Report',
        webFormUrl: 'la-report',
      ),
      isFalse,
    );
    expect(
      isLandAcquisitionReport(
        formId: '1316',
        formName: 'Land Acquisition Report',
        webFormUrl: 'la-report',
      ),
      isTrue,
    );
  });

  test('parses all four lists from GET /utility-report payload', () {
    final UtilityShiftingReportFilters filters =
        parseUtilityShiftingReportFilters(<String, dynamic>{
          'projectsList': <Map<String, dynamic>>[
            <String, dynamic>{
              'project_id_fk': 'P26',
              'project_name':
                  'Kazipet–Suryapet New Railway Line Project',
            },
          ],
          'executionAgency': <Map<String, dynamic>>[
            <String, dynamic>{'execution_agency_fk': 'MPPKVVCL'},
            <String, dynamic>{'execution_agency_fk': 'HPCL'},
            <String, dynamic>{'execution_agency_fk': 'SWR'},
          ],
          'impactedContractsList': <Map<String, dynamic>>[
            <String, dynamic>{
              'contract_id_fk': 'P01EN02',
              'contract_name': 'contract2 long',
              'contract_short_name': 'contract2',
              'project_id_fk': 'P26',
            },
          ],
          'utilityHODList': <Map<String, dynamic>>[
            <String, dynamic>{
              'hod_user_id_fk': 'PMIS_IU_039',
              'user_name': 'Sateesh Engineer',
              'designation': 'Engineer',
            },
          ],
        });

    expect(filters.projects.single.id, 'P26');
    expect(
      filters.projects.single.label,
      'P26 - Kazipet–Suryapet New Railway Line Project',
    );

    expect(
      filters.executionAgencies.map((ContractDetailOption o) => o.id).toList(),
      <String>['MPPKVVCL', 'HPCL', 'SWR'],
    );
    expect(filters.executionAgencies.first.label, 'MPPKVVCL');

    expect(filters.impactedContracts.single.id, 'P01EN02');
    expect(filters.impactedContracts.single.label, 'P01EN02 - contract2');

    expect(filters.hods.single.id, 'PMIS_IU_039');
    expect(filters.hods.single.label, 'Sateesh Engineer - Engineer');
  });

  test('parses nested data envelope and single-object lists', () {
    final UtilityShiftingReportFilters fromEnvelope =
        parseUtilityShiftingReportFilters(<String, dynamic>{
          'data': <String, dynamic>{
            'projectsList': <Map<String, dynamic>>[
              <String, dynamic>{
                'project_id_fk': 'P01',
                'project_name': 'Solo Project',
              },
            ],
            'executionAgency': <String, dynamic>{
              'execution_agency_fk': 'SWR',
            },
            'impactedContractsList': <Map<String, dynamic>>[
              <String, dynamic>{
                'contract_id_fk': 'C1',
                'contract_name': 'Full Name Only',
              },
            ],
            'utilityHODList': <Map<String, dynamic>>[
              <String, dynamic>{
                'hod_user_id_fk': 'U1',
                'user_name': 'Only Name',
              },
            ],
          },
        });

    expect(fromEnvelope.projects.single.label, 'P01 - Solo Project');
    expect(fromEnvelope.executionAgencies.single.label, 'SWR');
    expect(fromEnvelope.impactedContracts.single.label, 'C1 - Full Name Only');
    expect(fromEnvelope.hods.single.label, 'Only Name');
  });

  test('label builders match screenshot / API mapping', () {
    expect(
      buildUtilityShiftingProjectLabel(
        id: 'P26',
        projectName: 'Kazipet–Suryapet New Railway Line Project',
      ),
      'P26 - Kazipet–Suryapet New Railway Line Project',
    );
    expect(
      buildUtilityShiftingProjectLabel(
        id: 'P26',
        projectName: 'P26 - Already Prefixed',
      ),
      'P26 - Already Prefixed',
    );
    expect(buildUtilityShiftingExecutionAgencyLabel('MPPKVVCL'), 'MPPKVVCL');
    expect(
      buildUtilityShiftingImpactedContractLabel(
        contractId: 'P01EN02',
        shortName: 'contract2',
        contractName: 'ignored when short present',
      ),
      'P01EN02 - contract2',
    );
    expect(
      buildUtilityShiftingImpactedContractLabel(
        contractId: 'P01EN02',
        contractName: 'contract2',
      ),
      'P01EN02 - contract2',
    );
    expect(
      buildUtilityShiftingHodLabel(
        userName: 'Sateesh Engineer',
        designation: 'Engineer',
      ),
      'Sateesh Engineer - Engineer',
    );
  });

  test('documented generate body maps filter ids', () {
    expect(
      buildUtilityShiftingGenerateBody(
        projectId: 'P26',
        executionAgency: 'MPPKVVCL',
        contractId: 'P01EN02',
        hodUserId: 'PMIS_IU_039',
      ),
      <String, dynamic>{
        'project_id_fk': 'P26',
        'execution_agency_fk': 'MPPKVVCL',
        'contract_id_fk': 'P01EN02',
        'hod_user_id_fk': 'PMIS_IU_039',
      },
    );
  });
}
