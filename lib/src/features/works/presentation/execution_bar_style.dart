import 'package:flutter/material.dart';

abstract final class ExecutionBarColors {
  static const Color completed = Color(0xFF008000);
  static const Color almostCompleted = Color(0xFF90EE90);
  static const Color inProgress = Color(0xFFFFA500);
  static const Color notStarted = Color(0xFF808080);
  static const Color notAwarded = Color(0xFFFF0000);
  static const Color yellow = Color(0xFFFFEB3B);
  static const Color blue = Color(0xFF1976D2);
}

class ExecutionLegendItem {
  const ExecutionLegendItem({required this.label, required this.color});

  final String label;
  final Color color;
}

const List<ExecutionLegendItem> executionLegendItems = <ExecutionLegendItem>[
  ExecutionLegendItem(
    label: 'Completed (100%)',
    color: ExecutionBarColors.completed,
  ),
  ExecutionLegendItem(
    label: 'Almost Completed (90–99%)',
    color: ExecutionBarColors.almostCompleted,
  ),
  ExecutionLegendItem(
    label: 'In Progress',
    color: ExecutionBarColors.inProgress,
  ),
  ExecutionLegendItem(
    label: 'Not Started',
    color: ExecutionBarColors.notStarted,
  ),
  ExecutionLegendItem(
    label: 'Not Awarded',
    color: ExecutionBarColors.notAwarded,
  ),
];

Color executionSegmentColor({
  required String barColor,
  required String status,
  required double progress,
}) {
  if (!_isGenericGrey(barColor)) {
    final Color? named = _namedColor(barColor);
    if (named != null) {
      return named;
    }
  }
  return _statusColor(status, progress);
}

bool _isGenericGrey(String raw) {
  final String key = raw.trim().toLowerCase().replaceAll(
    RegExp(r'[\s_-]+'),
    '',
  );
  return key.isEmpty || key == 'grey' || key == 'gray';
}

Color? _namedColor(String raw) {
  final String key = raw.trim().toLowerCase().replaceAll(
    RegExp(r'[\s_-]+'),
    '',
  );
  if (key.isEmpty) {
    return null;
  }
  return switch (key) {
    'grey' || 'gray' => ExecutionBarColors.notStarted,
    'red' => ExecutionBarColors.notAwarded,
    'green' => ExecutionBarColors.completed,
    'lightgreen' || 'lime' => ExecutionBarColors.almostCompleted,
    'yellow' => ExecutionBarColors.yellow,
    'orange' || 'amber' => ExecutionBarColors.inProgress,
    'blue' => ExecutionBarColors.blue,
    _ => null,
  };
}

Color _statusColor(String status, double progress) {
  final String normalized = status.toLowerCase().trim();
  final String compact = normalized.replaceAll(RegExp(r'\s+'), '');
  if (compact.contains('notawarded')) {
    return ExecutionBarColors.notAwarded;
  }
  if (!progress.isNaN) {
    if (progress >= 100) {
      return ExecutionBarColors.completed;
    }
    if (progress >= 90 && progress < 100) {
      return ExecutionBarColors.almostCompleted;
    }
    if (progress > 0 && progress < 90) {
      return ExecutionBarColors.inProgress;
    }
    if (progress == 0) {
      return ExecutionBarColors.notStarted;
    }
  }
  if (normalized.contains('completed')) {
    return ExecutionBarColors.completed;
  }
  if (normalized.contains('progress')) {
    return ExecutionBarColors.inProgress;
  }
  if (normalized.contains('not started') || compact.contains('notstarted')) {
    return ExecutionBarColors.notStarted;
  }
  return ExecutionBarColors.notAwarded;
}
