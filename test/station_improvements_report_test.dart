import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/activities_export_option.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/station_improvements_report.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/tpc_status_report.dart';

void main() {
  test('detects Station Improvement Progress Report by name and url', () {
    expect(
      isStationImprovementsReport(
        formId: '',
        formName: 'Station Improvement Progress Report',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isStationImprovementsReport(
        formId: '',
        formName: 'station improvement',
        webFormUrl: '',
      ),
      isTrue,
    );
    expect(
      isStationImprovementsReport(
        formId: '',
        formName: 'Other',
        webFormUrl: 'station-improvements-report',
      ),
      isTrue,
    );
    expect(
      isStationImprovementsReport(
        formId: '',
        formName: 'Other',
        webFormUrl: '/api/activities-export/station-improvements-report',
      ),
      isTrue,
    );
  });

  test('does not collide with TPC, Activities Export, or FOB', () {
    expect(
      isStationImprovementsReport(
        formId: '',
        formName: 'TPC',
        webFormUrl: 'tpc-status-report',
      ),
      isFalse,
    );
    expect(
      isStationImprovementsReport(
        formId: '1319',
        formName: 'Contract-wise Activities',
        webFormUrl: 'activities-export-report',
      ),
      isFalse,
    );
    expect(
      isStationImprovementsReport(
        formId: '276',
        formName: 'FOB',
        webFormUrl: 'fob-report',
      ),
      isFalse,
    );
    expect(
      isTpcStatusReport(
        formId: '',
        formName: 'Station Improvement Progress Report',
        webFormUrl: 'station-improvements-report',
      ),
      isFalse,
    );
    expect(
      isActivitiesExportReport(
        formId: '',
        formName: 'Station Improvement Progress Report',
        webFormUrl: 'station-improvements-report',
      ),
      isFalse,
    );
  });
}
