import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/land_acquisition_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/pending_issues_report.dart';

void main() {
  test('detects Land Acquisition Report by formId, url, name', () {
    expect(
      isLandAcquisitionReport(
        formId: '1316',
        formName: 'Land Acquisition',
        webFormUrl: 'la-report',
      ),
      isTrue,
    );
    expect(
      isLandAcquisitionReport(
        formId: '',
        formName: 'Land Acquisition Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isLandAcquisitionReport(
        formId: '',
        formName: 'Other',
        webFormUrl: '/api/land-report/generate',
      ),
      isTrue,
    );
    expect(
      isLandAcquisitionReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'la-report',
      ),
      isTrue,
    );
  });

  test('does not collide with Pending Issues', () {
    expect(
      isLandAcquisitionReport(
        formId: '296',
        formName: 'Pending Issues Report',
        webFormUrl: 'issues-report',
      ),
      isFalse,
    );
    expect(
      isPendingIssuesReport(
        formId: '296',
        formName: 'Pending Issues Report',
        webFormUrl: 'issues-report',
      ),
      isTrue,
    );
  });

  test('parses project list from array, single object, and envelope', () {
    final List<ContractDetailOption> fromList = parseLandAcquisitionProjects(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'project_id': 'P01',
          'project_name': 'Bengaluru Railway Projects',
        },
        <String, dynamic>{
          'project_id': 'P02',
          'project_name': 'Other Project',
        },
      ],
    );
    expect(fromList.map((ContractDetailOption o) => o.id).toList(), <String>[
      'P01',
      'P02',
    ]);
    expect(fromList.first.label, 'Bengaluru Railway Projects');

    final List<ContractDetailOption> fromSingle = parseLandAcquisitionProjects(
      <String, dynamic>{
        'project_id': 'P01',
        'project_name': 'Solo Project',
      },
    );
    expect(fromSingle.single.id, 'P01');
    expect(fromSingle.single.label, 'Solo Project');

    final List<ContractDetailOption> fromEnvelope =
        parseLandAcquisitionProjects(
          <String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'project_id': 'P03',
                'project_name': 'Wrapped',
              },
            ],
          },
        );
    expect(fromEnvelope.single.id, 'P03');
    expect(fromEnvelope.single.label, 'Wrapped');
  });

  test('parses type list using category_fk as label and value', () {
    final List<ContractDetailOption> types = parseLandAcquisitionTypes(
      <Map<String, dynamic>>[
        <String, dynamic>{'category_fk': 'Government'},
        <String, dynamic>{'category_fk': 'Private'},
      ],
    );
    expect(types.map((ContractDetailOption o) => o.id).toList(), <String>[
      'Government',
      'Private',
    ]);
    expect(types.map((ContractDetailOption o) => o.label).toList(), <String>[
      'Government',
      'Private',
    ]);
  });

  test('parses sub-category list with la_sub_category_fk / la_sub_category', () {
    final List<ContractDetailOption> subs = parseLandAcquisitionSubCategories(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'la_sub_category_fk': '9',
          'la_sub_category': 'Agricultural Land',
        },
        <String, dynamic>{
          'la_sub_category_fk': 10,
          'la_sub_category': 'Forest Land',
        },
      ],
    );
    expect(subs.map((ContractDetailOption o) => o.id).toList(), <String>[
      '9',
      '10',
    ]);
    expect(subs.first.label, 'Agricultural Land');
  });

  test('generate body requires project, category, and sub-category fks', () {
    final Map<String, dynamic> body = buildLandAcquisitionGenerateBody(
      projectId: 'P01',
      categoryFk: 'Private',
      subCategoryFk: '9',
    );
    expect(body, <String, dynamic>{
      'project_id_fk': 'P01',
      'category_fk': 'Private',
      'la_sub_category_fk': '9',
    });
  });

  test('cascade query builders omit empty params', () {
    expect(buildLandAcquisitionProjectListQuery(), isEmpty);
    expect(
      buildLandAcquisitionProjectListQuery(categoryFk: 'Private'),
      <String, dynamic>{'category_fk': 'Private'},
    );

    expect(buildLandAcquisitionTypeListQuery(), isEmpty);
    expect(
      buildLandAcquisitionTypeListQuery(projectId: 'P01'),
      <String, dynamic>{'project_id_fk': 'P01'},
    );

    expect(buildLandAcquisitionSubCategoryListQuery(), isEmpty);
    expect(
      buildLandAcquisitionSubCategoryListQuery(projectId: 'P01'),
      <String, dynamic>{'project_id_fk': 'P01'},
    );
    expect(
      buildLandAcquisitionSubCategoryListQuery(categoryFk: 'Private'),
      <String, dynamic>{'category_fk': 'Private'},
    );
    expect(
      buildLandAcquisitionSubCategoryListQuery(
        projectId: 'P01',
        categoryFk: 'Private',
      ),
      <String, dynamic>{
        'project_id_fk': 'P01',
        'category_fk': 'Private',
      },
    );
  });
}
