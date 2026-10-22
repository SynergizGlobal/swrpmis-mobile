import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_list.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/domain/material_receipt_parse.dart';

const double _kActionColumnMinWidth = 112;
const double _kActionCellPadding = 4;
const Size _kActionButtonSize = Size(32, 32);

class MaterialReceiptTableColumn {
  const MaterialReceiptTableColumn({
    required this.label,
    required this.minWidth,
    required this.read,
    this.buildCell,
  });

  final String label;
  final double minWidth;
  final String Function(MaterialReceiptRow row) read;
  final Widget Function(BuildContext context, MaterialReceiptRow row)? buildCell;
}

List<MaterialReceiptTableColumn> materialReceiptTableColumns({
  required void Function(MaterialReceiptRow row) onOpen,
  required void Function(MaterialReceiptRow row) onDownload,
  required void Function(MaterialReceiptRow row) onEdit,
  required String? busyReceiptId,
}) {
  return <MaterialReceiptTableColumn>[
    MaterialReceiptTableColumn(
      label: 'Receipt ID',
      minWidth: 130,
      read: (MaterialReceiptRow row) => row.receiptId,
      buildCell: (BuildContext context, MaterialReceiptRow row) {
        return _LinkCell(label: row.receiptId, onTap: () => onOpen(row));
      },
    ),
    MaterialReceiptTableColumn(
      label: 'Project',
      minWidth: 180,
      read: (MaterialReceiptRow row) => row.projectLabel,
    ),
    MaterialReceiptTableColumn(
      label: 'Section',
      minWidth: 100,
      read: (MaterialReceiptRow row) =>
          row.sectionLabel.isEmpty ? '—' : row.sectionLabel,
    ),
    MaterialReceiptTableColumn(
      label: 'Contract',
      minWidth: 180,
      read: (MaterialReceiptRow row) => row.contractLabel,
    ),
    MaterialReceiptTableColumn(
      label: 'Material',
      minWidth: 120,
      read: (MaterialReceiptRow row) => row.materialName,
      buildCell: (BuildContext context, MaterialReceiptRow row) {
        final String label = row.materialName.trim();
        if (label.isEmpty) {
          return Text(
            '—',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          );
        }
        return _LinkCell(label: label, onTap: () => onOpen(row));
      },
    ),
    MaterialReceiptTableColumn(
      label: 'Batch / Lot No.',
      minWidth: 110,
      read: (MaterialReceiptRow row) => row.batchLotNo,
    ),
    MaterialReceiptTableColumn(
      label: 'Qty Received',
      minWidth: 100,
      read: (MaterialReceiptRow row) => row.quantity,
    ),
    MaterialReceiptTableColumn(
      label: 'Unit',
      minWidth: 60,
      read: (MaterialReceiptRow row) => row.unit,
    ),
    MaterialReceiptTableColumn(
      label: 'Date of Delivery',
      minWidth: 120,
      read: (MaterialReceiptRow row) => row.deliveryDate,
    ),
    MaterialReceiptTableColumn(
      label: 'Invoice No.',
      minWidth: 130,
      read: (MaterialReceiptRow row) => row.invoiceNo,
    ),
    MaterialReceiptTableColumn(
      label: 'Status',
      minWidth: 110,
      read: (MaterialReceiptRow row) => row.status,
      buildCell: (BuildContext context, MaterialReceiptRow row) {
        return _StatusBadge(status: row.status);
      },
    ),
    MaterialReceiptTableColumn(
      label: 'Created On',
      minWidth: 110,
      read: (MaterialReceiptRow row) => row.createdOn,
    ),
    MaterialReceiptTableColumn(
      label: 'Action',
      minWidth: _kActionColumnMinWidth,
      read: (_) => '',
      buildCell: (BuildContext context, MaterialReceiptRow row) {
        final bool busy = busyReceiptId == row.receiptId;
        return _Actions(
          busy: busy,
          onDownload: () => onDownload(row),
          onEdit: () => onEdit(row),
        );
      },
    ),
  ];
}

class MaterialReceiptsTable extends StatelessWidget {
  const MaterialReceiptsTable({
    super.key,
    required this.rows,
    required this.onOpen,
    required this.onDownload,
    required this.onEdit,
    this.busyReceiptId,
  });

  final List<MaterialReceiptRow> rows;
  final void Function(MaterialReceiptRow row) onOpen;
  final void Function(MaterialReceiptRow row) onDownload;
  final void Function(MaterialReceiptRow row) onEdit;
  final String? busyReceiptId;

  @override
  Widget build(BuildContext context) {
    final List<MaterialReceiptTableColumn> columns = materialReceiptTableColumns(
      onOpen: onOpen,
      onDownload: onDownload,
      onEdit: onEdit,
      busyReceiptId: busyReceiptId,
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
    List<MaterialReceiptTableColumn> columns,
    double viewport,
  ) {
    final double sum = columns.fold<double>(
      0,
      (double total, MaterialReceiptTableColumn column) =>
          total + column.minWidth,
    );
    if (columns.isEmpty) {
      return const _ColumnLayout(widths: <double>[], total: 0);
    }
    if (!viewport.isFinite || viewport <= 0 || sum >= viewport) {
      return _ColumnLayout(
        widths: columns
            .map((MaterialReceiptTableColumn column) => column.minWidth)
            .toList(growable: false),
        total: sum,
      );
    }
    final double extra = viewport - sum;
    final double share = extra / columns.length;
    return _ColumnLayout(
      widths: columns
          .map((MaterialReceiptTableColumn column) => column.minWidth + share)
          .toList(growable: false),
      total: viewport,
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.columns, required this.widths});

  final List<MaterialReceiptTableColumn> columns;
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

  final MaterialReceiptRow row;
  final List<MaterialReceiptTableColumn> columns;
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
    final String label = formatMaterialReceiptStatus(status);
    if (label == '-' || label.isEmpty) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );
    }
    final AppPalette palette = AppPalette.of(context);
    final String lower = status.trim().toLowerCase();
    final bool accepted = lower == 'accepted';
    final bool rejected = lower.contains('reject');
    final Color fill = accepted
        ? palette.success.withValues(alpha: 0.16)
        : rejected
        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.14)
        : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55);
    final Color foreground = accepted
        ? palette.success
        : rejected
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
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
  const _Actions({
    required this.busy,
    required this.onDownload,
    required this.onEdit,
  });

  final bool busy;
  final VoidCallback onDownload;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return Align(
      alignment: Alignment.centerLeft,
      child: busy
          ? SizedBox(
              width: _kActionButtonSize.width,
              height: _kActionButtonSize.height,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accent,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _kActionCellPadding,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _ActionButton(
                    tooltip: 'Download PDF',
                    icon: Icons.cloud_download_outlined,
                    onPressed: onDownload,
                  ),
                  const SizedBox(width: 6),
                  _ActionButton(
                    tooltip: 'Edit',
                    icon: Icons.edit_outlined,
                    onPressed: onEdit,
                  ),
                ],
              ),
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return SizedBox.fromSize(
      size: _kActionButtonSize,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: accent,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: accent.withValues(alpha: 0.7)),
          ),
        ),
        icon: Icon(icon, size: 16),
      ),
    );
  }
}

String _display(String value) {
  final String text = value.trim();
  return text.isEmpty ? '—' : text;
}
