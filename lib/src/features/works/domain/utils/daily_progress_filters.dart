import 'package:swr_pmis_mobile/src/features/works/domain/entities/daily_progress_row.dart';

class DailyProgressFilterState {
  const DailyProgressFilterState({
    this.section = DailyProgressFilters.allSections,
    this.activity = DailyProgressFilters.allActivities,
  });

  static const DailyProgressFilterState cleared = DailyProgressFilterState();

  final String section;
  final String activity;

  bool get hasActiveFilters =>
      section != DailyProgressFilters.allSections ||
      activity != DailyProgressFilters.allActivities;

  int get activeCount {
    int n = 0;
    if (section != DailyProgressFilters.allSections) n++;
    if (activity != DailyProgressFilters.allActivities) n++;
    return n;
  }

  DailyProgressFilterState copyWith({
    String? section,
    String? activity,
  }) {
    return DailyProgressFilterState(
      section: section ?? this.section,
      activity: activity ?? this.activity,
    );
  }
}

class DailyProgressFilters {
  DailyProgressFilters._();

  static const String allSections = 'All Sections';
  static const String allActivities = 'All Activities';

  static List<DailyProgressRow> apply(
    List<DailyProgressRow> rows,
    DailyProgressFilterState state,
  ) {
    return rows.where((DailyProgressRow row) {
      if (state.section != allSections &&
          row.sectionFilterValue != state.section) {
        return false;
      }
      if (state.activity != allActivities &&
          row.activityFilterValue != state.activity) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  static List<String> sectionOptions(List<DailyProgressRow> rows) {
    return <String>[
      allSections,
      ..._unique(rows.map((DailyProgressRow r) => r.sectionFilterValue)),
    ];
  }

  static List<String> activityOptions(List<DailyProgressRow> rows) {
    return <String>[
      allActivities,
      ..._unique(rows.map((DailyProgressRow r) => r.activityFilterValue)),
    ];
  }

  static String sheetValue(List<String> options, String value) {
    return options.contains(value) ? value : options.first;
  }

  static List<String> _unique(Iterable<String> values) {
    final Set<String> seen = <String>{};
    final List<String> out = <String>[];
    for (final String value in values) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == 'N/A' || !seen.add(trimmed)) {
        continue;
      }
      out.add(trimmed);
    }
    out.sort(
      (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    return out;
  }
}
