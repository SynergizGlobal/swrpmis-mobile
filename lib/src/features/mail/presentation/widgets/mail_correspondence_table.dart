import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_table_frame.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_dashboard.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/widgets/mail_ui_helpers.dart';

const Size _kActionButtonSize = Size(72, 32);

class MailCorrespondenceTableColumn {
  const MailCorrespondenceTableColumn({
    required this.label,
    required this.minWidth,
    required this.read,
    this.buildCell,
  });

  final String label;
  final double minWidth;
  final String Function(MailCorrespondenceRow row, int serial) read;
  final Widget Function(
    BuildContext context,
    MailCorrespondenceRow row,
    int serial,
  )?
  buildCell;
}

List<MailCorrespondenceTableColumn> mailCorrespondenceTableColumns({
  required void Function(MailCorrespondenceRow row) onView,
}) {
  return <MailCorrespondenceTableColumn>[
    MailCorrespondenceTableColumn(
      label: 'S. No.',
      minWidth: 56,
      read: (_, int serial) => '$serial',
    ),
    const MailCorrespondenceTableColumn(
      label: 'Contract Short Name',
      minWidth: 140,
      read: _contract,
    ),
    const MailCorrespondenceTableColumn(
      label: 'Contractor Name',
      minWidth: 160,
      read: _contractor,
    ),
    MailCorrespondenceTableColumn(
      label: 'Mail No. / Ref. Correspondence No.',
      minWidth: 220,
      read: _mailNo,
      buildCell: (BuildContext context, MailCorrespondenceRow row, int _) {
        return _MailNoCell(row: row);
      },
    ),
    MailCorrespondenceTableColumn(
      label: 'Date',
      minWidth: 100,
      read: (MailCorrespondenceRow row, _) => formatMailDashDate(row.date),
    ),
    const MailCorrespondenceTableColumn(
      label: 'Reply Reqd. (Y/N)',
      minWidth: 110,
      read: _replyRequired,
    ),
    MailCorrespondenceTableColumn(
      label: 'Due Date',
      minWidth: 100,
      read: (MailCorrespondenceRow row, _) => formatMailDashDate(row.dueDate),
      buildCell: (BuildContext context, MailCorrespondenceRow row, int _) {
        return _DueDateCell(row: row);
      },
    ),
    const MailCorrespondenceTableColumn(
      label: 'Person to Reply (Name, Designation)',
      minWidth: 180,
      read: _person,
    ),
    MailCorrespondenceTableColumn(
      label: 'Replied (Y/N)',
      minWidth: 100,
      read: _replied,
      buildCell: (BuildContext context, MailCorrespondenceRow row, int _) {
        return _RepliedCell(value: row.replied);
      },
    ),
    const MailCorrespondenceTableColumn(
      label: 'Reply Mail No. / Ref. Correspondence No.',
      minWidth: 200,
      read: _replyMailNo,
    ),
    MailCorrespondenceTableColumn(
      label: 'Reply Date',
      minWidth: 100,
      read: (MailCorrespondenceRow row, _) => formatMailDashDate(row.replyDate),
    ),
    MailCorrespondenceTableColumn(
      label: 'View Details',
      minWidth: 96,
      read: (_, _) => '',
      buildCell: (BuildContext context, MailCorrespondenceRow row, int _) {
        return _ViewButton(onPressed: () => onView(row));
      },
    ),
  ];
}

String _contract(MailCorrespondenceRow row, int _) => _display(row.contract);

String _contractor(MailCorrespondenceRow row, int _) =>
    _display(row.contractor);

String _mailNo(MailCorrespondenceRow row, int _) {
  final String mail = row.mailNo.trim();
  return mail.isEmpty ? _display(row.reference) : mail;
}

String _replyRequired(MailCorrespondenceRow row, int _) =>
    _display(row.replyRequired);

String _person(MailCorrespondenceRow row, int _) => _display(row.person);

String _replied(MailCorrespondenceRow row, int _) => _display(row.replied);

String _replyMailNo(MailCorrespondenceRow row, int _) =>
    _display(row.replyMailNo);

String formatMailDashDate(String raw) {
  final String text = raw.trim();
  if (text.isEmpty || text == '—') {
    return '—';
  }
  final DateTime? parsed = DateTime.tryParse(text);
  if (parsed == null) {
    return text;
  }
  return DateFormat('dd MMM yyyy').format(parsed);
}

String _display(String value) {
  final String text = value.trim();
  return text.isEmpty || text == '—' ? '—' : text;
}

