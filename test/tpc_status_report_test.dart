import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/tpc_status_report.dart';

void main() {
  test('detects TPC Status Report by name, url, and formId', () {
    expect(
      isTpcStatusReport(
        formId: '',
        formName: 'TPC',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isTpcStatusReport(
        formId: '',
        formName: 'TPC Status Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isTpcStatusReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'tpc-status-report',
      ),
      isTrue,
    );
    expect(
      isTpcStatusReport(
        formId: '',
        formName: 'Other',
        webFormUrl: '/api/activities-export/tpc-status-report',
      ),
      isTrue,
    );
    expect(
      isTpcStatusReport(
        formId: 'tpc-123',
        formName: 'Other',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isTpcStatusReport(
        formId: '',
        formName: 'tPc Progress',
        webFormUrl: '',
      ),
      isTrue,
    );
  });

  test('does not match Progress Report siblings without tpc', () {
    expect(
      isTpcStatusReport(
        formId: '276',
        formName: 'FOB',
        webFormUrl: 'fob-report',
      ),
      isFalse,
    );
    expect(
      isTpcStatusReport(
        formId: '',
        formName: 'New Line',
        webFormUrl: '',
      ),
      isFalse,
    );
    expect(
      isTpcStatusReport(
        formId: '',
        formName: 'Network Expansion Works',
        webFormUrl: '',
      ),
      isFalse,
    );
    expect(
      isTpcStatusReport(
        formId: '1319',
        formName: 'Contract-wise Activities',
        webFormUrl: 'activities-export-report',
      ),
      isFalse,
    );
  });
}
