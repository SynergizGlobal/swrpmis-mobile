import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_catalog.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_validation_report.dart';
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

  const Map<String, dynamic> pendingSample = <String, dynamic>{
    'rfiCategory': 'WORK',
    'stringRfiId': 'RFI_W_MNB_56319_FOUN_OPNF_RNFSHT_0001',
    'longRfiId': 105,
    'longRfiValidateId': 42,
    'status': null,
    'remarks': null,
    'valdationAuth': null,
    'comment': null,
    'projectName': 'P01',
    'contractName': 'P01EN01',
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

  test('parses latest QA pending row including longRfiId number and typo auth', () {
    final RfiValidationRow row = RfiValidationRow.fromJson(pendingSample);

    expect(row.rfiCategory, 'WORK');
    expect(row.stringRfiId, 'RFI_W_MNB_56319_FOUN_OPNF_RNFSHT_0001');
    expect(row.longRfiId, '105');
    expect(row.longRfiValidateId, 42);
    expect(row.status, isNull);
    expect(row.remarks, isNull);
    expect(row.comment, isNull);
    expect(row.valdationAuth, isNull);
    expect(row.projectName, 'P01');
    expect(row.contractName, 'P01EN01');
    expect(row.toListItem().rfiId, row.stringRfiId);
    expect(row.toListItem().projectName, 'P01');
    expect(row.toListItem().contractName, 'P01EN01');
    expect(rfiValidationPendingOrValue(row.remarks), rfiValidationPendingLabel);
    expect(rfiValidationPendingOrValue(row.comment), rfiValidationPendingLabel);
  });

  test('getValidationAccess parser gates validator-only actions', () {
    expect(parseRfiValidationAccess(<String, dynamic>{'validator': false}), isFalse);
    expect(parseRfiValidationAccess(<String, dynamic>{'validator': true}), isTrue);
    expect(
      parseRfiValidationAccess(<String, dynamic>{
        'data': <String, dynamic>{'validator': true},
      }),
      isTrue,
    );
    expect(parseRfiValidationAccess(null), isFalse);

    expect(
      rfiValidationCanDecide(isValidator: false, status: null),
      isFalse,
    );
    expect(
      rfiValidationCanDecide(isValidator: true, status: null),
      isTrue,
    );
    expect(
      rfiValidationCanDecide(isValidator: true, status: 'APPROVED'),
      isFalse,
    );
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

    final Map<String, String>? pendingFields = rfiValidationFormFields(
      row: RfiValidationRow.fromJson(pendingSample),
      remarks: 'NONO',
      comment: '',
      decision: RfiValidationDecision.approve,
    );
    expect(pendingFields?['long_rfi_id'], '105');
    expect(pendingFields?['long_rfi_validate_id'], '42');
    expect(pendingFields?['action'], 'APPROVED');

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

  test('filter payload uses rfiId null and empty strings', () {
    expect(const RfiValidationFilter().toJson(), <String, dynamic>{
      'rfiId': null,
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
      'rfiId': null,
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
      access: const <String, dynamic>{'validator': false},
    );

    expect(catalog.categories.map((option) => option.id), <String>[
      'WORK',
      'MATERIAL',
    ]);
    expect(catalog.projects.single.id, 'P01');
    expect(catalog.projects.single.label, 'Itarsi - Bhopal');
    expect(catalog.contracts, isEmpty);
    expect(catalog.rows.first.longRfiValidateId, 13);
    expect(catalog.isValidator, isFalse);
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
      access: const <String, dynamic>{'validator': true},
    );

    expect(catalog.categories.single.id, 'QUALITY');
    expect(catalog.projects.single.id, '9');
    expect(catalog.projects.single.label, 'Bridge');
    expect(catalog.contracts.single.label, 'EPC');
    expect(catalog.isValidator, isTrue);
    expect(
      ApiConstants.validationAccessPath,
      '/api/validation/getValidationAccess',
    );
    expect(
      ApiConstants.getRfiReportDetail,
      '/api/validation/getRfiReportDetail',
    );
  });

  test('latest QA filter option shapes parse', () {
    final RfiValidationCatalog catalog = RfiValidationCatalog.fromResponses(
      categories: const <Map<String, dynamic>>[
        <String, dynamic>{'rfiCategory': 'WORK'},
      ],
      projects: const <Map<String, dynamic>>[
        <String, dynamic>{
          'projectId': 'P01',
          'projectName': 'Bengaluru Railway Projects',
        },
      ],
      contracts: const <Map<String, dynamic>>[
        <String, dynamic>{
          'contractId': 'P01EN01',
          'contractName': 'EPC Contract for Important Bridges...',
        },
      ],
      projectList: const <dynamic>[],
      validations: <dynamic>[pendingSample],
      access: const <String, dynamic>{'validator': false},
    );

    expect(catalog.categories.single.id, 'WORK');
    expect(catalog.projects.single.id, 'P01');
    expect(catalog.projects.single.label, 'Bengaluru Railway Projects');
    expect(catalog.contracts.single.id, 'P01EN01');
    expect(catalog.rows.single.stringRfiId, pendingSample['stringRfiId']);
    expect(catalog.isValidator, isFalse);
  });

  test('getRfiReportDetail path encodes longRfiId', () {
    expect(
      ApiConstants.getRfiReportDetailPath('105'),
      '/api/validation/getRfiReportDetail/105',
    );
    expect(
      ApiConstants.rfiLogAttachmentFilePath,
      '/api/rfiLog/previewFiles/file',
    );
  });

  test('parses validation report detail sample including nested checklist', () {
    final RfiValidationReport report = RfiValidationReport.fromJson(
      <String, dynamic>{
        'reportDetails': <String, dynamic>{
          'project': 'Bengaluru Railway Projects',
          'consultant': null,
          'contract':
              'New Broad gauge line Between KM 25.4 & KM 66.4 (41.0 KM) in Tumkur-Chitradurga-Davangere project',
          'rfiCategory': 'WORK',
          'contractor':
              'M C SHEKHAR - M/s GIRIRAJ CIVIL DEVELOPERS LIMITED - MUMBAI',
          'contractId': 'P01EN01',
          'rfiId': 'RFI_W_MNB_56319_FOUN_OPNF_RNFSHT_0001',
          'rfiStatus': 'VALIDATION_PENDING',
          'conInspectedOn': '11-13-2026 12:47',
          'enggInspectedOn': '11-13-2026 19:36',
          'location': '1-',
          'proposedInspectionDate': '11-13-2026',
          'proposedInspectionTime': '11:06',
          'rfiDescription': 'Concreting',
          'enclosures': 'RCC Works - Concrete',
          'contractorRepresentative': 'KOUSTAV PAL',
          'clientRepresentative': 'Rakesh Kumar Pandey',
          'descriptionByContractor': 'Mobile QA test - please ignore',
          'validationStatus': null,
          'remarks': null,
          'validationComments': null,
          'selfieClient':
              '/home/smt/git/swrpmis_qa/Rfi-Storage/uploads/siteImages/client.jpg',
          'selfieContractor':
              '/home/smt/git/swrpmis_qa/Rfi-Storage/uploads/siteImages/selfie.jpg',
          'imagesUploadedByClient': null,
          'imagesUploadedByContractor':
              '/a/one.jpg,/b/two.jpg',
          'testType': 'VISUAL',
          'testStatus': 'Accepted',
          'attachmentData': 'RFI_105_attachments_1795005334019.pdf::local testing##',
          'attachments': <Map<String, dynamic>>[
            <String, dynamic>{
              'fileName': 'RFI_105_attachments_1795005334019.pdf',
              'description': 'local testing',
            },
          ],
        },
        'checklistItems': <Map<String, dynamic>>[
          <String, dynamic>{
            'rfiDescription': 'Concreting',
            'enclosureName': 'RCC Works - Concrete',
            'gradeOfConcrete': '',
            'checklist': <Map<String, dynamic>>[
              <String, dynamic>{
                'checklistDescription': 'DRAWING APPROVED AND AVAILABLE',
                'conStatus': 'YES',
                'aeStatus': '',
                'contractorRemark': 'testing',
                'aeRemark': '',
              },
              <String, dynamic>{
                'checklistDescription':
                    'ACCESS AND WALKWAY FOR CHECKING IS AVAILABLE',
                'conStatus': 'YES',
                'aeStatus': '',
                'contractorRemark': '',
                'aeRemark': '',
              },
            ],
          },
        ],
        'enclosures': <Map<String, dynamic>>[
          <String, dynamic>{
            'rfiDescription': 'Concreting',
            'enclosureName': 'RCC Works - Concrete',
            'file':
                '/home/smt/git/swrpmis_qa/Rfi-Storage/Enclosures/rfi_105_5_1794553434187.pdf',
          },
        ],
        'measurementDetails': <Map<String, dynamic>>[
          <String, dynamic>{
            'measurementType': 'Percent',
            'weight': null,
            'totalQty': 40.0,
            'activityName': 'Reinforcement & Shuttering',
            'description': '1',
            'component': null,
            'element': null,
            'b': null,
            'h': null,
            'l': null,
            'no': null,
            'units': '%',
          },
          <String, dynamic>{
            'measurementType': 'Number',
            'totalQty': 3.0,
            'activityName': 'Concreting',
            'description': 'aa',
            'no': 3,
            'units': 'Nos',
          },
        ],
        'materialDetails': null,
        'workDetails': <dynamic>[],
        'validationList': <dynamic>[],
      },
    );

    expect(report.details.rfiId, 'RFI_W_MNB_56319_FOUN_OPNF_RNFSHT_0001');
    expect(report.details.displayStatus, 'Active');
    expect(report.details.consultant, isEmpty);
    expect(rfiValidationBlank(report.details.consultant), '---');
    expect(report.details.contractorSiteImagePaths, <String>[
      '/a/one.jpg',
      '/b/two.jpg',
    ]);
    expect(report.details.attachments, hasLength(1));
    expect(
      report.details.attachments.single.fileName,
      'RFI_105_attachments_1795005334019.pdf',
    );
    expect(report.details.attachments.single.description, 'local testing');
    expect(report.checklistGroups, hasLength(1));
    expect(report.checklistGroups.single.enclosureName, 'RCC Works - Concrete');
    expect(report.checklistGroups.single.checklist, hasLength(2));
    expect(
      report.checklistGroups.single.checklist.first.contractorRemark,
      'testing',
    );
    expect(report.enclosures.single.file, contains('rfi_105_5_'));
    expect(report.measurementDetails, hasLength(2));
    expect(report.measurementDetails.first.totalQty, '40');
    expect(report.measurementDetails.first.description, '1');
    expect(report.measurementDetails.last.count, '3');
    expect(report.measurementDetails.last.description, 'aa');
    expect(report.validationList, isEmpty);
    expect(
      report.reportFileName,
      'RFI_W_MNB_56319_FOUN_OPNF_RNFSHT_0001_RfiReport.pdf',
    );
  });
}
