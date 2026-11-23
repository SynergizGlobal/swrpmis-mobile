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
        'description': '1',
        'units': '%',
      },
    );
    expect(m.component, 'Foundation');
    expect(m.element, 'Open Foundation');
    expect(m.description, '1');
    expect(m.totalQty, 40);
  });

  test('parses all multi-element measurement rows with description', () {
    final RfiInspectionDetails details = RfiInspectionDetails.fromJson(
      <String, dynamic>{
        'rfi': <String, dynamic>{'id': 1, 'rfiCategory': 'WORK'},
        'measurements': <Map<String, dynamic>>[
          <String, dynamic>{
            'component': 'Foundation',
            'element': 'Open Foundation',
            'activityName': 'Reinforcement & Shuttering',
            'description': '1',
            'measurementType': 'Area',
            'units': 'cm²',
            'length': 1,
            'breadth': 2,
            'noOfItems': 1,
            'totalQty': 2,
          },
          <String, dynamic>{
            'component': 'Foundation',
            'element': 'Open Foundation',
            'activityName': 'Concreting',
            'description': 'aa',
            'measurementType': 'Length',
            'units': 'mm',
            'length': 22,
            'noOfItems': 2,
            'totalQty': 44,
          },
          <String, dynamic>{
            'component': 'Return Wall',
            'element': 'Return Wall 1',
            'activityName': 'Foundation',
            'description': '--',
            'measurementType': 'Number',
            'units': 'Nos',
            'noOfItems': 22,
            'totalQty': 22,
          },
        ],
      },
    );

    expect(details.measurements, hasLength(3));
    expect(
      details.measurements.map((RfiInspectionMeasurement m) => m.description),
      <String>['1', 'aa', '--'],
    );
    expect(details.measurements[0].component, 'Foundation');
    expect(details.measurements[2].element, 'Return Wall 1');
    expect(details.measurements[1].totalQty, 44);
  });
}
