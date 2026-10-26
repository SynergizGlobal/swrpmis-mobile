import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/domain/ncr_observation_list.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/domain/ncr_observation_parse.dart';

const double _kActionColumnMinWidth = 72;
const Size _kActionButtonSize = Size(32, 32);

class NcrObservationTableColumn {
  const NcrObservationTableColumn({
    required this.label,
    required this.minWidth,
    required this.read,
    this.buildCell,
  });

  final String label;
  final double minWidth;
  final String Function(NcrObservationRow row) read;
  final Widget Function(BuildContext context, NcrObservationRow row)? buildCell;
}

List<NcrObservationTableColumn> ncrObservationTableColumns({
  required void Function(NcrObservationRow row) onView,
}) {
  return <NcrObservationTableColumn>[
    NcrObservationTableColumn(
      label: 'NCR/Observation ID',
      minWidth: 140,
      read: (NcrObservationRow row) => row.ncrCode,
      buildCell: (BuildContext context, NcrObservationRow row) {
        return _LinkCell(label: row.ncrCode, onTap: () => onView(row));
      },
    ),
    NcrObservationTableColumn(
      label: 'Type',
      minWidth: 110,
      read: (NcrObservationRow row) => formatNcrEnumLabel(row.ncrType),
      buildCell: (BuildContext context, NcrObservationRow row) {
        return _TypeBadge(type: row.ncrType);
      },
    ),
    NcrObservationTableColumn(
      label: 'Date Raised',
      minWidth: 110,
      read: (NcrObservationRow row) => row.raisedDate,
    ),
    NcrObservationTableColumn(
      label: 'Project',
      minWidth: 180,
      read: (NcrObservationRow row) => row.projectLabel,
    ),
    NcrObservationTableColumn(
      label: 'Contract',
      minWidth: 110,
      read: (NcrObservationRow row) => row.contractLabel,
    ),
    NcrObservationTableColumn(
      label: 'Source',
      minWidth: 130,
      read: (NcrObservationRow row) => row.sourceLabel,
    ),
    NcrObservationTableColumn(
      label: 'Reference',
      minWidth: 140,
      read: (NcrObservationRow row) => row.referenceLabel,
    ),
    NcrObservationTableColumn(
      label: 'Severity',
      minWidth: 100,
      read: (NcrObservationRow row) => formatNcrEnumLabel(row.severity),
      buildCell: (BuildContext context, NcrObservationRow row) {
        return _SeverityBadge(severity: row.severity);
      },
    ),
    NcrObservationTableColumn(
      label: 'Status',
      minWidth: 130,
      read: (NcrObservationRow row) => formatNcrEnumLabel(row.status),
      buildCell: (BuildContext context, NcrObservationRow row) {
        return _StatusBadge(status: row.status);
      },
    ),
    NcrObservationTableColumn(
      label: 'Action',
      minWidth: _kActionColumnMinWidth,
      read: (_) => '',
      buildCell: (BuildContext context, NcrObservationRow row) {
        return _Actions(onView: () => onView(row));
      },
    ),
  ];
}

class NcrObservationTable extends StatelessWidget {
  const NcrObservationTable({
    super.key,
    required this.rows,
    required this.onView,
  });

  final List<NcrObservationRow> rows;
  final void Function(NcrObservationRow row) onView;

  @override
  Widget build(BuildContext context) {
    final List<NcrObservationTableColumn> columns = ncrObservationTableColumns(
      onView: onView,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewport = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0;
        final _ColumnLayout layout = _ColumnLayout.fit(columns, viewport);
        return TableScrollFrame(
          width: math.max(layout.total, viewport),
          header: _TableHeaderRow(columns: columns, widths: layout.widths),
          itemCount: rows.length,
          itemBuilder: (BuildContext context, int index) {
            return _DataRow(
              row: rows[index],
              columns: columns,
              widths: layout.widths,
              index: index,
            );
          },
        );
      },
    );
  }
}

class _ColumnLayout {
  const _ColumnLayout({required this.widths, required this.total});

  final List<double> widths;
  final double total;

  factory _ColumnLayout.fit(
    List<NcrObservationTableColumn> columns,
    double viewport,
  ) {
    final double sum = columns.fold<double>(
      0,
      (double total, NcrObservationTableColumn column) =>
          total + column.minWidth,
    );
    if (columns.isEmpty) {
      return const _ColumnLayout(widths: <double>[], total: 0);
    }
    if (!viewport.isFinite || viewport <= 0 || sum >= viewport) {
      return _ColumnLayout(
        widths: columns
            .map((NcrObservationTableColumn column) => column.minWidth)
            .toList(growable: false),
        total: sum,
      );
    }
    final double extra = viewport - sum;
    final double share = extra / columns.length;
    return _ColumnLayout(
      widths: columns
          .map(
            (NcrObservationTableColumn column) => column.minWidth + share,
          )
          .toList(growable: false),
      total: viewport,
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.columns, required this.widths});

