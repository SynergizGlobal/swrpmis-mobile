import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/execution_progress_segment.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/execution_chart_data.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/widgets/execution_progress_chart.dart';

void main() {
  testWidgets('tapping a bar opens the progress detail sheet', (tester) async {
    final ExecutionProgressSegment segment =
        ExecutionProgressSegment.tryParse(<String, dynamic>{
          'project': '4th Line between Itarsi - Bhopal - Bina',
          'projectFromKm': 0,
          'projectToKm': 10,
          'fromKm': 0,
          'toKm': 8,
          'contractShortName': 'New Broad gauge line',
          'contractor': 'M/s GIRIRAJ',
          'structureType': 'Earthwork',
          'subStructure': 'CH 0 to CH 8000',
          'status': 'NOT AWARDED',
          'progress': 33.38,
          'barColor': 'Red',
        })!;
    final ExecutionChartData data = ExecutionChartData.fromSegments(
      <ExecutionProgressSegment>[segment],
      now: DateTime(2026, 10, 5),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExecutionProgressChart(data: data),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('As on 05-10-2026'), findsOneWidget);
    expect(find.text('Completed (100%)'), findsOneWidget);
    expect(find.text('Not Awarded'), findsOneWidget);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    expect(find.text('Contract Short Name'), findsOneWidget);
    expect(find.text('New Broad gauge line'), findsOneWidget);
    expect(find.text('0.000 to 8.000'), findsOneWidget);
    expect(find.text('33.38%'), findsOneWidget);
    expect(find.text('NOT AWARDED'), findsOneWidget);
  });
}
