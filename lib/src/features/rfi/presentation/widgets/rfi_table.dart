import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_list_item.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_list_kind.dart';

class RfiTableColumn {
  const RfiTableColumn({
    required this.label,
    required this.minWidth,
    required this.read,
    this.status = false,
    this.buildCell,
  });

  final String label;
  final double minWidth;
  final String Function(RfiListItem item) read;
  final bool status;
  final Widget Function(BuildContext context, RfiListItem item)? buildCell;
}

List<RfiTableColumn> rfiTableColumns(
  RfiListKind kind, {
  void Function(RfiListItem item)? onEdit,
  void Function(RfiListItem item)? onDelete,
}) {
  const RfiTableColumn rfiId = RfiTableColumn(
    label: 'RFI ID',
    minWidth: 196,
    read: _rfiId,
  );
  const RfiTableColumn project = RfiTableColumn(
    label: 'Project',
    minWidth: 180,
    read: _project,
  );
  const RfiTableColumn raised = RfiTableColumn(
    label: 'Raised date',
    minWidth: 124,
    read: _raised,
  );
  const RfiTableColumn scheduled = RfiTableColumn(
    label: 'Scheduled on',
    minWidth: 156,
    read: _scheduled,
  );
  const RfiTableColumn status = RfiTableColumn(
    label: 'Status',
    minWidth: 156,
    read: _status,
    status: true,
  );
  return switch (kind) {
    RfiListKind.material => <RfiTableColumn>[
      rfiId,
      project,
      const RfiTableColumn(label: 'Item', minWidth: 120, read: _item),
      const RfiTableColumn(label: 'Material', minWidth: 140, read: _material),
      const RfiTableColumn(label: 'Batch/Lot No.', minWidth: 130, read: _batch),
      const RfiTableColumn(label: 'Location', minWidth: 140, read: _location),
      const RfiTableColumn(
        label: 'Assigned contractor',
        minWidth: 168,
        read: _contractor,
      ),
      raised,
      scheduled,
      const RfiTableColumn(
        label: 'Contractor submitted on',
        minWidth: 176,
        read: _submitted,
      ),
      status,
    ],
    RfiListKind.work => <RfiTableColumn>[
      rfiId,
      project,
      const RfiTableColumn(label: 'Structure', minWidth: 150, read: _structure),
      const RfiTableColumn(label: 'Element', minWidth: 140, read: _element),
      const RfiTableColumn(
        label: 'Assigned contractor',
        minWidth: 168,
        read: _contractor,
      ),
      const RfiTableColumn(
        label: "Assigned employer's engineer",
        minWidth: 200,
        read: _engineer,
      ),
      raised,
      scheduled,
      const RfiTableColumn(
        label: 'Contractor submitted on',
        minWidth: 176,
        read: _submitted,
      ),
      status,
      RfiTableColumn(
        label: 'Actions',
        minWidth: 176,
        read: _blank,
        buildCell: (BuildContext context, RfiListItem item) {
          return _WorkRowActions(
            onEdit: onEdit == null ? null : () => onEdit(item),
            onDelete: onDelete == null ? null : () => onDelete(item),
          );
        },
      ),
    ],
    RfiListKind.quality => <RfiTableColumn>[
      rfiId,
      const RfiTableColumn(label: 'Category', minWidth: 120, read: _category),
      project,
      const RfiTableColumn(
        label: 'Structure type',
        minWidth: 160,
        read: _structureType,
      ),
      raised,
      scheduled,
      status,
    ],
  };
}

String _rfiId(RfiListItem item) => item.rfiId;

String _project(RfiListItem item) => item.projectName;

String _item(RfiListItem item) => item.item;

String _material(RfiListItem item) => item.material;

String _batch(RfiListItem item) => item.batchLotNo;

String _location(RfiListItem item) => item.location;

String _contractor(RfiListItem item) => item.nameOfRepresentative;

String _raised(RfiListItem item) => item.dateOfSubmission;

String _scheduled(RfiListItem item) => item.scheduledText;

String _submitted(RfiListItem item) => item.contractorSubmittedOn;

String _status(RfiListItem item) => item.statusLabel;

String _blank(RfiListItem item) => '';

String _structure(RfiListItem item) => item.structure;

String _element(RfiListItem item) => item.element;

String _engineer(RfiListItem item) => item.assignedPersonClient;

String _category(RfiListItem item) => item.rfiCategory;

String _structureType(RfiListItem item) => item.structureType;

class RfiTable extends StatelessWidget {
  const RfiTable({super.key, required this.columns, required this.items});

