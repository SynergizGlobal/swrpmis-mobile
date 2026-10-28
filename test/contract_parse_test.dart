import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/contracts/domain/contract_parse.dart';

void main() {
  test('parseContractList reads DataTables aaData', () {
    final ({List rows, int total}) parsed = parseContractList(<String, dynamic>{
      'iTotalDisplayRecords': 2,
      'iTotalRecords': 2,
      'aaData': <Map<String, dynamic>>[
        <String, dynamic>{
          'contract_id_fk': 'P01EN01',
          'project_id_fk': 'P01',
          'project_name': 'Itarsi - Bhopal',
          'contract_short_name': 'Important Bridges',
          'contract_name': 'EPC Contract',
          'contractor_name': 'M/s Demo',
          'department_name': 'Engineering',
          'designation': 'CE/CN',
          'dy_hod': 'Dy.CE',
          'last_update': '2026-10-01',
        },
        <String, dynamic>{
          'contract_id': 'P02CN01',
          'project_id_fk': 'P02',
          'contract_name': 'OHE works',
        },
      ],
    });

    expect(parsed.total, 2);
    expect(parsed.rows, hasLength(2));
    expect(parsed.rows.first.contractId, 'P01EN01');
    expect(parsed.rows.first.nameDisplay, 'Important Bridges');
    expect(parsed.rows.first.projectDisplay, 'P01 - Itarsi - Bhopal');
    expect(parsed.rows.last.contractId, 'P02CN01');
  });

  test('parseContractFormMaster reads known list keys', () {
    final master = parseContractFormMaster(<String, dynamic>{
      'projectsList': <Map<String, dynamic>>[
        <String, dynamic>{
          'project_id_fk': 'P03',
          'project_name': 'Sidhi - Singrauli',
        },
      ],
      'departmentList': <Map<String, dynamic>>[
        <String, dynamic>{
          'department_fk': 'EN',
          'department_name': 'Engineering',
        },
      ],
      'hodList': <Map<String, dynamic>>[
        <String, dynamic>{
          'user_id': 'U1',
          'user_name': 'PREM NARAYAN',
          'designation': 'CE/CN/II/BNC',
        },
      ],
      'contractors': <Map<String, dynamic>>[
        <String, dynamic>{
          'contractor_id_fk': 'C1',
          'contractor_name': 'M/s ABC',
        },
      ],
      'contract_Status': <Map<String, dynamic>>[
        <String, dynamic>{'contract_status': 'Awarded'},
      ],
      'contract_type': <Map<String, dynamic>>[
        <String, dynamic>{'contract_type': 'EPC'},
      ],
      'unitsList': <Map<String, dynamic>>[
        <String, dynamic>{'unit': 'Lakh'},
      ],
    });

    expect(master.projects.single.id, 'P03');
    expect(master.departments.single.label, 'Engineering');
    expect(master.hods.single.id, 'U1');
    expect(master.contractors.single.label, 'M/s ABC');
    expect(master.contractStatuses.single.id, 'Awarded');
    expect(master.contractTypes.single.id, 'EPC');
    expect(master.units.single.id, 'Lakh');
  });

  test('parseContractProjects builds id-name labels', () {
    final options = parseContractProjects(<Map<String, dynamic>>[
      <String, dynamic>{
        'project_id_fk': 'P01',
        'project_name': '4th Line',
      },
    ]);
    expect(options.single.value, 'P01');
    expect(options.single.label, 'P01 - 4th Line');
  });
}
