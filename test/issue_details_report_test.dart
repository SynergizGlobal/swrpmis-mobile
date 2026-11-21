import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/issue_details_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/issues_summary_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/pending_issues_report.dart';

void main() {
  test('detects Issue Details Report by formId, url, name', () {
    expect(
      isIssueDetailsReport(
        formId: '298',
        formName: 'Issue Details Report',
        webFormUrl: 'issue-details-report',
      ),
      isTrue,
    );
    expect(
      isIssueDetailsReport(
        formId: '',
        formName: 'Issues Details Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isIssueDetailsReport(
        formId: '',
        formName: 'Other',
        webFormUrl: '/api/issues-details-report/generate',
      ),
      isTrue,
    );
  });

  test('does not collide with Pending Issues or Issues Summary', () {
    expect(
      isIssueDetailsReport(
        formId: '296',
        formName: 'Pending Issues Report',
        webFormUrl: 'issues-report',
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
    expect(
      isIssueDetailsReport(
        formId: '297',
        formName: 'Issues Summary Report',
        webFormUrl: 'generate-issues-summary-report',
      ),
      isFalse,
    );
    expect(
      isIssuesSummaryReport(
        formId: '',
        formName: 'Issue Details Report',
        webFormUrl: '',
      ),
      isFalse,
    );
  });

  test('parses HOD / contract / status / location / category / title lists', () {
    final List<PendingIssuesHodOption> hods = parseIssueDetailsHods(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'hod_user_id_fk': 'PMIS_SU_002',
          'designation': 'CE/CN/I/BNC',
          'hod_name': 'M V PRASAD',
        },
      ],
    );
    expect(hods.single.userId, 'PMIS_SU_002');
    expect(hods.single.name, 'M V PRASAD');
    expect(hods.single.label, contains('M V PRASAD'));

    final List<ContractDetailOption> contracts = parseIssueDetailsContracts(
      <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'contract_id_fk': 'P24EN01',
            'contract_name': 'Sample Contract',
          },
        ],
      },
    );
    expect(contracts.single.id, 'P24EN01');
    expect(contracts.single.label, 'Sample Contract');

    final List<ContractDetailOption> statuses = parseIssueDetailsStatuses(
      <Map<String, dynamic>>[
        <String, dynamic>{'status_fk': 'Raised'},
        <String, dynamic>{'status_fk': 'active'},
      ],
    );
    expect(statuses.map((ContractDetailOption o) => o.id).toList(), <String>[
      'Raised',
      'active',
    ]);

    final List<ContractDetailOption> locations = parseIssueDetailsLocations(
      <String, dynamic>{'location': '28-29KM'},
    );
    expect(locations.single.id, '28-29KM');

    final List<ContractDetailOption> categories = parseIssueDetailsCategories(
      <Map<String, dynamic>>[
        <String, dynamic>{'category_fk': 'Contract'},
      ],
    );
    expect(categories.single.id, 'Contract');

    final List<IssueDetailsTitleOption> titles = parseIssueDetailsTitles(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'issue_id': '19',
          'title': 'Non acquisition of private land',
          'location': '28-29KM',
        },
        <String, dynamic>{
          'issue_id': '20',
          'title': '',
          'location': 'Fallback Loc',
        },
      ],
    );
    expect(titles, hasLength(2));
    expect(titles.first.issueId, '19');
    expect(titles.first.label, 'Non acquisition of private land');
    expect(titles.last.label, 'Fallback Loc');
  });

  test('generate body maps hod_user_id_fk to user id, not display name', () {
    final Map<String, dynamic> body = buildIssueDetailsGenerateBody(
      hodUserId: 'PMIS_SU_002',
      contractId: 'P24EN01',
      status: 'Raised',
      location: '28-29KM',
      category: 'Contract',
      issueId: '19',
    );
    expect(body, <String, dynamic>{
      'hod_user_id_fk': 'PMIS_SU_002',
      'contract_id_fk': 'P24EN01',
      'status_fk': 'Raised',
      'location': '28-29KM',
      'category_fk': 'Contract',
      'issue_id': '19',
    });
    expect(body['hod_user_id_fk'], isNot(equals('M V PRASAD')));

    final Map<String, dynamic> cleared = buildIssueDetailsGenerateBody(
      hodUserId: '',
      contractId: '',
      status: '',
      location: '',
      category: '',
      issueId: '',
    );
    expect(cleared.keys.toList(), <String>[
      'hod_user_id_fk',
      'contract_id_fk',
      'status_fk',
      'location',
      'category_fk',
      'issue_id',
    ]);
    expect(cleared.values.every((Object? v) => v == ''), isTrue);
  });
}
