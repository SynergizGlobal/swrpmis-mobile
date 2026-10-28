import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/projects/domain/project_list.dart';

class ProjectsTableColumn {
  const ProjectsTableColumn({
    required this.label,
    required this.minWidth,
    required this.read,
    this.buildCell,
  });

  final String label;
  final double minWidth;
  final String Function(ProjectRow row) read;
  final Widget Function(BuildContext context, ProjectRow row)? buildCell;
}

List<ProjectsTableColumn> projectsTableColumns({
  required void Function(ProjectRow row) onEdit,
  required void Function(ProjectRow row) onDelete,
}) {
  return <ProjectsTableColumn>[
    const ProjectsTableColumn(label: 'ID', minWidth: 64, read: _id),
    const ProjectsTableColumn(label: 'Name', minWidth: 220, read: _name),
    const ProjectsTableColumn(label: 'Status', minWidth: 80, read: _status),
    const ProjectsTableColumn(label: 'Type', minWidth: 120, read: _type),
    const ProjectsTableColumn(
      label: 'Railway Zone',
      minWidth: 100,
      read: _zone,
    ),
    const ProjectsTableColumn(
      label: 'Plan Head No.',
      minWidth: 110,
      read: _planHead,
    ),
    const ProjectsTableColumn(
      label: 'Sanctioned Amount',
      minWidth: 140,
      read: _amount,
    ),
    const ProjectsTableColumn(
      label: 'Sanctioned Year',
      minWidth: 110,
      read: _year,
    ),
    const ProjectsTableColumn(
      label: 'Sanctioned Date',
      minWidth: 120,
      read: _date,
    ),
    const ProjectsTableColumn(
      label: 'Division',
      minWidth: 100,
      read: _division,
    ),
    const ProjectsTableColumn(label: 'Section', minWidth: 100, read: _section),
    ProjectsTableColumn(
      label: 'Action',
      minWidth: 96,
      read: _blank,
      buildCell: (BuildContext context, ProjectRow row) {
        return _ActionButtons(
          onEdit: () => onEdit(row),
          onDelete: () => onDelete(row),
        );
      },
    ),
  ];
}

String _id(ProjectRow row) => row.projectId;
String _name(ProjectRow row) => row.projectName;
String _status(ProjectRow row) => row.projectStatus;
String _type(ProjectRow row) => row.projectTypeName;
String _zone(ProjectRow row) => row.railwayZone;
String _planHead(ProjectRow row) => row.planHeadNumber;
String _amount(ProjectRow row) => row.sanctionedAmount;
String _year(ProjectRow row) => row.sanctionedYear;
String _date(ProjectRow row) => row.sanctionedCommissioningDate;
String _division(ProjectRow row) => row.divisionName;
String _section(ProjectRow row) => row.sectionName;
String _blank(ProjectRow row) => '';

class ProjectsTable extends StatelessWidget {
  const ProjectsTable({
    super.key,
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ProjectRow> rows;
  final void Function(ProjectRow row) onEdit;
  final void Function(ProjectRow row) onDelete;

  @override
  Widget build(BuildContext context) {
    final List<ProjectsTableColumn> columns = projectsTableColumns(
      onEdit: onEdit,
      onDelete: onDelete,
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
    List<ProjectsTableColumn> columns,
    double viewport,
  ) {
    final double sum = columns.fold<double>(
      0,
      (double total, ProjectsTableColumn column) => total + column.minWidth,
    );
    if (columns.isEmpty) {
      return const _ColumnLayout(widths: <double>[], total: 0);
    }
    if (!viewport.isFinite || viewport <= 0 || sum >= viewport) {
      return _ColumnLayout(
        widths: columns
            .map((ProjectsTableColumn column) => column.minWidth)
            .toList(growable: false),
        total: sum,
      );
    }
    final double extra = (viewport - sum) / columns.length;
    return _ColumnLayout(
      widths: columns
          .map((ProjectsTableColumn column) => column.minWidth + extra)
          .toList(growable: false),
      total: viewport,
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.columns, required this.widths})
    : assert(columns.length == widths.length);

  final List<ProjectsTableColumn> columns;
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
    required this.row,
    required this.columns,
    required this.widths,
    required this.index,
  });

  final ProjectRow row;
  final List<ProjectsTableColumn> columns;
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
    ProjectsTableColumn column,
    bool dark,
    bool emphasize,
  ) {
    if (column.buildCell != null) {
      return column.buildCell!(context, row);
    }
    final String raw = column.read(row).trim();
    final TextStyle style =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: emphasize
              ? (dark ? const Color(0xFF9DC0F0) : AppTheme.brandPrimary)
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
          height: 1.3,
        ) ??
        const TextStyle(fontSize: 12, height: 1.3);
    return Text(raw.isEmpty ? '—' : _softBreak(raw), style: style);
  }
}

String _softBreak(String text) {
  return text.replaceAllMapped(RegExp(r'[_/\-]'), (Match match) {
    return '${match[0]}\u200B';
  });
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _IconAction(
            tooltip: 'Edit',
            icon: Icons.edit_note_rounded,
            color: AppTheme.brandSecondary,
            onPressed: onEdit,
          ),
          const SizedBox(width: 6),
          _IconAction(
            tooltip: 'Delete',
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFC1121F),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
