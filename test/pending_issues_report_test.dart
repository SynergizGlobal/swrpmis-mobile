import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/list_of_contractors_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/pending_issues_report.dart';

void main() {
  test('detects Pending Issues Report by formId, url, name', () {
    expect(
      isPendingIssuesReport(
        formId: '296',
        formName: 'Pending Issues Report',
        webFormUrl: 'issues-report',
      ),
      isTrue,
    );
    expect(
      isPendingIssuesReport(
        formId: '',
        formName: 'Pending Issues Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isPendingIssuesReport(
        formId: '',
        formName: 'Other',
        webFormUrl: '/api/issues-report/generate-pending',
      ),
      isTrue,
    );
    expect(
      isPendingIssuesReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'issues-report',
      ),
      isTrue,
    );
  });

  test('does not collide with List of Contractors or other Issues reports', () {
    expect(
      isPendingIssuesReport(
        formId: '290',
        formName: 'List of Contractors',
        webFormUrl: 'contractorslist',
      ),
      isFalse,
    );
    expect(
      isListOfContractorsReport(
        formId: '290',
        formName: 'List of Contractors',
        webFormUrl: 'contractorslist',
      ),
      isTrue,
    );
    expect(
      isPendingIssuesReport(
        formId: '297',
        formName: 'Issues Summary Report',
        webFormUrl: 'generate-issues-summary-report',
      ),
      isFalse,
    );
    expect(
      isPendingIssuesReport(
        formId: '298',
        formName: 'Issue Details Report',
        webFormUrl: 'issue-details-report',
      ),
      isFalse,
    );
  });

  test('parses HOD list from array, single object, and envelope', () {
    final List<PendingIssuesHodOption> fromList = parsePendingIssuesHods(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'hod_user_id_fk': 'PMIS_SU_002',
          'designation': 'CE/CN/I/BNC',
          'hod_name': 'M V PRASAD',
        },
        <String, dynamic>{
          'hod_user_id_fk': 'PMIS_SU_003',
          'designation': 'CE/CN/II/BNC',
          'hod_name': 'Other HOD',
        },
      ],
    );
    expect(fromList, hasLength(2));
    expect(fromList.first.userId, 'PMIS_SU_002');
    expect(fromList.first.name, 'M V PRASAD');
    expect(fromList.first.label, 'M V PRASAD (CE/CN/I/BNC)');

    final List<PendingIssuesHodOption> fromSingle = parsePendingIssuesHods(
      <String, dynamic>{
        'hod_user_id_fk': 'PMIS_SU_002',
        'hod_name': 'M V PRASAD',
      },
    );
    expect(fromSingle, hasLength(1));
    expect(fromSingle.single.name, 'M V PRASAD');

    final List<PendingIssuesHodOption> fromEnvelope = parsePendingIssuesHods(
      <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'hod_user_id_fk': 'U1',
            'hod_name': 'Alpha',
          },
        ],
      },
    );
    expect(fromEnvelope.single.userId, 'U1');
    expect(fromEnvelope.single.name, 'Alpha');
  });

  test('parses contract list with contract_id_fk and contract_name', () {
    final List<ContractDetailOption> contracts = parsePendingIssuesContracts(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'contract_id_fk': 'P01EN01',
          'contract_name':
              'EPC Contract for Important Bridges on Bengaluru Suburban',
        },
        <String, dynamic>{
          'contract_id': 'P02EN02',
          'contract_name': 'Another Contract',
        },
      ],
    );
    expect(contracts.map((ContractDetailOption o) => o.id).toList(), <String>[
      'P01EN01',
      'P02EN02',
    ]);
    expect(
      contracts.first.label,
      'EPC Contract for Important Bridges on Bengaluru Suburban',
    );

    final List<ContractDetailOption> wrapped = parsePendingIssuesContracts(
      <String, dynamic>{
        'result': <String, dynamic>{
          'contract_id_fk': 'P01EN01',
          'contract_name': 'Solo',
        },
      },
    );
    expect(wrapped.single.id, 'P01EN01');
    expect(wrapped.single.label, 'Solo');
  });

  test('generate body maps hod_user_id_fk to HOD name, not user id', () {
    final Map<String, dynamic> body = buildPendingIssuesGenerateBody(
      hodName: 'M V PRASAD',
      contractId: 'P01EN01',
    );
    expect(body, <String, dynamic>{
      'hod_user_id_fk': 'M V PRASAD',
      'contract_id_fk': 'P01EN01',
    });
    expect(body['hod_user_id_fk'], isNot(equals('PMIS_SU_002')));

    final PendingIssuesHodOption hod = PendingIssuesHodOption(
      userId: 'PMIS_SU_002',
      name: 'M V PRASAD',
      designation: 'CE/CN/I/BNC',
    );
    final Map<String, dynamic> fromOption = buildPendingIssuesGenerateBody(
      hodName: hod.name,
      contractId: 'P01EN01',
    );
    expect(fromOption['hod_user_id_fk'], 'M V PRASAD');
    expect(fromOption['contract_id_fk'], 'P01EN01');
  });
}
