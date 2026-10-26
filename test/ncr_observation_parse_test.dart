import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/domain/ncr_observation_detail.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/domain/ncr_observation_list.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/domain/ncr_observation_parse.dart';

void main() {
  test('parses raw list response with date arrays', () {
    final ({List<NcrObservationRow> rows, int total}) parsed =
        parseNcrObservationList(
          <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 29,
              'ncrCode': 'NCR-2026-34D95',
              'ncrType': 'NCR',
              'severity': 'MAJOR',
              'description': 'invalid records',
              'location': 'N/A',
              'testObligationId': 384,
              'sourceType': 'TEST_OBLIGATION',
              'status': 'RETURNED',
              'overdue': false,
              'raisedDate': <int>[2026, 9, 30],
              'targetClosureDate': null,
              'projectId': 'P05',
              'sectionId': 92,
              'contractId': 'P05CN01',
              'materialReceiptId': null,
              'responsibleContractorId': null,
            },
            <String, dynamic>{
              'id': 25,
              'ncrCode': 'NCR-2026-AB7B7',
              'ncrType': 'OBSERVATION',
              'severity': 'MINOR',
              'description': 'minor invalid data',
              'location': 'N/A',
              'testObligationId': 387,
              'sourceType': 'TEST_OBLIGATION',
              'status': 'CLOSED',
              'overdue': false,
              'raisedDate': <int>[2026, 9, 11],
              'projectId': 'P05',
              'contractId': 'P05CN01',
            },
          ],
          apiPage: 0,
          pageSize: 10,
        );

    expect(parsed.rows, hasLength(2));
    expect(parsed.total, 2);
    expect(parsed.rows.first.ncrCode, 'NCR-2026-34D95');
    expect(parsed.rows.first.raisedDate, '30-09-2026');
    expect(parsed.rows.first.referenceLabel, 'Test Obligation #384');
    expect(parsed.rows.first.sourceLabel, 'TEST OBLIGATION');
    expect(parsed.rows.last.ncrType, 'OBSERVATION');
  });

  test('list query maps filters and 0-based page', () {
    const NcrObservationListQuery query = NcrObservationListQuery(
      projectId: 'P01',
      sectionId: '255',
      contractId: 'P01EN01',
      ncrType: 'NCR',
      status: 'OPEN',
      dateFrom: '2026-09-01',
      dateTo: '2026-10-24',
      search: '084CE',
      page: 1,
      pageSize: 10,
    );

    expect(query.listQueryParameters(), <String, dynamic>{
      'page': 0,
      'size': 10,
      'projectId': 'P01',
      'sectionId': '255',
      'contractId': 'P01EN01',
      'ncrType': 'NCR',
      'status': 'OPEN',
      'dateFrom': '2026-09-01',
      'dateTo': '2026-10-24',
      'q': '084CE',
    });
  });

  test('parses project dropdown envelope', () {
    final List<NcrOption> options = parseNcrDropdownProjects(<String, dynamic>{
      'success': true,
      'data': <Map<String, dynamic>>[
        <String, dynamic>{
          'projectIdFk': 'P01',
          'projectName': '4th Line between Itarsi - Bhopal - Bina',
        },
        <String, dynamic>{'projectIdFk': null, 'projectName': null},
      ],
    });

    expect(options, hasLength(1));
    expect(options.single.value, 'P01');
    expect(options.single.label, contains('4th Line'));
  });

  test('parses NCR detail, obligation reference and attachments', () {
    final NcrObservationDetail detail = parseNcrObservationDetail(
      <String, dynamic>{
        'id': 28,
        'ncrCode': 'NCR-2026-CD218',
        'ncrType': 'NCR',
        'severity': 'MAJOR',
        'description': 'test is fine but the process is wrong',
        'projectId': 'P05',
        'sectionId': 92,
        'contractId': 'P05CN01',
        'sourceType': 'TEST_OBLIGATION',
        'testObligationId': 400,
        'status': 'ACTION_SUBMITTED',
        'correctiveActionTaken': 'review again',
        'raisedDate': <int>[2026, 10, 1],
        'overdue': false,
      },
      obligation: parseNcrObligationReference(<String, dynamic>{
        'id': 400,
        'obligationCode': 'QT-2026-A7185',
        'materialName': null,
        'batchLotNo': 'PNT-20260928-100',
        'testName': 'Painting',
      }),
      issueAttachments: parseNcrAttachments(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 33,
          'fileName': 'Notification_Report.png',
          'filePath':
              '/quality/NCR-2026-CD218/1790836861740_Notification_Report.png',
          'attachmentStage': 'ISSUE',
        },
      ]),
      correctiveAttachments: parseNcrAttachments(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 34,
          'fileName': '15mb.jpg',
          'filePath': '/quality/NCR-2026-CD218/1790839426273_15mb.jpg',
          'attachmentStage': 'CORRECTIVE_ACTION',
        },
      ]),
    );

    expect(detail.canVerify, isTrue);
    expect(detail.obligation.testName, 'Painting');
    expect(detail.obligation.batchLotNo, 'PNT-20260928-100');
    expect(detail.issueAttachments.single.fileName, 'Notification_Report.png');
    expect(
      ncrAttachmentAbsoluteUrl(
        baseUrl: 'https://pmis-swrindianrailways.org/swrpmis_qa/',
        filePath: detail.issueAttachments.single.filePath,
      ),
      'https://pmis-swrindianrailways.org/swrpmis_qa/quality/NCR-2026-CD218/1790836861740_Notification_Report.png',
    );
  });

  test('enrich fills project and contract names', () {
    final List<NcrObservationRow> rows = enrichNcrRows(
      rows: <NcrObservationRow>[
        const NcrObservationRow(
          id: 1,
          ncrCode: 'NCR-1',
          ncrType: 'NCR',
          severity: 'MAJOR',
          description: '',
          location: '',
          testObligationId: 7,
          sourceType: 'TEST_OBLIGATION',
          status: 'OPEN',
          overdue: false,
          raisedDate: '01-01-2026',
          targetClosureDate: '',
          projectId: 'P01',
          projectName: '',
          sectionId: '',
          contractId: 'P01EN01',
          contractName: '',
          materialReceiptId: '',
          responsibleContractorId: '',
        ),
      ],
      projects: const <NcrOption>[
        NcrOption(value: 'P01', label: 'P01 - Line A'),
      ],
      contracts: const <NcrOption>[
        NcrOption(value: 'P01EN01', label: 'P01EN01 - Contract A'),
      ],
    );

    expect(rows.single.projectName, 'Line A');
    expect(rows.single.contractName, 'Contract A');
  });
}
