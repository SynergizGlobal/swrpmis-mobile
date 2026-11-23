import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/works/data/daily_progress_export_file.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/daily_progress_row.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds Daily Progress xlsx and pdf bytes', () async {
    final List<DailyProgressRow> rows = <DailyProgressRow>[
      DailyProgressRow(
        unit: 'Cum',
        plannedTillDate: 100,
        actualTillDate: 40,
        askingRatePerDay: 5,
        actualForDay: 2,
        cumulativeActual: 40,
        scope: 100,
        structure: 'CH 1',
        structureType: 'Earthwork Cutting',
        section: 'Section A',
        tdc: DateTime(2026, 11, 2),
      ),
      DailyProgressRow(
        unit: 'Cum',
        plannedTillDate: 50,
        actualTillDate: 10,
        askingRatePerDay: 3,
        actualForDay: 0,
        cumulativeActual: 10,
        scope: 50,
        structure: 'CH 2',
        structureType: 'Earthwork Cutting',
        section: 'Section A',
        tdc: DateTime(2026, 10, 13),
      ),
    ];
    final List<DailyProgressActivityGroup> groups = groupDailyProgress(rows);
    final DateTime reportDate = DateTime(2026, 11, 23);

    final xlsx = buildDailyProgressXlsxBytes(
      groups: groups,
      reportDate: reportDate,
    );
    final pdf = await buildDailyProgressPdfBytes(
      groups: groups,
      reportDate: reportDate,
    );

    expect(xlsx, isNotEmpty);
    expect(pdf, isNotEmpty);
    expect(
      dailyProgressExportFileName(reportDate: reportDate, extension: 'xlsx'),
      'Daily_Progress_2026-11-23.xlsx',
    );
    expect(
      dailyProgressExportFileName(reportDate: reportDate, extension: 'pdf'),
      'Daily_Progress_2026-11-23.pdf',
    );
  });
}
