import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/forms/form_menu_tree.dart';
import 'package:swr_pmis_mobile/src/core/navigation/module_catalog.dart';
import 'package:swr_pmis_mobile/src/features/issues/data/issue_export_file.dart';
import 'package:swr_pmis_mobile/src/features/issues/domain/issue_list.dart';
import 'package:swr_pmis_mobile/src/features/issues/domain/issue_parse.dart';
import 'package:swr_pmis_mobile/src/features/issues/presentation/pages/issues_page.dart';
import 'package:swr_pmis_mobile/src/features/issues/presentation/widgets/issues_table.dart';
import 'package:swr_pmis_mobile/src/features/update_forms/domain/update_form_destination.dart';

void main() {
  test('contract list parses short name and id', () {
    final List<IssueOption> contracts = parseIssueContracts(<dynamic>[
      <String, dynamic>{
        'contract_short_name': 'contract2',
        'contract_id_fk': 'P01EN02',
      },
      <String, dynamic>{
        'contract_short_name': 'duplicate',
        'contract_id_fk': 'P01EN02',
      },
      <String, dynamic>{
        'contract_short_name': null,
        'contract_id_fk': 'P01EN03',
      },
    ]);

    expect(contracts, hasLength(1));
    expect(contracts.single.label, 'contract2');
    expect(contracts.single.value, 'P01EN02');

    final IssueOption single = parseIssueContracts(<String, dynamic>{
      'contract_short_name': 'contract3',
      'contract_id_fk': 'P01EN09',
    }).single;
    expect(single.label, 'contract3');
    expect(single.value, 'P01EN09');
  });

  test('single HOD object parses name, designation, and id', () {
    final IssueOption hod = parseIssueHods(<String, dynamic>{
      'user_name': 'Mr. Rajveer',
      'designation': 'CE/C-II/HQ',
      'hod_user_id_fk': 'PMIS_SU_014',
    }).single;

    expect(hod.label, 'Mr. Rajveer-CE/C-II/HQ');
    expect(hod.value, 'PMIS_SU_014');
    expect(
      parseIssueHods(<String, dynamic>{
        'user_name': null,
        'designation': 'CE/C-II/HQ',
        'hod_user_id_fk': 'PMIS_SU_014',
      }),
      isEmpty,
    );
  });

  test('department, category, and status options parse', () {
    final IssueOption department = parseIssueDepartments(<String, dynamic>{
      'department_name': 'Contractor',
      'department_fk': 'CON',
    }).single;
    expect(department.label, 'Contractor');
    expect(department.value, 'CON');

    final IssueOption category = parseIssueCategories(<String, dynamic>{
      'category_fk': 'network',
    }).single;
    expect(category.label, 'network');
    expect(category.value, 'network');

    final IssueOption status = parseIssueStatuses(<String, dynamic>{
      'status_fk': 'Raised',
    }).single;
    expect(status.label, 'Raised');
    expect(status.value, 'Raised');
  });

  test('issue row maps the table columns and skips a missing id', () {
    const Map<String, dynamic> sample = <String, dynamic>{
      'issue_id': '101',
      'contract_short_name': 'contract short name',
      'title': 'test1',
      'location': 'Jabalpur',
      'other_org_resposible_person_name': 'dummy-Ajay',
      'responsible_person': 'Ajay',
      'other_organization': 'railway',
      'department_name': 'Engineering',
      'status_fk': 'active',
      'modified_date': '20-07-2026',
    };
    final List<IssueRow> rows = parseIssueRows(<dynamic>[
      sample,
      <String, dynamic>{'title': 'test1', 'location': 'Mumbai'},
    ]);

    expect(rows, hasLength(1));
    expect(rows.single.issueId, '101');
    expect(issueExportCells(rows.single), <String>[
      'contract short name',
      'test1',
      'Jabalpur',
      'dummy-Ajay',
      'railway',
      'active',
      '20-07-2026',
    ]);

    final IssueRow fallback = parseIssueRows(<String, dynamic>{
      'issue_id': '2',
      'other_org_resposible_person_name': '',
      'responsible_person': 'Ajay',
      'department_name': 'Engineering',
    }).single;
    expect(fallback.responsiblePerson, 'Ajay');
    expect(fallback.department, 'Engineering');
  });

  test('filter body uses empty strings and a change skips that list', () {
    expect(const IssueListQuery().toJson(), <String, String>{
      'contract_id_fk': '',
      'department_fk': '',
      'category_fk': '',
      'status_fk': '',
      'hod': '',
    });
    expect(
      const IssueListQuery(
        contractId: 'P01EN02',
        departmentId: 'CON',
        categoryId: 'network',
        statusId: 'Raised',
        hodId: 'PMIS_SU_014',
      ).toJson(),
      <String, String>{
        'contract_id_fk': 'P01EN02',
        'department_fk': 'CON',
        'category_fk': 'network',
        'status_fk': 'Raised',
        'hod': 'PMIS_SU_014',
      },
    );
    expect(issueListCalls(), <IssueListCall>[
      IssueListCall.contracts,
      IssueListCall.hods,
      IssueListCall.departments,
      IssueListCall.categories,
      IssueListCall.statuses,
      IssueListCall.issues,
    ]);
    expect(issueListCalls(changed: IssueFilterField.contract), <IssueListCall>[
      IssueListCall.hods,
      IssueListCall.departments,
      IssueListCall.categories,
      IssueListCall.statuses,
      IssueListCall.issues,
    ]);
  });

  test('workbook bytes contain the contract short name and title', () {
    final IssueRow row = parseIssueRows(<String, dynamic>{
      'issue_id': '101',
      'contract_short_name': 'contract short name',
      'title': 'test1',
      'location': 'Jabalpur',
      'other_org_resposible_person_name': 'dummy-Ajay',
      'other_organization': 'railway',
      'status_fk': 'active',
      'modified_date': '20-07-2026',
    }).single;
    expect(
      issueExportHeaders,
      issueTableColumns(
        onEdit: (_) {},
      ).map((IssueTableColumn column) => column.label).where((String label) {
        return label != 'Actions';
      }),
    );

    final bytes = buildIssueXlsxBytes(<IssueRow>[row]);
    expect(bytes.length, greaterThan(4));
    expect(bytes[0], 0x50);
    expect(bytes[1], 0x4B);
    expect(issueExportFileName, 'issues.xlsx');

    final Sheet sheet = Excel.decodeBytes(bytes).tables.values.single;
    final List<List<Data?>> rows = sheet.rows;
    expect(rows.length, 2);
    expect(_cellText(rows[0][0]), 'Contract');
    expect(_cellText(rows[0][1]), 'Short Description');
    expect(_cellText(rows[1][0]), 'contract short name');
    expect(_cellText(rows[1][1]), 'test1');
  });

  test('Issues leaf opens the issues route and other leaves stay', () {
    final AppModule issues = ModuleCatalog.routable.firstWhere(
      (AppModule module) => module.id == 'issues',
    );
    expect(IssuesPage.routeName, issues.routeName);
    expect(
      updateFormRouteName(_leaf(formName: 'Issues', webFormUrl: '')),
      IssuesPage.routeName,
    );
    expect(
      updateFormRouteName(_leaf(formName: 'Site notes', webFormUrl: 'issues')),
      IssuesPage.routeName,
    );
    expect(
      updateFormRouteName(
        _leaf(formName: 'Add Project', webFormUrl: 'project'),
      ),
      isNull,
    );
    expect(
      updateFormRouteName(
        _leaf(formName: 'Design & Drawing', webFormUrl: 'design'),
      ),
      'forms-design',
    );
  });
}

FormMenuNode _leaf({required String formName, required String webFormUrl}) {
  return FormMenuNode(
    formId: formName,
    formName: formName,
    webFormUrl: webFormUrl,
    mobileFormUrl: '',
    priority: 1,
    children: const <FormMenuNode>[],
  );
}

String _cellText(Data? data) {
  final CellValue? value = data?.value;
  if (value is TextCellValue) {
    return value.value.text ?? '';
  }
  return '';
}
