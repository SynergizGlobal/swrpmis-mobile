class RfiDashboardCounts {
  const RfiDashboardCounts({
    required this.created,
    required this.scheduled,
    required this.rescheduled,
    required this.submitted,
    required this.approved,
    required this.rejected,
    required this.closed,
  });

  final int created;
  final int scheduled;
  final int rescheduled;
  final int submitted;
  final int approved;
  final int rejected;
  final int closed;

  List<({String label, int count})> get metrics =>
      <({String label, int count})>[
        (label: 'RFI Created', count: created),
        (label: 'RFI Scheduled', count: scheduled),
        (label: 'RFI Rescheduled', count: rescheduled),
        (label: 'RFI Submitted', count: submitted),
        (label: 'RFI Approved', count: approved),
        (label: 'RFI Rejected', count: rejected),
        (label: 'RFI Closed', count: closed),
      ];

  factory RfiDashboardCounts.fromResponses({
    required Object? inspectionCount,
    required Object? statusCounts,
  }) {
    final Map<String, int> status = _statusCounts(statusCounts);
    final int scheduled = status.containsKey('SCHEDULED')
        ? status['SCHEDULED']!
        : status['PENDING'] ?? 0;
    return RfiDashboardCounts(
      created: _count(inspectionCount),
      scheduled: scheduled,
      rescheduled: status['RESCHEDULED'] ?? 0,
      submitted: status['SUBMITTED'] ?? 0,
      approved: status['APPROVED'] ?? 0,
      rejected: status['REJECTED'] ?? 0,
      closed: status['CLOSED'] ?? 0,
    );
  }
}

Map<String, int> _statusCounts(Object? data) {
  if (data is! Map) {
    return const <String, int>{};
  }
  final Map<String, int> counts = <String, int>{};
  data.forEach((Object? key, Object? value) {
    final String name = key.toString().trim().toUpperCase();
    if (name.isEmpty) {
      return;
    }
    counts[name] = _count(value);
  });
  return counts;
}

int _count(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final String text = value.trim();
    if (text.isEmpty) {
      return 0;
    }
    return int.tryParse(text) ?? double.tryParse(text)?.toInt() ?? 0;
  }
  if (value is Map && value.length == 1) {
    return _count(value.values.single);
  }
  return 0;
}
