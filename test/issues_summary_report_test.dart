import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/issues_summary_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/list_of_contractors_report.dart';

void main() {
  test('detects Issues Summary Report by name, url, and formId', () {
    expect(
      isIssuesSummaryReport(
        formId: '292',
        formName: 'Issues Summary Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isIssuesSummaryReport(
        formId: '',
        formName: 'Issues Summary Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isIssuesSummaryReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'issues-summary-report',
      ),
      isTrue,
    );
    expect(
      isIssuesSummaryReport(
        formId: '',
        formName: 'Other',
        webFormUrl: '/api/issues-report/issues-summary-report/ALL',
      ),
      isTrue,
    );
    expect(
      isIssuesSummaryReport(
        formId: '292',
        formName: '',
        webFormUrl: '',
      ),
      isTrue,
    );
  });

  test('does not collide with Pending Issues, Issue Details, or Contractors', () {
    expect(
      isIssuesSummaryReport(
        formId: '290',
        formName: 'Pending Issues Report',
        webFormUrl: '',
      ),
      isFalse,
    );
    expect(
      isIssuesSummaryReport(
        formId: '',
        formName: 'Pending Issues Report',
        webFormUrl: '',
      ),
      isFalse,
    );
    expect(
      isIssuesSummaryReport(
        formId: '291',
        formName: 'Issue Details Report',
        webFormUrl: '',
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
    expect(
      isIssuesSummaryReport(
        formId: '290',
        formName: 'List of Contractors',
        webFormUrl: 'contractorslist',
      ),
      isFalse,
    );
    expect(
      isListOfContractorsReport(
        formId: '292',
        formName: 'Issues Summary Report',
        webFormUrl: '',
      ),
      isFalse,
    );
  });
}
