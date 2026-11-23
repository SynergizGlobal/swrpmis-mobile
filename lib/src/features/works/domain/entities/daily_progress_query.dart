/// Query key for [dailyProgressProvider].
class DailyProgressQuery {
  const DailyProgressQuery({
    required this.projectId,
    required this.fromDate,
    required this.toDate,
  });

  final String projectId;
  final DateTime fromDate;
  final DateTime toDate;

  /// Report / API `date` param — same as [toDate] for single-day reports.
  DateTime get date => toDate;

  @override
  bool operator ==(Object other) {
    return other is DailyProgressQuery &&
        other.projectId == projectId &&
        other.fromDate == fromDate &&
        other.toDate == toDate;
  }

  @override
  int get hashCode => Object.hash(projectId, fromDate, toDate);
}