  final List<RfiTableColumn> columns;
  final List<RfiListItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewport = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0;
        final _ColumnLayout layout = _ColumnLayout.fit(columns, viewport);
        return TableScrollFrame(
          width: math.max(layout.total, viewport),
          header: _TableHeaderRow(columns: columns, widths: layout.widths),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return _DataRow(
              item: items[index],
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

  factory _ColumnLayout.fit(List<RfiTableColumn> columns, double viewport) {
    final double sum = columns.fold<double>(
      0,
      (double total, RfiTableColumn column) => total + column.minWidth,
    );
    if (columns.isEmpty) {
      return const _ColumnLayout(widths: <double>[], total: 0);
    }
    if (!viewport.isFinite || viewport <= 0 || sum >= viewport) {
      return _ColumnLayout(
        widths: columns
            .map((RfiTableColumn column) => column.minWidth)
            .toList(growable: false),
        total: sum,
      );
    }
    final double extra = (viewport - sum) / columns.length;
    return _ColumnLayout(
      widths: columns
          .map((RfiTableColumn column) => column.minWidth + extra)
          .toList(growable: false),
      total: viewport,
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.columns, required this.widths})
    : assert(columns.length == widths.length);

  final List<RfiTableColumn> columns;
  final List<double> widths;

  static const double _height = 52;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.brandPrimary,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              height: _height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    columns[i].label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
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
    required this.item,
    required this.columns,
    required this.widths,
    required this.index,
  });

  final RfiListItem item;
  final List<RfiTableColumn> columns;
  final List<double> widths;
  final int index;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color background = index.isEven
        ? (dark ? const Color(0xFF122844) : AppTheme.surfaceLight)
        : (dark ? const Color(0xFF0E1F36) : AppTheme.scaffoldLight);
    final Color line = AppPalette.of(context).borderSubtle;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: _cell(context, columns[i], dark, i == 0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    RfiTableColumn column,
    bool dark,
    bool isId,
  ) {
    if (column.buildCell != null) {
      return column.buildCell!(context, item);
    }
    final String raw = column.read(item).trim();
    final TextStyle style =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isId
              ? (dark ? const Color(0xFF9DC0F0) : AppTheme.brandPrimary)
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: isId ? FontWeight.w800 : FontWeight.w600,
          height: 1.3,
        ) ??
        const TextStyle(fontSize: 12, height: 1.3);
    if (column.status) {
      if (raw.isEmpty) {
        return Text('—', style: style);
      }
      return Align(
        alignment: Alignment.centerLeft,
        child: _StatusChip(code: item.rfiStatus, label: raw),
      );
    }
    return Text(raw.isEmpty ? '—' : _softBreak(raw), style: style);
  }
}

String _softBreak(String text) {
  return text.replaceAllMapped(RegExp(r'[_/\-]'), (Match match) {
    return '${match[0]}\u200B';
  });
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color foreground = _statusColor(code, dark);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: dark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

Color _statusColor(String code, bool dark) {
  final String normalized = code.toUpperCase();
  if (normalized.contains('REJECT') || normalized.contains('DECLIN')) {
    return dark ? const Color(0xFFFF8A93) : AppTheme.railwayRed;
  }
  if (normalized.contains('APPROV') ||
      normalized.contains('ACCEPT') ||
      normalized.contains('CLOSE')) {
    return dark ? const Color(0xFF34D399) : const Color(0xFF198754);
  }
  if (normalized.contains('ONGOING') ||
      normalized.contains('PEND') ||
      normalized.contains('INSP') ||
      normalized.contains('SUBMIT')) {
    return dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
  }
  return dark ? const Color(0xFF9DC0F0) : AppTheme.brandSecondary;
}

class _WorkRowActions extends StatelessWidget {
  const _WorkRowActions({required this.onEdit, required this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color editColor = dark
        ? const Color(0xFFF0C36A)
        : const Color(0xFF8A5A00);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        OutlinedButton(
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 32)),
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 10),
            ),
            foregroundColor: WidgetStatePropertyAll<Color>(editColor),
            side: WidgetStatePropertyAll<BorderSide>(
              BorderSide(color: editColor),
            ),
            textStyle: const WidgetStatePropertyAll<TextStyle>(
              TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          onPressed: onEdit,
          child: const Text('Edit'),
        ),
        FilledButton(
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: const WidgetStatePropertyAll<Size>(Size(72, 32)),
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 10),
            ),
            backgroundColor: const WidgetStatePropertyAll<Color>(
              AppTheme.railwayRed,
            ),
            foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
            textStyle: const WidgetStatePropertyAll<TextStyle>(
              TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          onPressed: onDelete,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
