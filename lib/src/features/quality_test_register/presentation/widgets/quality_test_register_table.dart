import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_actions.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_list.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/domain/quality_test_register_parse.dart';

const double _kActionColumnMinWidth = 72;
const Size _kActionButtonSize = Size(32, 32);

class QualityTestRegisterTableColumn {
  const QualityTestRegisterTableColumn({
    required this.label,
    required this.minWidth,
    required this.read,
    this.buildCell,
  });

  final String label;
  final double minWidth;
  final String Function(QualityTestObligationRow row) read;
  final Widget Function(BuildContext context, QualityTestObligationRow row)?
  buildCell;
}

List<QualityTestRegisterTableColumn> qualityTestRegisterTableColumns({
  required bool isContractor,
  required void Function(
    QualityTestObligationRow row,
    QualityTestRegisterAction action,
  )
  onAction,
}) {
  return <QualityTestRegisterTableColumn>[
    QualityTestRegisterTableColumn(
      label: 'Test Obligation Id',
      minWidth: 130,
      read: (QualityTestObligationRow row) => row.obligationCode,
      buildCell: (BuildContext context, QualityTestObligationRow row) {
        return _LinkCell(
          label: row.obligationCode,
          onTap: () => onAction(row, QualityTestRegisterAction.viewDetails),
        );
      },
    ),
    QualityTestRegisterTableColumn(
      label: 'Project',
      minWidth: 180,
      read: (QualityTestObligationRow row) => row.projectLabel,
    ),
    QualityTestRegisterTableColumn(
      label: 'Section',
      minWidth: 140,
      read: (QualityTestObligationRow row) => row.sectionName,
    ),
    QualityTestRegisterTableColumn(
      label: 'Contract',
      minWidth: 120,
      read: (QualityTestObligationRow row) => row.contractLabel,
    ),
    QualityTestRegisterTableColumn(
      label: 'Material/Work',
      minWidth: 110,
      read: (QualityTestObligationRow row) => row.materialLabel,
    ),
    QualityTestRegisterTableColumn(
      label: 'Test Name',
      minWidth: 130,
      read: (QualityTestObligationRow row) => row.testName,
    ),
    QualityTestRegisterTableColumn(
      label: 'Frequency Basis',
      minWidth: 120,
      read: (QualityTestObligationRow row) => row.frequencyBasis,
    ),
    QualityTestRegisterTableColumn(
      label: 'Generated Form',
      minWidth: 120,
      read: (QualityTestObligationRow row) => row.generatedFrom,
    ),
    QualityTestRegisterTableColumn(
      label: 'Obligation Basis/Coverage',
      minWidth: 160,
      read: (QualityTestObligationRow row) => row.obligationBasisCoverage,
    ),
    QualityTestRegisterTableColumn(
      label: 'Triggers(Source)',
      minWidth: 130,
      read: (QualityTestObligationRow row) => row.batchLotNo,
    ),
    QualityTestRegisterTableColumn(
      label: 'Required By Date',
      minWidth: 110,
      read: (QualityTestObligationRow row) => row.requiredByDate,
    ),
    QualityTestRegisterTableColumn(
      label: 'Contractor Status',
      minWidth: 120,
      read: (QualityTestObligationRow row) => row.contractorStatus,
      buildCell: (BuildContext context, QualityTestObligationRow row) {
        return _StatusBadge(status: row.contractorStatus);
      },
    ),
    QualityTestRegisterTableColumn(
      label: 'Engineer Status',
      minWidth: 120,
      read: (QualityTestObligationRow row) => row.engineerStatus,
      buildCell: (BuildContext context, QualityTestObligationRow row) {
        return _StatusBadge(status: row.engineerStatus);
      },
    ),
    QualityTestRegisterTableColumn(
      label: 'Action',
      minWidth: _kActionColumnMinWidth,
      read: (_) => '',
      buildCell: (BuildContext context, QualityTestObligationRow row) {
        return _Actions(
          isContractor: isContractor,
          row: row,
          onAction: onAction,
        );
      },
    ),
  ];
}

class QualityTestRegisterTable extends StatelessWidget {
  const QualityTestRegisterTable({
    super.key,
    required this.rows,
    required this.isContractor,
    required this.onAction,
  });

