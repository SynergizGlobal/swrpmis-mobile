import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/site_photo_row.dart';

class SitePhotosFilterState {
  const SitePhotosFilterState({
    this.section = SitePhotosFilters.all,
    this.structureType = SitePhotosFilters.all,
    this.structure = SitePhotosFilters.all,
    this.structureComponent = SitePhotosFilters.all,
    this.componentId = SitePhotosFilters.all,
    this.fromDate,
    this.toDate,
  });

  static const SitePhotosFilterState cleared = SitePhotosFilterState();

  final String section;
  final String structureType;
  final String structure;
  final String structureComponent;
  final String componentId;
  final DateTime? fromDate;
  final DateTime? toDate;

  bool get hasActiveFilters =>
      section != SitePhotosFilters.all ||
      structureType != SitePhotosFilters.all ||
      structure != SitePhotosFilters.all ||
      structureComponent != SitePhotosFilters.all ||
      componentId != SitePhotosFilters.all ||
      fromDate != null ||
      toDate != null;

  SitePhotosFilterState copyWith({
    String? section,
    String? structureType,
    String? structure,
    String? structureComponent,
    String? componentId,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) {
    return SitePhotosFilterState(
      section: section ?? this.section,
      structureType: structureType ?? this.structureType,
      structure: structure ?? this.structure,
      structureComponent: structureComponent ?? this.structureComponent,
      componentId: componentId ?? this.componentId,
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
    );
  }
}

class SitePhotosFilters {
  SitePhotosFilters._();

  static const String all = 'All';

  static List<SitePhotoRow> apply(
    List<SitePhotoRow> rows,
    SitePhotosFilterState state,
  ) {
    return rows.where((SitePhotoRow row) => _matches(row, state)).toList();
  }

  static List<String> sectionOptions(
    List<SitePhotoRow> rows,
    SitePhotosFilterState state,
  ) {
    final Iterable<SitePhotoRow> scoped = rows.where(
      (SitePhotoRow row) => _matches(row, state, applySection: false),
    );
    return _withAll(
      _uniqueStrings(scoped.map((SitePhotoRow row) => row.sectionFilterValue)),
    );
  }

  static List<String> structureTypeOptions(
    List<SitePhotoRow> rows,
    SitePhotosFilterState state,
  ) {
    final Iterable<SitePhotoRow> scoped = rows.where(
      (SitePhotoRow row) => _matches(row, state, applyStructureType: false),
    );
    return _withAll(
      _uniqueStrings(
        scoped.map((SitePhotoRow row) => row.structureTypeFilterValue),
      ),
    );
  }

  static List<String> structureOptions(
    List<SitePhotoRow> rows,
    SitePhotosFilterState state,
  ) {
    final Iterable<SitePhotoRow> scoped = rows.where(
      (SitePhotoRow row) => _matches(row, state, applyStructure: false),
    );
    return _withAll(
      _uniqueStrings(scoped.map((SitePhotoRow row) => row.structureFilterValue)),
    );
  }

  static List<String> structureComponentOptions(
    List<SitePhotoRow> rows,
    SitePhotosFilterState state,
  ) {
    final Iterable<SitePhotoRow> scoped = rows.where(
      (SitePhotoRow row) =>
          _matches(row, state, applyStructureComponent: false),
    );
    return _withAll(
      _uniqueStrings(
        scoped.map((SitePhotoRow row) => row.structureComponentFilterValue),
      ),
    );
  }

  static List<String> componentIdOptions(
    List<SitePhotoRow> rows,
    SitePhotosFilterState state,
  ) {
    final Iterable<SitePhotoRow> scoped = rows.where(
      (SitePhotoRow row) => _matches(row, state, applyComponentId: false),
    );
    return _withAll(
      _uniqueStrings(
        scoped.map((SitePhotoRow row) => row.componentIdFilterValue),
      ),
    );
  }

  static String sheetValue(List<String> options, String current) {
    final String normalized = current.trim();
    if (normalized.isEmpty || !options.contains(normalized)) {
      return all;
    }
    return normalized;
  }

  /// Continuous min–max window of photo `created_date` values for the project.
  /// Matches web Site Photos calendar: days outside this range are disabled.
  static ({DateTime? earliest, DateTime? latest}) availableDateBounds(
    List<SitePhotoRow> rows,
  ) {
    DateTime? earliest;
    DateTime? latest;
    for (final SitePhotoRow row in rows) {
      final DateTime? created = row.createdAt;
      if (created == null) {
        continue;
      }
      final DateTime day = DateUtils.dateOnly(created);
      if (earliest == null || day.isBefore(earliest)) {
        earliest = day;
      }
      if (latest == null || day.isAfter(latest)) {
        latest = day;
      }
    }
    return (earliest: earliest, latest: latest);
  }

  /// Clamps a selected day into [earliest, latest]. Null stays null.
  static DateTime? clampToAvailable(
    DateTime? date, {
    required DateTime? earliest,
    required DateTime? latest,
  }) {
    if (date == null || earliest == null || latest == null) {
      return date;
    }
    final DateTime day = DateUtils.dateOnly(date);
    final DateTime first = DateUtils.dateOnly(earliest);
    final DateTime last = DateUtils.dateOnly(latest);
    if (day.isBefore(first)) {
      return first;
    }
    if (day.isAfter(last)) {
      return last;
    }
    return day;
  }

  static bool _matches(
    SitePhotoRow row,
    SitePhotosFilterState state, {
    bool applySection = true,
    bool applyStructureType = true,
    bool applyStructure = true,
    bool applyStructureComponent = true,
    bool applyComponentId = true,
    bool applyDateRange = true,
  }) {
    if (applyDateRange && !_matchesDateRange(row, state)) {
      return false;
    }
    if (applySection &&
        state.section != all &&
        row.sectionFilterValue != state.section) {
      return false;
    }
    if (applyStructureType &&
        state.structureType != all &&
        row.structureTypeFilterValue != state.structureType) {
      return false;
    }
    if (applyStructure &&
        state.structure != all &&
        row.structureFilterValue != state.structure) {
      return false;
    }
    if (applyStructureComponent &&
        state.structureComponent != all &&
        row.structureComponentFilterValue != state.structureComponent) {
      return false;
    }
    if (applyComponentId &&
        state.componentId != all &&
        row.componentIdFilterValue != state.componentId) {
      return false;
    }
    return true;
  }

  static bool _matchesDateRange(SitePhotoRow row, SitePhotosFilterState state) {
    if (state.fromDate == null && state.toDate == null) {
      return true;
    }
    final DateTime? created = row.createdAt;
    if (created == null) {
      return false;
    }
    final DateTime day = DateUtils.dateOnly(created);
    if (state.fromDate != null) {
      final DateTime from = DateUtils.dateOnly(state.fromDate!);
      if (day.isBefore(from)) {
        return false;
      }
    }
    if (state.toDate != null) {
      final DateTime to = DateUtils.dateOnly(state.toDate!);
      if (day.isAfter(to)) {
        return false;
      }
    }
    return true;
  }

  static List<String> _withAll(List<String> values) {
    return <String>[all, ...values];
  }

  static List<String> _uniqueStrings(Iterable<String> values) {
    final Set<String> seen = <String>{};
    final List<String> sorted = <String>[];
    for (final String value in values) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == all || seen.contains(trimmed)) {
        continue;
      }
      seen.add(trimmed);
      sorted.add(trimmed);
    }
    sorted.sort(
      (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    return sorted;
  }
}
