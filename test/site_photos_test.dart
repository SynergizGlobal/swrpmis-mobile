import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/constants/api_constants.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/site_photo_row.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/utils/site_photos_filters.dart';

void main() {
  group('ApiConstants site photos', () {
    test('site photos display path and structure file path', () {
      expect(
        ApiConstants.sitePhotosDisplayPath,
        '/execution/site-photos-display',
      );
      expect(
        ApiConstants.structureFilePath('uuid_filename.jpeg'),
        '/STRUCTURE_FILES/uuid_filename.jpeg',
      );
      expect(
        ApiConstants.structureFilePath('a b.jpeg'),
        '/STRUCTURE_FILES/a%20b.jpeg',
      );
    });
  });

  group('SitePhotoRow.fromMap', () {
    test('parses web payload fields and formats date', () {
      final SitePhotoRow row = SitePhotoRow.fromMap(<String, dynamic>{
        'section': 'L441-K441',
        'created_date': '2026-11-12',
        'structure_type': 'Minor Bridge',
        'structure': 'MNB 44 CH 33346 (RCC BOX)',
        'strip_chart_component': 'Foundation',
        'strip_chart_component_id': 'Open Foundation',
        'photos_count': 1,
        'photos': <String>['uuid_filename.jpeg'],
      });

      expect(row.section, 'L441-K441');
      expect(row.displayDate, '12-11-2026');
      expect(row.structureType, 'Minor Bridge');
      expect(row.structure, 'MNB 44 CH 33346 (RCC BOX)');
      expect(row.structureComponent, 'Foundation');
      expect(row.componentId, 'Open Foundation');
      expect(row.photosCount, 1);
      expect(row.photos, <String>['uuid_filename.jpeg']);
      expect(row.hasPhotos, isTrue);
      expect(row.location, 'N/A');
    });

    test('null section becomes N/A and empty photos are safe', () {
      final SitePhotoRow row = SitePhotoRow.fromMap(<String, dynamic>{
        'section': null,
        'created_date': null,
        'structure_type': '',
        'structure': 'CH 55800 to CH 66400',
        'strip_chart_component': 'Earthwork Filling',
        'strip_chart_component_id': 'CH 61000 to CH 62000',
        'photos_count': '0',
        'photos': <dynamic>[],
      });

      expect(row.section, 'N/A');
      expect(row.displayDate, 'N/A');
      expect(row.structureType, 'N/A');
      expect(row.photosCount, 0);
      expect(row.hasPhotos, isFalse);
    });

    test('photos_count falls back to photos length', () {
      final SitePhotoRow row = SitePhotoRow.fromMap(<String, dynamic>{
        'structure': 'A',
        'photos': <String>['a.jpeg', 'b.jpeg'],
      });
      expect(row.photosCount, 2);
    });

    test('parses photos encoded as a JSON-like string', () {
      final SitePhotoRow row = SitePhotoRow.fromMap(<String, dynamic>{
        'structure': 'A',
        'photos': '["one.jpeg", "two.jpeg"]',
      });
      expect(row.photos, <String>['one.jpeg', 'two.jpeg']);
      expect(row.photosCount, 2);
    });
  });

  group('SitePhotosFilters', () {
    final List<SitePhotoRow> rows = <SitePhotoRow>[
      SitePhotoRow.fromMap(<String, dynamic>{
        'section': 'L441-K441',
        'created_date': '2026-11-12',
        'structure_type': 'Minor Bridge',
        'structure': 'MNB 44',
        'strip_chart_component': 'Foundation',
        'strip_chart_component_id': 'Open Foundation',
        'photos_count': 1,
        'photos': <String>['a.jpeg'],
      }),
      SitePhotoRow.fromMap(<String, dynamic>{
        'section': null,
        'created_date': '2026-11-10',
        'structure_type': 'Earthwork',
        'structure': 'CH 34000 to CH 55800',
        'strip_chart_component': 'Earthwork Filling',
        'strip_chart_component_id': 'CH 49000 to CH 50000',
        'photos_count': 1,
        'photos': <String>['b.jpeg'],
      }),
      SitePhotoRow.fromMap(<String, dynamic>{
        'section': 'N/A',
        'created_date': '2026-03-26',
        'structure_type': 'Earthwork',
        'structure': 'CH 34000 to CH 55800',
        'strip_chart_component': 'Earthwork Filling',
        'strip_chart_component_id': 'CH 48000 to CH 49000',
        'photos_count': 1,
        'photos': <String>['c.jpeg'],
      }),
    ];

    test('filters by section including N/A', () {
      final List<SitePhotoRow> filtered = SitePhotosFilters.apply(
        rows,
        const SitePhotosFilterState(section: 'N/A'),
      );
      expect(filtered.length, 2);
      expect(
        filtered.every((SitePhotoRow row) => row.section == 'N/A'),
        isTrue,
      );
    });

    test('filters by structure type and date range', () {
      final List<SitePhotoRow> filtered = SitePhotosFilters.apply(
        rows,
        SitePhotosFilterState(
          structureType: 'Earthwork',
          fromDate: DateTime(2026, 11, 10),
          toDate: DateTime(2026, 11, 11),
        ),
      );
      expect(filtered.length, 1);
      expect(filtered.single.componentId, 'CH 49000 to CH 50000');
    });

    test('cascading options exclude unrelated values', () {
      final SitePhotosFilterState state = const SitePhotosFilterState(
        structureType: 'Minor Bridge',
      );
      expect(
        SitePhotosFilters.structureOptions(rows, state),
        <String>['All', 'MNB 44'],
      );
      expect(
        SitePhotosFilters.componentIdOptions(rows, state),
        <String>['All', 'Open Foundation'],
      );
    });

    test('clear state reports no active filters', () {
      expect(SitePhotosFilterState.cleared.hasActiveFilters, isFalse);
      expect(
        const SitePhotosFilterState(section: 'L441-K441').hasActiveFilters,
        isTrue,
      );
    });

    test('availableDateBounds uses earliest and latest photo days', () {
      final ({DateTime? earliest, DateTime? latest}) bounds =
          SitePhotosFilters.availableDateBounds(rows);
      expect(bounds.earliest, DateTime(2026, 3, 26));
      expect(bounds.latest, DateTime(2026, 11, 12));
    });

    test('clampToAvailable keeps null and clamps out-of-range days', () {
      final DateTime earliest = DateTime(2026, 3, 26);
      final DateTime latest = DateTime(2026, 3, 31);
      expect(
        SitePhotosFilters.clampToAvailable(
          null,
          earliest: earliest,
          latest: latest,
        ),
        isNull,
      );
      expect(
        SitePhotosFilters.clampToAvailable(
          DateTime(2026, 3, 1),
          earliest: earliest,
          latest: latest,
        ),
        earliest,
      );
      expect(
        SitePhotosFilters.clampToAvailable(
          DateTime(2026, 4, 5),
          earliest: earliest,
          latest: latest,
        ),
        latest,
      );
      expect(
        SitePhotosFilters.clampToAvailable(
          DateTime(2026, 3, 28),
          earliest: earliest,
          latest: latest,
        ),
        DateTime(2026, 3, 28),
      );
    });
  });
}
