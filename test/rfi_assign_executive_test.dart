import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_assign_executive.dart';

void main() {
  test('parses project names', () {
    final List<RfiAssignProject> projects = parseRfiAssignProjects(<dynamic>[
      <String, dynamic>{
        'projectName': '4th Line between Itarsi - Bhopal - Bina',
        'projectId': 'P01',
      },
      <String, dynamic>{
        'projectName': 'Panna - Kajuraho Section New B.G. Line Project',
        'projectId': 'P02',
      },
    ]);

    expect(projects, hasLength(2));
    expect(projects.first.projectId, 'P01');
    expect(
      projects.first.projectName,
      '4th Line between Itarsi - Bhopal - Bina',
    );
    expect(projects.first.label, projects.first.projectName);
    expect(projects.last.projectId, 'P02');
  });

  test('parses a single contract object and a contract list', () {
    const Map<String, dynamic> sample = <String, dynamic>{
      'contractIdFk': 'P02EN13',
      'dyHodUserId': 'PMIS_SU_009',
      'contractShortName':
          'Civil Works at Panna-Ranipur and Ghat Section-Ranipur-Ajaygarh',
    };

    final List<RfiAssignContract> one = parseRfiAssignContracts(sample);
    final List<RfiAssignContract> many = parseRfiAssignContracts(<dynamic>[
      sample,
      <String, dynamic>{
        'contractIdFk': 'P02EN14',
        'dyHodUserId': 'PMIS_SU_010',
        'contractShortName': 'Second contract',
      },
    ]);

    expect(one, hasLength(1));
    expect(one.single.contractIdFk, 'P02EN13');
    expect(
      one.single.contractShortName,
      'Civil Works at Panna-Ranipur and Ghat Section-Ranipur-Ajaygarh',
    );
    expect(one.single.label, one.single.contractShortName);
    expect(many, hasLength(2));
    expect(many.first.contractIdFk, 'P02EN13');
    expect(many.last.contractIdFk, 'P02EN14');
    expect(many.last.contractShortName, 'Second contract');
  });

  test('parses assigned executive logs and keeps the executives string', () {
    final List<RfiAssignExecutiveLog>
    rows = parseRfiAssignExecutiveLogs(<dynamic>[
      <String, dynamic>{
        'id': 76,
        'contract': 'contract1',
        'structureType': 'Important Bridge',
        'structure': '71 (Open web Girder)',
        'assignedExecutive': 'Shivendra kumar pandey,Umakant Singh',
      },
      <String, dynamic>{
        'id': 77,
        'contract':
            'New Broad gauge line Between KM 25.4 & KM 66.4 (41.0 KM) in Tumkur-Chitradurga-Davangere project',
        'structureType': 'Blanketing',
        'structure': 'CH 25400 to CH 34000',
        'assignedExecutive': 'IT Test Engineer',
      },
    ]);

    expect(rows, hasLength(2));
    expect(rows.first.id, 76);
    expect(rows.first.contract, 'contract1');
    expect(rows.first.structureType, 'Important Bridge');
    expect(rows.first.structure, '71 (Open web Girder)');
    expect(
      rows.first.assignedExecutive,
      'Shivendra kumar pandey,Umakant Singh',
    );
    expect(rows.last.id, 77);
    expect(rows.last.structureType, 'Blanketing');
    expect(rows.last.assignedExecutive, 'IT Test Engineer');
    expect(
      ApiConstants.rfiAssignedExecutiveLogsPath,
      '/rfi/getAssinedExecutiveLogs',
    );
    expect(
      ApiConstants.rfiAssignExecutiveDeletePath(76),
      '/rfi/assignExecutive/delete/76',
    );
  });
}
