import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_filter.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_menu.dart';

class RfiDashboardCardTarget {
  const RfiDashboardCardTarget({
    required this.label,
    required this.section,
    required this.filterStatus,
    required this.caption,
  });

  final String label;
  final RfiMenuId section;
  final List<String> filterStatus;
  final String caption;

  RfiInspectionFilter get filter =>
      RfiInspectionFilter(filterStatus: filterStatus);

  static const RfiDashboardCardTarget created = RfiDashboardCardTarget(
    label: 'RFI Created',
    section: RfiMenuId.inspection,
    filterStatus: <String>[],
    caption: '',
  );

  static const RfiDashboardCardTarget scheduled = RfiDashboardCardTarget(
    label: 'RFI Scheduled',
    section: RfiMenuId.inspection,
    filterStatus: <String>[
      'CREATED',
      'UPDATED',
      'REASSIGNED',
      'CON_INSP_ONGOING',
      'UNDER_CON_RECTIFICATION',
    ],
    caption: 'Scheduled',
  );

  static const RfiDashboardCardTarget rescheduled = RfiDashboardCardTarget(
    label: 'RFI Rescheduled',
    section: RfiMenuId.inspection,
    filterStatus: <String>['RESCHEDULED'],
    caption: 'Rescheduled',
  );

  static const RfiDashboardCardTarget submitted = RfiDashboardCardTarget(
    label: 'RFI Submitted',
    section: RfiMenuId.inspection,
    filterStatus: <String>['INSPECTED_BY_CON', 'UNDER_ENGG_RECTIFICATION'],
    caption: 'Submitted',
  );

  static const RfiDashboardCardTarget approved = RfiDashboardCardTarget(
    label: 'RFI Approved',
    section: RfiMenuId.log,
    filterStatus: <String>['APPROVED'],
    caption: 'Approved',
  );

  static const RfiDashboardCardTarget rejected = RfiDashboardCardTarget(
    label: 'RFI Rejected',
    section: RfiMenuId.log,
    filterStatus: <String>['REJECTED'],
    caption: 'Rejected',
  );

  static const RfiDashboardCardTarget closed = RfiDashboardCardTarget(
    label: 'RFI Closed',
    section: RfiMenuId.log,
    filterStatus: <String>['CLOSED'],
    caption: 'Closed',
  );

  static const List<RfiDashboardCardTarget> all = <RfiDashboardCardTarget>[
    created,
    scheduled,
    rescheduled,
    submitted,
    approved,
    rejected,
    closed,
  ];

  static RfiDashboardCardTarget? forLabel(String label) {
    for (final RfiDashboardCardTarget target in all) {
      if (target.label == label) {
        return target;
      }
    }
    return null;
  }
}

String? rfiDashboardStatusCaption(List<String> filterStatus) {
  if (filterStatus.isEmpty) {
    return null;
  }
  for (final RfiDashboardCardTarget target in RfiDashboardCardTarget.all) {
    if (target.caption.isEmpty) {
      continue;
    }
    if (_sameStrings(target.filterStatus, filterStatus)) {
      return target.caption;
    }
  }
  return null;
}

bool _sameStrings(List<String> left, List<String> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
