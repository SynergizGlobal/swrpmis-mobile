import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/contract_detail_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/quality_control_summary_report.dart';

void main() {
  test('detects Quality Control Summary Tests Report by formId, url, name', () {
    expect(
      isQualityControlSummaryReport(
        formId: '1404',
        formName: 'Quality Control Summary Tests Report',
        webFormUrl: 'qualitytestsummaryreport',
      ),
      isTrue,
    );
    expect(
      isQualityControlSummaryReport(
        formId: '',
        formName: 'Quality Control Summary Tests Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isQualityControlSummaryReport(
        formId: '',
        formName: 'Other',
        webFormUrl: '/reports/qualitytestsummaryreport',
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
    expect(
      isQualityControlSummaryReport(
        formId: '',
        formName: 'Quality Control',
        webFormUrl: '',
      ),
      isFalse,
    );
  });

  test('parses projects and skips null project ids', () {
    final List<ContractDetailOption> projects = parseQualitySummaryProjects(
      <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'projectIdFk': 'P19',
            'projectName': 'Bagalkot-Kudachi New Railway Line',
          },
          <String, dynamic>{
            'projectIdFk': null,
            'projectName': 'Should Skip',
          },
          <String, dynamic>{
            'projectIdFk': 'P20',
            'projectName': 'Another Project',
          },
        ],
      },
    );
    expect(projects.map((ContractDetailOption o) => o.id).toList(), <String>[
      'P19',
      'P20',
    ]);
    expect(projects.first.label, 'Bagalkot-Kudachi New Railway Line');
  });

  test('parses contracts from name/id payload', () {
    final List<ContractDetailOption> contracts = parseQualitySummaryContracts(
      <Map<String, dynamic>>[
        <String, dynamic>{'id': 'C1', 'name': 'P19EN01- BK-KD-ROB-01'},
        <String, dynamic>{'id': 'C2', 'name': 'Other Contract'},
      ],
    );
    expect(contracts, hasLength(2));
    expect(contracts.first.id, 'C1');
    expect(contracts.first.label, 'P19EN01- BK-KD-ROB-01');
  });

  test('parses summary report sections and formats zero as dash', () {
    final QualityControlSummaryReport report =
        QualityControlSummaryReport.fromJson(<String, dynamic>{
          'projectName': 'Bagalkot-Kudachi New Railway Line',
          'contractShortName': 'BK-KD-ROB-01',
          'contractorName': 'abc',
          'periodFrom': <int>[2026, 11, 18],
          'periodTo': <int>[2026, 11, 20],
          'sections': <Map<String, dynamic>>[
            <String, dynamic>{
              'srNo': '1',
              'title': 'Steel Reinforcement Bar',
              'rows': <Map<String, dynamic>>[
                <String, dynamic>{
                  'label': 'a',
                  'testName': 'Tensile Strength Test',
                  'unit': 'MT',
                  'frequency': 'Per Batch / Lot',
                  'previous': <String, dynamic>{
                    'performed': 0,
                    'passed': 0,
                    'failed': 0,
                  },
                  'current': <String, dynamic>{
                    'performed': 2,
                    'passed': 1,
                    'failed': 1,
                  },
                  'cumulative': <String, dynamic>{
                    'performed': 2,
                    'passed': 1,
                    'failed': 1,
                  },
                },
              ],
            },
          ],
        });

    expect(report.projectName, 'Bagalkot-Kudachi New Railway Line');
    expect(report.contractShortName, 'BK-KD-ROB-01');
    expect(report.contractorName, 'abc');
    expect(report.periodLabel, '18-11-2026 - 20-11-2026');
    expect(report.sections, hasLength(1));
    expect(report.sections.single.title, 'Steel Reinforcement Bar');
    expect(report.sections.single.rows.single.testName, 'Tensile Strength Test');
    expect(qualitySummaryCountDisplay(0), '-');
    expect(qualitySummaryCountDisplay(2), '2');
    expect(qualitySummaryDashOrText(''), '-');
    expect(qualitySummaryDashOrText('MT'), 'MT');
  });
}