  final List<NcrObservationTableColumn> columns;
  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.primary,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Text(
                  columns[i].label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.row,
    required this.columns,
    required this.widths,
    required this.index,
  });

  final NcrObservationRow row;
  final List<NcrObservationTableColumn> columns;
  final List<double> widths;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool stripe = index.isOdd;
    return ColoredBox(
      color: stripe
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.45)
          : scheme.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child:
                    columns[i].buildCell?.call(context, row) ??
                    Text(
                      _display(columns[i].read(row)),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkCell extends StatelessWidget {
  const _LinkCell({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final String key = type.trim().toUpperCase();
    final String label = formatNcrEnumLabel(type);
    if (label.isEmpty) {
      return Text('—', style: Theme.of(context).textTheme.bodySmall);
    }
    final bool isNcr = key == 'NCR';
    final Color foreground = isNcr
        ? const Color(0xFFB91C1C)
        : const Color(0xFF0369A1);
    final Color fill = isNcr
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFE0F2FE);
    return _Pill(
      label: isNcr ? 'NCR' : label,
      foreground: foreground,
      fill: fill,
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    final String label = formatNcrEnumLabel(severity);
    if (label.isEmpty) {
      return Text('—', style: Theme.of(context).textTheme.bodySmall);
    }
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final String key = severity.trim().toUpperCase();
    final Color foreground;
    final Color fill;
    switch (key) {
      case 'CRITICAL':
        foreground = dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
        fill = dark
            ? const Color(0xFFFCA5A5).withValues(alpha: 0.18)
            : const Color(0xFFFEE2E2);
      case 'MAJOR':
        foreground = dark ? const Color(0xFFFB923C) : const Color(0xFFC2410C);
        fill = dark
            ? const Color(0xFFFB923C).withValues(alpha: 0.18)
            : const Color(0xFFFFEDD5);
      case 'MODERATE':
        foreground = dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        fill = dark
            ? const Color(0xFFFBBF24).withValues(alpha: 0.18)
            : const Color(0xFFFEF3C7);
      case 'MINOR':
        foreground = dark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1);
        fill = dark
            ? const Color(0xFF7DD3FC).withValues(alpha: 0.18)
            : const Color(0xFFE0F2FE);
      default:
        foreground = Theme.of(context).colorScheme.onSurfaceVariant;
        fill = Theme.of(context).colorScheme.outlineVariant.withValues(
          alpha: 0.55,
        );
    }
    return _Pill(label: label, foreground: foreground, fill: fill);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final String label = formatNcrEnumLabel(status);
    if (label.isEmpty) {
      return Text('—', style: Theme.of(context).textTheme.bodySmall);
    }
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final String key = status.trim().toUpperCase().replaceAll(' ', '_');
    final Color foreground;
    final Color fill;
    switch (key) {
      case 'CLOSED':
        foreground = palette.success;
        fill = palette.success.withValues(alpha: 0.16);
      case 'OPEN':
        foreground = dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        fill = dark
            ? const Color(0xFFFBBF24).withValues(alpha: 0.18)
            : const Color(0xFFFEF3C7);
      case 'ACTION_SUBMITTED':
        foreground = scheme.primary;
        fill = scheme.primary.withValues(alpha: 0.14);
      case 'RETURNED':
        foreground = dark ? const Color(0xFFFB923C) : const Color(0xFFC2410C);
        fill = dark
            ? const Color(0xFFFB923C).withValues(alpha: 0.18)
            : const Color(0xFFFFEDD5);
      default:
        foreground = scheme.onSurfaceVariant;
        fill = scheme.outlineVariant.withValues(alpha: 0.55);
    }
    return _Pill(label: label, foreground: foreground, fill: fill);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.foreground,
    required this.fill,
  });

  final String label;
  final Color foreground;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onView});

  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = colors.primary;
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox.fromSize(
        size: _kActionButtonSize,
        child: IconButton(
          tooltip: 'View',
          padding: EdgeInsets.zero,
          onPressed: onView,
          style: IconButton.styleFrom(
            foregroundColor: accent,
            backgroundColor: AppPalette.of(context).fieldFill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: accent.withValues(alpha: 0.7)),
            ),
          ),
          icon: const Icon(Icons.visibility_outlined, size: 16),
        ),
      ),
    );
  }
}

String _display(String value) {
  final String text = value.trim();
  return text.isEmpty ? '—' : text;
}