  final List<QualityTestObligationRow> rows;
  final bool isContractor;
  final void Function(
    QualityTestObligationRow row,
    QualityTestRegisterAction action,
  )
  onAction;

  @override
  Widget build(BuildContext context) {
    final List<QualityTestRegisterTableColumn> columns =
        qualityTestRegisterTableColumns(
          isContractor: isContractor,
          onAction: onAction,
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
    List<QualityTestRegisterTableColumn> columns,
    double viewport,
  ) {
    final double sum = columns.fold<double>(
      0,
      (double total, QualityTestRegisterTableColumn column) =>
          total + column.minWidth,
    );
    if (columns.isEmpty) {
      return const _ColumnLayout(widths: <double>[], total: 0);
    }
    if (!viewport.isFinite || viewport <= 0 || sum >= viewport) {
      return _ColumnLayout(
        widths: columns
            .map((QualityTestRegisterTableColumn column) => column.minWidth)
            .toList(growable: false),
        total: sum,
      );
    }
    final double extra = viewport - sum;
    final double share = extra / columns.length;
    return _ColumnLayout(
      widths: columns
          .map(
            (QualityTestRegisterTableColumn column) => column.minWidth + share,
          )
          .toList(growable: false),
      total: viewport,
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.columns, required this.widths});

  final List<QualityTestRegisterTableColumn> columns;
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

  final QualityTestObligationRow row;
  final List<QualityTestRegisterTableColumn> columns;
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final String label = formatQualityTestStatus(status);
    if (label.isEmpty) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final bool dark = scheme.brightness == Brightness.dark;
    final String key = status.trim().toUpperCase().replaceAll(' ', '_');
    final Color foreground;
    final Color fill;
    switch (key) {
      case 'SUBMITTED':
        foreground = scheme.primary;
        fill = scheme.primary.withValues(alpha: 0.14);
      case 'PENDING':
        foreground = dark
            ? const Color(0xFFFBBF24)
            : const Color(0xFFB45309);
        fill = dark
            ? const Color(0xFFFBBF24).withValues(alpha: 0.18)
            : const Color(0xFFFFF3CD);
      case 'APPROVED':
        foreground = palette.success;
        fill = palette.success.withValues(alpha: 0.16);
      case 'NCR_RAISED':
        foreground = scheme.error;
        fill = scheme.error.withValues(alpha: 0.14);
      case 'RETURNED':
        foreground = dark
            ? const Color(0xFFFB923C)
            : const Color(0xFFC2410C);
        fill = dark
            ? const Color(0xFFFB923C).withValues(alpha: 0.18)
            : const Color(0xFFFFEDD5);
      default:
        foreground = scheme.onSurfaceVariant;
        fill = scheme.outlineVariant.withValues(alpha: 0.55);
    }
    final Color bg = fill;
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
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
  const _Actions({
    required this.isContractor,
    required this.row,
    required this.onAction,
  });

  final bool isContractor;
  final QualityTestObligationRow row;
  final void Function(
    QualityTestObligationRow row,
    QualityTestRegisterAction action,
  )
  onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = colors.primary;
    final List<QualityTestRegisterAction> items =
        qualityTestRegisterActionsFor(
          contractorStatus: row.contractorStatus,
          isContractor: isContractor,
        );
    final ButtonStyle iconStyle = IconButton.styleFrom(
      foregroundColor: accent,
      backgroundColor: AppPalette.of(context).fieldFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: accent.withValues(alpha: 0.7)),
      ),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox.fromSize(
        size: _kActionButtonSize,
        child: PopupMenuButton<QualityTestRegisterAction>(
          tooltip: 'More Actions',
          padding: EdgeInsets.zero,
          style: iconStyle,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          onSelected: (QualityTestRegisterAction action) {
            onAction(row, action);
          },
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<QualityTestRegisterAction>>[
              for (final QualityTestRegisterAction action in items)
                PopupMenuItem<QualityTestRegisterAction>(
                  value: action,
                  child: Text(qualityTestRegisterActionLabel(action)),
                ),
            ];
          },
        ),
      ),
    );
  }
}

String _display(String value) {
  final String text = value.trim();
  return text.isEmpty ? '—' : text;
}
