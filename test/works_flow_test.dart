import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/execution_progress_segment.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/works_tree.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/execution_chart_data.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/execution_bar_style.dart';

void main() {
  test('works tree groups getProjectList by project type id', () {
    final WorksTree tree = WorksTree.fromApi(
      projectTypes: <Map<String, dynamic>>[
        <String, dynamic>{
          'project_type_id': 1,
          'project_type_name': 'Doubling',
        },
        <String, dynamic>{
          'project_type_id': '2',
          'project_type_name': 'New Line',
        },
        <String, dynamic>{
          'project_type_id': '3',
          'project_type_name': 'Special Projects',
        },
      ],
      projects: <Map<String, dynamic>>[
        <String, dynamic>{
          'project_id': 'P01',
          'project_name': '4th Line between Itarsi - Bhopal - Bina',
          'project_type_id_fk': '1',
        },
        <String, dynamic>{
          'project_id': 'P09',
          'project_name': 'Orphan',
          'project_type_id_fk': '99',
        },
        <String, dynamic>{
          'project_id': 'P02',
          'project_name': 'Tumkuru - Chitradurga - Davangere New Line Project',
          'project_type_id_fk': 2,
        },
      ],
    );

    expect(
      tree.sections.map((WorksTypeSection section) => section.name),
      <String>['Doubling', 'New Line', 'Special Projects'],
    );
    expect(tree.sections.first.projects.single.id, 'P01');
    expect(tree.sections[1].projects.single.name, contains('Tumkuru'));
    expect(tree.sections.last.projects, isEmpty);
  });

  test('chart clamps full range to the last plotted kilometre', () {
    final ExecutionChartData chart =
        ExecutionChartData.fromSegments(<ExecutionProgressSegment>[
          _segment(
            structureType: 'Earthwork',
            fromKm: 745,
            toKm: 800,
            projectFromKm: 745,
            projectToKm: 981.16,
            projectSection: 'Hiriyur - Tavaerekere',
          ),
          _segment(
            structureType: 'Major Bridge',
            fromKm: 810,
            toKm: 810,
            projectFromKm: 745,
            projectToKm: 981.16,
            projectSection: 'Hiriyur - Tavaerekere',
          ),
          _segment(
            structureType: 'Earthwork',
            fromKm: 900,
            toKm: 975.357,
            projectFromKm: 745,
            projectToKm: 981.16,
            projectSection: 'Hiriyur - Tavaerekere',
          ),
        ], now: DateTime(2026, 10, 5));

    expect(chart.fromKm, 745);
    expect(chart.toKm, 975.357);
    expect(chart.rangeKm, closeTo(230.357, 0.001));
    expect(
      chart.rows.map((ExecutionChartRow row) => row.structureType),
      <String>['Earthwork', 'Major Bridge'],
    );
    expect(chart.rows.first.serialNumber, 1);
    expect(chart.sections.single.name, 'Hiriyur - Tavaerekere');
    expect(chart.asOnLabel, '05-10-2026');

    final KmWindow window = chart.visibleWindow(
      viewportWidth: 300,
      scrollOffset: 0,
    );
    expect(window.startKm, 745);
    expect(window.endKm, closeTo(820, 0.001));
  });

  test('overlapping spans stack on later layers', () {
    final ExecutionChartData chart =
        ExecutionChartData.fromSegments(<ExecutionProgressSegment>[
          _segment(structureType: 'Track work', fromKm: 10, toKm: 40),
          _segment(structureType: 'Track work', fromKm: 20, toKm: 30),
          _segment(structureType: 'Track work', fromKm: 40, toKm: 50),
        ]);
    final List<int> layers = chart.rows.single.segments
        .map((PlottedSegment plotted) => plotted.layer)
        .toList();
    expect(layers, <int>[0, 1, 0]);
  });

  test('barColor overrides status and chainage uses from-to kilometres', () {
    final ExecutionProgressSegment? segment =
        ExecutionProgressSegment.tryParse(<String, dynamic>{
          'project': '4th Line between Itarsi - Bhopal - Bina',
          'projectFromKm': 745,
          'projectToKm': 981.16,
          'contract': 'EPC Contract',
          'contract_name': 'Named contract',
          'contractor': 'M/s GIRIRAJ CIVIL DEVELOPERS LIMITED - MUMBAI',
          'subStructure': 'CH 34000 to CH 55800',
          'fromKm': 34,
          'toKm': 55.8,
          'status': 'NOT AWARDED',
          'progress': 33.38,
          'barColor': 'Grey',
          'structureType': 'Earthwork',
          'progressDate': '2026-10-01',
          'contractShortName': '',
          'projectSection': 'Thimmarajanahalli - Tavaerekere',
        });

    expect(segment, isNotNull);
    expect(segment!.contractShortLabel, 'Named contract');
    expect(segment.chainageLabel, '34.000 to 55.800');
    expect(segment.progressLabel, '33.38%');
    expect(segment.statusLabel, 'NOT AWARDED');
    expect(
      executionSegmentColor(
        barColor: segment.barColor,
        status: segment.status,
        progress: segment.progress,
      ),
      ExecutionBarColors.notStarted,
    );
    expect(
      executionSegmentColor(
        barColor: '',
        status: 'NOT AWARDED',
        progress: 33.38,
      ),
      ExecutionBarColors.notAwarded,
    );
    expect(
      executionSegmentColor(barColor: '', status: 'IN PROGRESS', progress: 95),
      ExecutionBarColors.almostCompleted,
    );
    expect(
      executionSegmentColor(
        barColor: 'Yellow',
        status: 'COMPLETED',
        progress: 100,
      ),
      ExecutionBarColors.yellow,
    );

    final ExecutionChartData chart = ExecutionChartData.fromSegments(
      <ExecutionProgressSegment>[segment],
      now: DateTime(2026, 10, 5),
    );
    expect(chart.asOnLabel, '01-10-2026');
  });
}

ExecutionProgressSegment _segment({
  required String structureType,
  required double fromKm,
  required double toKm,
  double projectFromKm = 0,
  double projectToKm = 100,
  String projectSection = '',
}) {
  return ExecutionProgressSegment.tryParse(<String, dynamic>{
    'project': 'Sample',
    'projectFromKm': projectFromKm,
    'projectToKm': projectToKm,
    'fromKm': fromKm,
    'toKm': toKm,
    'structureType': structureType,
    'status': 'NOT AWARDED',
    'progress': 10,
    'projectSection': projectSection,
  })!;
}
