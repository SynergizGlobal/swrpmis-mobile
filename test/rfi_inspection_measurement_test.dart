import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_inspection_details.dart';

void main() {
  test('measurement rows keep component and element from rfi-details', () {
    final RfiInspectionMeasurement m = RfiInspectionMeasurement.fromJson(
      <String, dynamic>{
        'measurementType': 'Percent',
        'totalQty': 40.0,
        'activityIdFk': 1887,
        'activityName': 'Reinforcement & Shuttering',
        'component': 'Foundation',
        'element': 'Open Foundation',
        'units': '%',
      },
    );
    expect(m.component, 'Foundation');
    expect(m.element, 'Open Foundation');
    expect(m.totalQty, 40);
  });
}
