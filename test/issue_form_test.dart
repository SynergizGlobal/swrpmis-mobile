import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/issues/domain/issue_form.dart';

void main() {
  test('issue detail parses nulls, numeric ids, and extra scalars', () {
    final IssueDetail detail = parseIssueDetail(<String, dynamic>{
      'issue_id': 44,
      'project_id_fk': null,
      'contract_id_fk': 'P01EN01',
      'title': 'Leak at pier',
      'description': null,
      'date': '2026-01-02',
      'location': null,
      'priority_fk': 3,
      'category_fk': 'Civil',
      'status_fk': null,
      'status': 'Open',
      'reported_by': 'Ada',
      'reported_by_user_id': 15,
      'responsible_person': null,
      'responsible_person_user_id': 'PMIS_SU_014',
      'department_fk': 'CON',
      'zonal_railway_fk': 7,
      'other_organization': 'State PWD',
      'other_org_resposible_person_name': 'Ravi',
      'other_org_resposible_person_designation': 'EE',
      'structure': 'Bridge 1',
      'component': 'Pier',
      'corrective_measure': 'Inspected',
      'escalated_to': null,
      'escalated_to_user_id': 'PMIS_SU_020',
      'remarks': '',
      'hod_user_id_fk': 'PMIS_SU_001',
      'latitude': '12.97',
      'longitude': null,
    });

    expect(detail.issueId, '44');
    expect(detail.projectIdFk, isEmpty);
    expect(detail.contractIdFk, 'P01EN01');
    expect(detail.title, 'Leak at pier');
    expect(detail.description, isEmpty);
    expect(detail.date, '2026-01-02');
    expect(detail.location, isEmpty);
    expect(detail.priorityFk, '3');
    expect(detail.categoryFk, 'Civil');
    expect(detail.statusFk, 'Open');
    expect(detail.reportedBy, 'Ada');
    expect(detail.reportedByUserId, '15');
    expect(detail.responsiblePerson, isEmpty);
    expect(detail.responsiblePersonUserId, 'PMIS_SU_014');
    expect(detail.departmentFk, 'CON');
    expect(detail.zonalRailwayFk, '7');
    expect(detail.otherOrganization, 'State PWD');
    expect(detail.otherOrgResponsiblePersonName, 'Ravi');
    expect(detail.otherOrgResponsiblePersonDesignation, 'EE');
    expect(detail.structure, 'Bridge 1');
    expect(detail.component, 'Pier');
    expect(detail.correctiveMeasure, 'Inspected');
    expect(detail.escalatedTo, isEmpty);
    expect(detail.escalatedToUserId, 'PMIS_SU_020');
    expect(detail.remarks, isEmpty);
    expect(detail.hodUserId, 'PMIS_SU_001');
    expect(detail.additional['latitude'], '12.97');
    expect(detail.additional.containsKey('longitude'), isFalse);
  });

  test('issue detail reads the first populated record in a wrapper', () {
    final IssueDetail detail = parseIssueDetail(<String, dynamic>{
      'data': <dynamic>[
        <String, dynamic>{'issue_id': null, 'title': 'skip'},
        <String, dynamic>{
          'issue_id': '9',
          'title': null,
          'short_description': 'Blocked drain',
          'contract_id_fk': 100,
        },
      ],
    });

    expect(detail.issueId, '9');
    expect(detail.title, 'Blocked drain');
    expect(detail.contractIdFk, '100');
    expect(parseIssueDetail(null).issueId, isEmpty);
    expect(parseIssueDetail(null).title, isEmpty);
  });

  test('form master parses catalogs, skips nulls, and keeps extra lists', () {
    final IssueFormMaster master = parseIssueFormMaster(<String, dynamic>{
      'projectsList': <dynamic>[
        <String, dynamic>{'project_id_fk': 12, 'project_name': 'Hubli'},
        <String, dynamic>{'project_id_fk': null, 'project_name': null},
        <String, dynamic>{'project_id_fk': '12', 'project_name': 'duplicate'},
      ],
      'contractsList': <dynamic>[
        <String, dynamic>{
          'contract_id_fk': 'P01EN01',
          'contract_short_name': 'Tumkur',
          'contract_name': 'EPC Tumkur',
          'project_id_fk': 12,
        },
        <String, dynamic>{
          'contract_id_fk': 'P02EN01',
          'contract_short_name': null,
          'contract_name': 'Davangere',
          'project_id_fk': '99',
        },
        <String, dynamic>{
          'contract_id_fk': null,
          'contract_short_name': 'missing',
          'project_id_fk': 12,
        },
      ],
      'issuesStatusList': <dynamic>[
        <String, dynamic>{'status': 'Open'},
        <String, dynamic>{'status': null},
        'Closed',
      ],
      'issuesPriorityList': <dynamic>[
        <String, dynamic>{'priority_fk': 3, 'priority': 'High'},
      ],
      'issuesCategoryList': <dynamic>[
        <String, dynamic>{'category_fk': 2, 'category': 'Civil'},
      ],
      'issueTitlesList': <dynamic>[
        <String, dynamic>{'short_description': 'Leak', 'category_fk': 2},
        <String, dynamic>{
          'short_description': 'Signal',
          'category_fk': 'Signal',
        },
      ],
      'departmentList': <dynamic>[
        <String, dynamic>{
          'department_fk': 'CON',
          'department_name': 'Contractor',
        },
      ],
      'railwayList': <dynamic>[
        <String, dynamic>{'railway_id': 7, 'railway_name': 'SWR'},
      ],
      'reportedByList': <dynamic>[
        <String, dynamic>{
          'reported_by_user_id': 15,
          'reported_by_designation': 'SSE',
        },
      ],
      'responsiblePersonList': <dynamic>[
        <String, dynamic>{
          'responsible_person': 'Ravi',
          'responsible_person_user_id': 'PMIS_SU_014',
          'responsible_person_designation': 'EE',
          'contract_id_fk': 'P01EN01',
        },
      ],
      'escalatedToList': <dynamic>[
        <String, dynamic>{
          'user_name': 'Meera',
          'escalated_to_user_id': 'PMIS_SU_020',
          'escalated_to_designation': 'DEN',
        },
      ],
      'otherOrganizations': <dynamic>[
        <String, dynamic>{'other_organization': 'State PWD'},
        'NHAI',
      ],
      'issueFileTypes': <dynamic>['Photo', null, ''],
      'structures': <dynamic>[
        <String, dynamic>{'structure': 'Bridge 1', 'contract_id_fk': 'P01EN01'},
        <String, dynamic>{'structure': 'Bridge 2', 'contract_id_fk': 'P02EN01'},
      ],
      'components': <dynamic>[
        <String, dynamic>{'component': 'Pier', 'structure': 'Bridge 1'},
        <String, dynamic>{'component': 'Deck', 'structure': 'Bridge 2'},
      ],
      'hodList': <dynamic>[
        <String, dynamic>{
          'hod_user_id_fk': 'PMIS_SU_001',
          'user_name': 'Raj',
          'designation': 'CE',
        },
      ],
      'customNotes': <dynamic>['Alpha', null, ''],
    });

    expect(master.projects, hasLength(1));
    expect(master.projects.single.id, '12');
    expect(master.projects.single.label, 'Hubli');

    expect(master.contracts, hasLength(3));
    expect(master.contracts.first.label, 'Tumkur');
    expect(master.contracts.first.projectId, '12');
    expect(master.contracts[1].label, 'Davangere');
    expect(master.contracts.last.id, 'missing');

    final List<IssueFormOption> forHubli = issueContractsForProject(
      master.contracts,
      '12',
    );
    expect(
      forHubli.map((IssueFormOption option) => option.id).toList(),
      <String>['P01EN01', 'missing'],
    );
    expect(issueContractsForProject(master.contracts, ''), isEmpty);
    expect(
      issueContractsForProject(master.contracts, '99').single.id,
      'P02EN01',
    );

    expect(
      master.statuses.map((IssueFormOption option) => option.id).toList(),
      <String>['Open', 'Closed'],
    );
    expect(master.priorities.single.id, '3');
    expect(master.priorities.single.label, 'High');
    expect(master.categories.single.id, '2');
    expect(master.categories.single.label, 'Civil');

    expect(
      issueTitlesForCategory(
        master.titles,
        categoryId: '2',
        categoryLabel: 'Civil',
      ).single.label,
      'Leak',
    );
    expect(
      issueTitlesForCategory(master.titles, categoryId: '', categoryLabel: ''),
      isEmpty,
    );

    expect(master.departments.single.label, 'Contractor');
    expect(master.railways.single.id, '7');
    expect(master.railways.single.label, 'SWR');
    expect(master.reportedBy.single.id, '15');
    expect(master.reportedBy.single.label, 'SSE');
    expect(master.responsiblePersons.single.id, 'PMIS_SU_014');
    expect(master.responsiblePersons.single.label, 'Ravi — EE');
    expect(
      issuePeopleForContract(master.responsiblePersons, 'P01EN01').single.id,
      'PMIS_SU_014',
    );
    expect(
      issuePeopleForContract(master.responsiblePersons, 'P02EN01'),
      isEmpty,
    );
    expect(master.escalatedTo.single.label, 'Meera — DEN');
    expect(
      master.otherOrganizations
          .map((IssueFormOption option) => option.id)
          .toList(),
      <String>['State PWD', 'NHAI'],
    );
    expect(
      master.fileTypes.map((IssueFormOption option) => option.label).toList(),
      <String>['Photo'],
    );

    expect(
      issueStructuresForContract(master.structures, 'P01EN01').single.label,
      'Bridge 1',
    );
    expect(issueStructuresForContract(master.structures, ''), isEmpty);
    expect(
      issueComponentsFor(
        master.components,
        contractId: 'P01EN01',
        structureId: 'Bridge 1',
      ).single.label,
      'Pier',
    );
    expect(
      issueComponentsFor(
        master.components,
        contractId: 'P01EN01',
        structureId: '',
      ),
      isEmpty,
    );

    expect(master.hods.single.id, 'PMIS_SU_001');
    expect(master.hods.single.label, 'Raj — CE');
    expect(master.extras['customNotes']?.single.label, 'Alpha');
    expect(master.extras.containsKey('hodList'), isFalse);
  });

  test('unlinked structures appear only after a contract is chosen', () {
    const List<IssueFormOption> structures = <IssueFormOption>[
      IssueFormOption(id: 'Yard', label: 'Yard'),
    ];

    expect(issueStructuresForContract(structures, ''), isEmpty);
    expect(issueStructuresForContract(structures, 'P01EN01').single.id, 'Yard');
  });
}
