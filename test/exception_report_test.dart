import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/exception_report.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/exception_report_detail.dart';

void main() {
  group('ApiConstants exception report', () {
    test('list and detail paths', () {
      expect(ApiConstants.exceptionReportPath, '/api/exception-report');
      expect(
        ApiConstants.exceptionReportStructurePath(167),
        '/api/exception-report/structures/167',
      );
    });
  });

  group('ExceptionReportData.fromMap', () {
    test('parses summary and null-safe drawings/utility', () {
      final ExceptionReportData data = ExceptionReportData.fromMap(
        <String, dynamic>{
          'summary': <String, dynamic>{
            'criticalExceptions': 28,
            'structuresMonitored': 140,
            'generalDrawingsPending': 30,
            'detailedDrawingsPending': 10,
            'utilityShiftingImpacted': 43,
          },
          'structures': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 167,
              'tdc': '2026-11-02',
              'name': 'CH 25400 to CH 34000',
              'type': 'Earthwork',
              'unit': 'km',
              'scope': '8.6 km',
              'actual': 4.2,
              'issues': 3,
              'actualKm': 0.36,
              'contract': 'Contract A',
              'exception': 'Open Issues',
              'contractId': 'P01EN01',
              'frontTotal': 8.6,
              'utilityDone': 0.325,
              'utilityTotal': 1.925,
              'frontAvailable': 8.21,
              'generalDrawing': null,
              'detailedDrawing': null,
            },
            <String, dynamic>{
              'id': 17,
              'tdc': '2026-10-05',
              'name': 'MNB 25 CH 25631 (RCC BOX)',
              'type': 'Minor Bridge',
              'unit': 'm',
              'scope': '100%',
              'actual': 43,
              'issues': 0,
              'actualKm': null,
              'contract': 'Contract A',
              'exception': 'On Track',
              'contractId': 'P01EN01',
              'frontTotal': 3,
              'utilityDone': null,
              'utilityTotal': null,
              'frontAvailable': 0,
              'generalDrawing': 'Approved',
              'detailedDrawing': null,
            },
            <String, dynamic>{
              'id': 82,
              'tdc': '2027-01-29',
              'name': 'MJB 33 CH 29123 (PSC Slab)',
              'type': 'Major Bridge',
              'unit': 'm',
              'scope': '100%',
              'actual': 0,
              'issues': 0,
              'actualKm': null,
              'contract': 'Contract A',
              'exception': 'Drawing Pending',
              'contractId': 'P01EN01',
              'frontTotal': 12.2,
              'utilityDone': null,
              'utilityTotal': null,
              'frontAvailable': 12.2,
              'generalDrawing': 'Under Review',
              'detailedDrawing': 'Under Review',
            },
          ],
        },
      );

      expect(data.summary.structuresMonitored, 140);
      expect(data.summary.criticalExceptions, 28);
      expect(data.structures.length, 3);

      final ExceptionReportStructure earthwork = data.structures.first;
      expect(earthwork.generalDrawingLabel, 'Not Available');
      expect(earthwork.generalDrawingDot, DrawingStatusDot.none);
      expect(earthwork.utilityShiftingLabel, '0.3 / 1.9 km');
      expect(earthwork.frontAvailableLabel, '8.2 / 8.6 km');
      expect(earthwork.actualProgressLabel, '0.36 km');
      expect(earthwork.tdcLabel, '02 Nov 2026');
      expect(earthwork.frontAvailabilityCategory, 'Partially Available');
      expect(earthwork.utilityShiftingCategory, 'Impacted');

      final ExceptionReportStructure approved = data.structures[1];
      expect(approved.generalDrawingLabel, 'Approved');
      expect(approved.generalDrawingDot, DrawingStatusDot.approved);
      expect(approved.utilityShiftingLabel, '—');
      expect(approved.actualProgressLabel, '43%');
      expect(approved.frontAvailabilityCategory, 'Not Available');
      expect(approved.utilityShiftingCategory, 'Not Applicable');

      final ExceptionReportStructure review = data.structures[2];
      expect(review.generalDrawingDot, DrawingStatusDot.underReview);
      expect(review.drawingStatusCategory, 'Under Review');
      expect(review.frontAvailabilityCategory, 'Fully Available');
    });
  });

  group('ExceptionReportFilters', () {
    late List<ExceptionReportStructure> rows;

    setUp(() {
      rows = ExceptionReportData.fromMap(<String, dynamic>{
        'summary': <String, dynamic>{},
        'structures': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'name': 'CH 25400 to CH 34000',
            'type': 'Earthwork',
            'unit': 'km',
            'scope': '8.6 km',
            'actual': 4.2,
            'issues': 3,
            'actualKm': 0.36,
            'exception': 'Open Issues',
            'frontTotal': 8.6,
            'frontAvailable': 8.21,
            'utilityDone': 0.3,
            'utilityTotal': 1.9,
            'generalDrawing': null,
            'detailedDrawing': null,
            'tdc': '2026-11-02',
          },
          <String, dynamic>{
            'id': 2,
            'name': 'MNB 25 CH 25631 (RCC BOX)',
            'type': 'Minor Bridge',
            'unit': 'm',
            'scope': '100%',
            'actual': 43,
            'issues': 0,
            'exception': 'On Track',
            'frontTotal': 3,
            'frontAvailable': 0,
            'generalDrawing': 'Approved',
            'detailedDrawing': null,
            'tdc': '2026-10-05',
          },
          <String, dynamic>{
            'id': 3,
            'name': 'MJB 33 CH 29123',
            'type': 'Major Bridge',
            'unit': 'm',
            'scope': '100%',
            'actual': 0,
            'issues': 0,
            'exception': 'Drawing Pending',
            'frontTotal': 12.2,
            'frontAvailable': 12.2,
            'generalDrawing': 'Under Review',
            'detailedDrawing': 'Under Review',
            'tdc': '2027-01-29',
          },
        ],
      }).structures;
    });

    test('filters by structure type and search', () {
      final List<ExceptionReportStructure> filtered =
          ExceptionReportFilters.apply(
        rows,
        const ExceptionReportFilterState(
          structureType: 'Earthwork',
          searchQuery: '25400',
        ),
      );
      expect(filtered.length, 1);
      expect(filtered.single.id, 1);
    });

    test('filters by drawing status and exception category', () {
      final List<ExceptionReportStructure> filtered =
          ExceptionReportFilters.apply(
        rows,
        const ExceptionReportFilterState(
          drawingStatus: 'Under Review',
          exceptionCategory: 'Drawing Pending',
        ),
      );
      expect(filtered.single.id, 3);
    });

    test('filters by front availability and utility shifting', () {
      final List<ExceptionReportStructure> notAvailable =
          ExceptionReportFilters.apply(
        rows,
        const ExceptionReportFilterState(
          frontAvailability: 'Not Available',
        ),
      );
      expect(notAvailable.single.id, 2);

      final List<ExceptionReportStructure> impacted =
          ExceptionReportFilters.apply(
        rows,
        const ExceptionReportFilterState(
          utilityShifting: 'Impacted',
        ),
      );
      expect(impacted.single.id, 1);
    });

    test('reset clears active filters', () {
      expect(ExceptionReportFilterState.cleared.hasActiveFilters, isFalse);
      expect(
        const ExceptionReportFilterState(
          structureType: 'Earthwork',
        ).hasActiveFilters,
        isTrue,
      );
    });
  });

  group('ExceptionReportDetail.fromMap', () {
    test('parses front, utility, issues, and empty drawings', () {
      final ExceptionReportDetail detail = ExceptionReportDetail.fromMap(
        <String, dynamic>{
          'id': 167,
          'name': 'CH 25400 to CH 34000',
          'type': 'Earthwork',
          'status': 'active',
          'contract': 'New Broad gauge line',
          'front': <String, dynamic>{
            'unit': 'km',
            'total': 8.6,
            'available': 8.21,
            'segments': <Map<String, dynamic>>[
              <String, dynamic>{
                'from': 25400,
                'to': 25790,
                'length': 0.39,
                'status': 'Not Available',
                'remarks': 'No land record',
              },
              <String, dynamic>{
                'from': 25790,
                'to': 34000,
                'length': 8.21,
                'status': 'Available',
                'remarks': '–',
              },
            ],
          },
          'utility': <String, dynamic>{
            'done': 0.325,
            'unit': 'km',
            'total': 1.925,
            'segments': <Map<String, dynamic>>[
              <String, dynamic>{
                'from': 25800,
                'to': 25850,
                'type': 'Chartered - Electrical',
                'length': 0.05,
                'status': 'In Progress',
                'remarks': '–',
              },
            ],
          },
          'issues': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'ISS-001',
              'status': 'Raised',
              'category': 'Land Acquisition',
              'raisedOn': '2026-10-22',
              'targetDate': null,
              'description': 'Obstruction/Dispute from land owner post handover',
            },
          ],
          'tabCounts': <String, dynamic>{
            'front': 1,
            'issues': 3,
            'general': 0,
            'utility': 32,
            'detailed': 0,
          },
          'generalDrawings': <String, dynamic>{
            'rows': <dynamic>[],
            'status': null,
          },
          'detailedDrawings': <String, dynamic>{
            'rows': <dynamic>[],
            'status': null,
          },
        },
      );

      expect(detail.title, 'Earthwork – CH 25400 to CH 34000');
      expect(detail.isActive, isTrue);
      expect(detail.front.segments.length, 2);
      expect(detail.front.segments.first.isAvailable, isFalse);
      expect(detail.front.segments.last.isAvailable, isTrue);
      expect(detail.front.segments.last.remarks, '—');
      expect(detail.utility.segments.single.isInProgress, isTrue);
      expect(detail.issues.single.targetDateLabel, '—');
      expect(detail.issues.single.raisedOnLabel, '22 Oct 2026');
      expect(detail.generalDrawings.isEmpty, isTrue);
      expect(detail.generalDrawings.statusLabel, 'Not Available');
      expect(detail.tabCounts.utility, 32);
      expect(detail.front.summaryLabel.contains('8.2'), isTrue);
    });
  });
}
