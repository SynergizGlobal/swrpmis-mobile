import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_dashboard_counts.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_dashboard_card.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_menu.dart';

void main() {
  test('inspection-count 2 and status sample map onto the seven cards', () {
    final RfiDashboardCounts counts = RfiDashboardCounts.fromResponses(
      inspectionCount: 2,
      statusCounts: <String, dynamic>{
        'CLOSED': 2,
        'RESCHEDULED': 1,
        'SUBMITTED': 0,
        'PENDING': 0,
        'APPROVED': 0,
        'REJECTED': 0,
      },
    );

    expect(counts.metrics, <({String label, int count})>[
      (label: 'RFI Created', count: 2),
      (label: 'RFI Scheduled', count: 0),
      (label: 'RFI Rescheduled', count: 1),
      (label: 'RFI Submitted', count: 0),
      (label: 'RFI Approved', count: 0),
      (label: 'RFI Rejected', count: 0),
      (label: 'RFI Closed', count: 2),
    ]);
  });

  test('SCHEDULED wins over PENDING and missing keys are zero', () {
    final RfiDashboardCounts counts = RfiDashboardCounts.fromResponses(
      inspectionCount: <String, dynamic>{'count': 2},
      statusCounts: <String, dynamic>{
        'SCHEDULED': 0,
        'PENDING': 9,
        'rescheduled': '1',
      },
    );

    expect(counts.created, 2);
    expect(counts.scheduled, 0);
    expect(counts.rescheduled, 1);
    expect(counts.submitted, 0);
    expect(counts.approved, 0);
    expect(counts.rejected, 0);
    expect(counts.closed, 0);
  });

  test('a bare numeric string counts as RFI Created', () {
    final RfiDashboardCounts counts = RfiDashboardCounts.fromResponses(
      inspectionCount: '2',
      statusCounts: const <String, dynamic>{},
    );

    expect(counts.created, 2);
    expect(counts.scheduled, 0);
  });

  test('Created, Scheduled, and Approved cards send filterStatus', () {
    final Map<String, dynamic> created = RfiDashboardCardTarget.created.filter
        .toJson();
    expect(RfiDashboardCardTarget.created.section, RfiMenuId.inspection);
    expect(created['filterStatus'], <String>[]);
    expect(created['rfiCategory'], isNull);
    expect(created['projectId'], isNull);
    expect(created['contractId'], isNull);
    expect(created['structureType'], isNull);
    expect(created['structureId'], isNull);
    expect(created['itemId'], isNull);
    expect(created['materialId'], isNull);
    expect(created['qualityOrSafetyId'], isNull);

    final Map<String, dynamic> scheduled = RfiDashboardCardTarget
        .scheduled
        .filter
        .toJson();
    expect(RfiDashboardCardTarget.scheduled.section, RfiMenuId.inspection);
    expect(scheduled['filterStatus'], <String>[
      'CREATED',
      'UPDATED',
      'REASSIGNED',
      'CON_INSP_ONGOING',
      'UNDER_CON_RECTIFICATION',
    ]);

    final Map<String, dynamic> approved = RfiDashboardCardTarget.approved.filter
        .toJson();
    expect(RfiDashboardCardTarget.approved.section, RfiMenuId.log);
    expect(approved['filterStatus'], <String>['APPROVED']);
    expect(approved['rfiCategory'], isNull);
    expect(approved['structureId'], isNull);

    final RfiInspectionFilter kept = RfiDashboardCardTarget.scheduled.filter
        .selectAt(RfiInspectionFilter.projectIndex, text: '9');
    expect(kept.projectId, '9');
    expect(kept.toJson()['filterStatus'], scheduled['filterStatus']);
    expect(rfiDashboardStatusCaption(kept.filterStatus), 'Scheduled');
    expect(
      rfiDashboardStatusCaption(RfiDashboardCardTarget.approved.filterStatus),
      'Approved',
    );
    expect(const RfiInspectionFilter().toJson()['filterStatus'], <String>[]);
    expect(rfiDashboardStatusCaption(const <String>[]), isNull);
  });
}
