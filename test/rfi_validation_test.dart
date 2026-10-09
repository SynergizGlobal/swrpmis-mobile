import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_catalog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_row.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_validation_actions.dart';

void main() {
  const Map<String, dynamic> sample = <String, dynamic>{
    'rfiCategory': null,
    'stringRfiId': null,
    'longRfiId': null,
    'longRfiValidateId': 13,
    'status': 'APPROVED',
    'remarks': 'NONOC(C)',
    'valdationAuth': null,
    'comment': 'Seen',
    'projectName': null,
    'contractName': null,
  };

  test('parses one validation object and a one-element list', () {
    final RfiValidationRow row = RfiValidationRow.fromJson(sample);
    final List<RfiValidationRow> fromObject = parseRfiValidationRows(sample);
    final List<RfiValidationRow> fromList = parseRfiValidationRows(<dynamic>[
      sample,
    ]);

    expect(row.rfiCategory, isNull);
    expect(row.stringRfiId, isNull);
    expect(row.longRfiId, isNull);
    expect(row.longRfiValidateId, 13);
    expect(row.status, 'APPROVED');
    expect(row.remarks, 'NONOC(C)');
    expect(row.comment, 'Seen');
    expect(rfiValidationSelectedRemark(row.remarks), 'NONOC(C)');
    expect(fromObject, hasLength(1));
    expect(fromObject.single.longRfiValidateId, 13);
    expect(fromList.single.remarks, 'NONOC(C)');
    expect(fromList.single.comment, 'Seen');
  });

  test('approved status hides actions and an empty status shows three', () {
    final RfiValidationRow approved = RfiValidationRow.fromJson(sample);
    final RfiValidationRow open = RfiValidationRow.fromJson(<String, dynamic>{
      'status': '',
      'longRfiValidateId': 4,
    });

    expect(rfiValidationDecisions(approved.status), isEmpty);
    expect(rfiValidationStatusText(approved.status), 'APPROVED');
    expect(rfiValidationDecisions('REJECTED'), isEmpty);
    expect(rfiValidationStatusText('REJECTED'), 'REJECTED');
    expect(rfiValidationDecisions('Returned_For_Clarification'), isEmpty);
    expect(
      rfiValidationStatusText('RETURNED_FOR_CLARIFICATION'),
      'Returned_For_Clarification',
    );
    expect(
      rfiValidationDecisions(open.status).map((RfiValidationDecision decision) {
        return decision.action;
      }),
      <String>['APPROVED', 'REJECTED', 'Returned_For_Clarification'],
    );
    expect(rfiValidationDecisions(null), hasLength(3));
  });

  test('comment cap is 500 and actions map onto validate fields', () {
    expect(rfiValidationCommentMaxLength, 500);
    expect(clampRfiValidationComment('x' * 600).length, 500);

    final RfiValidationRow row = RfiValidationRow.fromJson(sample);
    expect(
      rfiValidationFormFields(
        row: row,
        remarks: '-- Select --',
        comment: 'Seen',
        decision: RfiValidationDecision.approve,
      ),
      isNull,
    );
    expect(
      rfiValidationFormFields(
        row: row,
        remarks: '',
        comment: 'Seen',
        decision: RfiValidationDecision.reject,
      ),
      isNull,
    );

    expect(RfiValidationDecision.approve.action, 'APPROVED');
    expect(RfiValidationDecision.reject.action, 'REJECTED');
    expect(RfiValidationDecision.rectify.action, 'Returned_For_Clarification');

    final Map<String, String>? fields = rfiValidationFormFields(
      row: row,
      remarks: 'NONOC(C)',
      comment: 'Seen',
      decision: RfiValidationDecision.rectify,
    );
    expect(fields, <String, String>{
      'long_rfi_id': '',
      'long_rfi_validate_id': '13',
      'remarks': 'NONOC(C)',
      'comment': 'Seen',
      'action': 'Returned_For_Clarification',
    });
    expect(
      rfiValidationFormFields(
        row: row,
        remarks: 'NONO',
        comment: '',
        decision: RfiValidationDecision.approve,
      )?['action'],
      'APPROVED',
    );
    expect(
      rfiValidationFormFields(
        row: row,
        remarks: 'OTHERS',
        comment: 'note',
        decision: RfiValidationDecision.reject,
      )?['action'],
      'REJECTED',
    );
  });

  test('filter payload uses empty strings and clears fields to the right', () {
    expect(const RfiValidationFilter().toJson(), <String, dynamic>{
      'projectId': '',
      'contractId': '',
      'rfiCategory': '',
    });

    const RfiValidationFilter filter = RfiValidationFilter(
      rfiCategory: 'WORK',
      projectId: '9',
      contractId: '3',
    );
    final RfiValidationFilter category = filter.withCategory('MATERIAL');
    expect(category.toJson(), <String, dynamic>{
      'projectId': '',
      'contractId': '',
      'rfiCategory': 'MATERIAL',
    });
    final RfiValidationFilter project = filter.withProject('4');
    expect(project.rfiCategory, 'WORK');
    expect(project.projectId, '4');
    expect(project.contractId, '');
    expect(filter.withContract('8').projectId, '9');
  });

  test('empty filter endpoints fall back to rows and the project list', () {
    final RfiValidationCatalog catalog = RfiValidationCatalog.fromResponses(
      categories: const <dynamic>[],
      projects: const <dynamic>[],
      contracts: const <dynamic>[],
      projectList: const <Map<String, dynamic>>[
        <String, dynamic>{
          'project_id': 'P01',
          'project_name': 'Itarsi - Bhopal',
        },
      ],
      validations: <dynamic>[
        sample,
        <String, dynamic>{'rfiCategory': 'WORK', 'status': ''},
        <String, dynamic>{'rfiCategory': 'WORK', 'status': ''},
        <String, dynamic>{'rfiCategory': null, 'status': ''},
        <String, dynamic>{'rfiCategory': 'MATERIAL', 'status': ''},
      ],
    );

    expect(catalog.categories.map((option) => option.id), <String>[
      'WORK',
      'MATERIAL',
    ]);
    expect(catalog.projects.single.id, 'P01');
    expect(catalog.projects.single.label, 'Itarsi - Bhopal');
    expect(catalog.contracts, isEmpty);
    expect(catalog.rows.first.longRfiValidateId, 13);
  });

  test('filter objects win over fallbacks, including plain strings', () {
    final RfiValidationCatalog catalog = RfiValidationCatalog.fromResponses(
      categories: const <dynamic>['QUALITY'],
      projects: const <Map<String, dynamic>>[
        <String, dynamic>{'projectId': '9', 'projectName': 'Bridge'},
      ],
      contracts: const <Map<String, dynamic>>[
        <String, dynamic>{'contractId': '3', 'contractName': 'EPC'},
      ],
      projectList: const <Map<String, dynamic>>[
        <String, dynamic>{'project_id': 'P01', 'project_name': 'Other'},
      ],
      validations: const <Map<String, dynamic>>[
        <String, dynamic>{'rfiCategory': 'WORK', 'status': ''},
      ],
    );

    expect(catalog.categories.single.id, 'QUALITY');
    expect(catalog.projects.single.id, '9');
    expect(catalog.projects.single.label, 'Bridge');
    expect(catalog.contracts.single.label, 'EPC');
    expect(
      ApiConstants.getRfiReportDetail,
      '/api/validation/getRfiReportDetail',
    );
  });
}