bool mailDueDateIsOverdue(MailCorrespondenceRow row) {
  final String replied = row.replied.trim().toLowerCase();
  if (replied == 'yes' || replied == 'y') {
    return false;
  }
  final String raw = row.dueDate.trim();
  if (raw.isEmpty || raw == '—') {
    return false;
  }
  final DateTime? due = DateTime.tryParse(raw);
  if (due == null) {
    return false;
  }
  final DateTime today = DateTime.now();
  final DateTime dueDay = DateTime(due.year, due.month, due.day);
  final DateTime todayDay = DateTime(today.year, today.month, today.day);
  return dueDay.isBefore(todayDay);
}

class MailCorrespondenceTable extends StatelessWidget {
  const MailCorrespondenceTable({
    super.key,
    required this.rows,
    required this.startSerial,
    required this.onView,
    this.shrinkWrap = false,
  });

  final List<MailCorrespondenceRow> rows;
  final int startSerial;
  final void Function(MailCorrespondenceRow row) onView;

  /// When true, sizes to row content (no nested vertical scroll) so a parent
  /// [ScrollView] can scroll KPIs + table together.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final List<MailCorrespondenceTableColumn> columns =
        mailCorrespondenceTableColumns(onView: onView);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewport = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final _ColumnLayout layout = _ColumnLayout.fit(columns, viewport);
        final double width = math.max(layout.total, viewport);
        final Widget header = _TableHeaderRow(
          columns: columns,
          widths: layout.widths,
        );
        if (shrinkWrap) {
          return AppTableFrame(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              primary: false,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    for (int index = 0; index < rows.length; index++)
                      _DataRow(
                        row: rows[index],
                        columns: columns,
                        widths: layout.widths,
                        index: index,
                        serial: startSerial + index,
                      ),
                  ],
                ),
              ),
            ),
          );
        }
        return TableScrollFrame(
          width: width,
          header: header,
          itemCount: rows.length,
          itemBuilder: (BuildContext context, int index) {
            final int serial = startSerial + index;
            return _DataRow(
              row: rows[index],
              columns: columns,
              widths: layout.widths,
              index: index,
              serial: serial,
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
    List<MailCorrespondenceTableColumn> columns,
    double viewport,
  ) {
    final double sum = columns.fold<double>(
      0,
      (double total, MailCorrespondenceTableColumn column) =>
          total + column.minWidth,
    );
    if (columns.isEmpty) {
      return const _ColumnLayout(widths: <double>[], total: 0);
    }
    if (!viewport.isFinite || viewport <= 0 || sum >= viewport) {
      return _ColumnLayout(
        widths: columns
            .map((MailCorrespondenceTableColumn column) => column.minWidth)
            .toList(growable: false),
        total: sum,
      );
    }
    final double extra = (viewport - sum) / columns.length;
    return _ColumnLayout(
      widths: columns
          .map(
            (MailCorrespondenceTableColumn column) => column.minWidth + extra,
          )
          .toList(growable: false),
      total: viewport,
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.columns, required this.widths})
    : assert(columns.length == widths.length);

  final List<MailCorrespondenceTableColumn> columns;
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
    required this.serial,
  });

  final MailCorrespondenceRow row;
  final List<MailCorrespondenceTableColumn> columns;
  final List<double> widths;
  final int index;
  final int serial;

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
                  horizontal: 10,
                  vertical: 10,
                ),
                child: columns[i].buildCell?.call(context, row, serial) ??
                    Text(
                      columns[i].read(row, serial),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MailNoCell extends StatelessWidget {
  const _MailNoCell({required this.row});

  final MailCorrespondenceRow row;

  @override
  Widget build(BuildContext context) {
    final String mail = row.mailNo.trim().isEmpty
        ? (row.reference.trim().isEmpty ? '—' : row.reference.trim())
        : row.mailNo.trim();
    final String ref = row.reference.trim().isEmpty
        ? '—'
        : row.reference.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          mail,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: MailTheme.pillForeground(context),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Ref: $ref',
          style: MailTheme.mutedStyle(context, fontSize: 11),
        ),
      ],
    );
  }
}

class _DueDateCell extends StatelessWidget {
  const _DueDateCell({required this.row});

  final MailCorrespondenceRow row;

  @override
  Widget build(BuildContext context) {
    final bool overdue = mailDueDateIsOverdue(row);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Text(
      formatMailDashDate(row.dueDate),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: overdue ? scheme.error : null,
        height: 1.3,
      ),
    );
  }
}

class _RepliedCell extends StatelessWidget {
  const _RepliedCell({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final String text = _display(value);
    final String lower = text.toLowerCase();
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    Color? color;
    if (lower == 'yes' || lower == 'y') {
      color = palette.success;
    } else if (lower == 'no' || lower == 'n') {
      color = scheme.error;
    }
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.3,
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox.fromSize(
        size: _kActionButtonSize,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: accent.withValues(alpha: 0.7)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          icon: const Icon(Icons.visibility_outlined, size: 14),
          label: const Text('View', style: TextStyle(fontSize: 11)),
        ),
      ),
    );
  }
}
