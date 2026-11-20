import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/quality_control_summary_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/rfi_summary_report.dart';

void main() {
  test('detects RFI Summary Report by formId, url, name', () {
    expect(
      isRfiSummaryReport(
        formId: '1405',
        formName: 'RFI Summary Report',
        webFormUrl: 'rfisummaryreport',
      ),
      isTrue,
    );
    expect(
      isRfiSummaryReport(
        formId: '',
        formName: 'RFI Summary Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isRfiSummaryReport(
        formId: '',
        formName: 'Other',
        webFormUrl: '/rfi-summary-report',
      ),
      isTrue,
    );
    expect(
      isRfiSummaryReport(
        formId: '1404',
        formName: 'Quality Control Summary Tests Report',
        webFormUrl: 'qualitytestsummaryreport',
      ),
      isFalse,
    );
    expect(
      isRfiSummaryReport(
        formId: '',
        formName: 'RFI List',
        webFormUrl: '',
      ),
      isFalse,
    );
  });

  test('RFI Summary and QC Summary detectors are mutually exclusive for 1405', () {
    expect(
      isRfiSummaryReport(
        formId: '1405',
        formName: 'RFI Summary Report',
        webFormUrl: 'rfisummaryreport',
      ),
      isTrue,
    );
    expect(
      isQualityControlSummaryReport(
        formId: '1405',
        formName: 'RFI Summary Report',
        webFormUrl: 'rfisummaryreport',
      ),
      isFalse,
    );
  });

  test('parses value/label options from list and single object', () {
    final List<ContractDetailOption> fromList = parseRfiSummaryOptions(
      <Map<String, dynamic>>[
        <String, dynamic>{'value': 'P01', 'label': 'Bengaluru Railway Projects'},
        <String, dynamic>{'value': 'P02', 'label': 'Other Project'},
        <String, dynamic>{'value': '', 'label': 'Skip empty'},
      ],
    );
    expect(fromList.map((ContractDetailOption o) => o.id).toList(), <String>[
      'P01',
      'P02',
    ]);
    expect(fromList.first.label, 'Bengaluru Railway Projects');

    final List<ContractDetailOption> fromSingle = parseRfiSummaryOptions(
      <String, dynamic>{'value': 'WORK', 'label': 'Work'},
    );
    expect(fromSingle, hasLength(1));
    expect(fromSingle.first.id, 'WORK');
    expect(fromSingle.first.label, 'Work');

    final List<ContractDetailOption> fromEnvelope = parseRfiSummaryOptions(
      <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'value': 'C1', 'label': 'Contract One'},
        ],
      },
    );
    expect(fromEnvelope.single.id, 'C1');
    expect(fromEnvelope.single.label, 'Contract One');
  });

  test('parses date-range minDate/maxDate and builds hint', () {
    final RfiSummaryDateRange range = RfiSummaryDateRange.fromJson(
      <String, dynamic>{
        'minDate': '2026-11-02',
        'maxDate': '2026-11-12',
      },
    );
    expect(range.minDate, DateTime(2026, 11, 2));
    expect(range.maxDate, DateTime(2026, 11, 12));
    expect(
      range.hintLabel,
      'Available submission dates: 2026-11-02 to 2026-11-12. '
      'Leave dates blank to include the full range.',
    );

    final RfiSummaryDateRange nested = RfiSummaryDateRange.fromJson(
      <String, dynamic>{
        'data': <String, dynamic>{
          'minDate': '2026-01-01',
          'maxDate': '2026-01-31',
        },
      },
    );
    expect(nested.minDate, DateTime(2026, 1, 1));
    expect(nested.maxDate, DateTime(2026, 1, 31));
  });
}
