import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/widgets/paged_table_column.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_parse.dart';

/// Three action icons at [_kFileTableActionButtonSize] plus horizontal padding.
const double _kFileTableActionColumnMinWidth = 112;
const double _kFileTableActionCellPadding = 4;
const Size _kFileTableActionButtonSize = Size(32, 32);

class RdsoDrawingFilesTable extends StatelessWidget {
  const RdsoDrawingFilesTable({
    super.key,
    required this.files,
    required this.busyFileId,
    required this.onView,
    required this.onDownload,
    required this.onMail,
  });

  final List<RdsoDrawingFile> files;
  final String? busyFileId;
  final void Function(RdsoDrawingFile file) onView;
  final void Function(RdsoDrawingFile file) onDownload;
  final void Function(RdsoDrawingFile file) onMail;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No files available.'),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewport = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 640;
        const List<_Col> columns = <_Col>[
          _Col('Name', 160),
          _Col('Type', 100),
          _Col('Size', 90),
          _Col('Status', 100),
          _Col('Actions', _kFileTableActionColumnMinWidth),
        ];
        final double total = columns.fold<double>(
          0,
          (double sum, _Col c) => sum + c.minWidth,
        );
        final double width = math.max(total, viewport);
        return TableScrollFrame(
          width: width,
          header: _HeaderRow(columns: columns, width: width),
          itemCount: files.length,
          itemBuilder: (BuildContext context, int index) {
            final RdsoDrawingFile file = files[index];
            final bool busy = busyFileId == file.id;
            return _FileRow(
              file: file,
              columns: columns,
              width: width,
              index: index,
              busy: busy,
              onView: () => onView(file),
              onDownload: () => onDownload(file),
              onMail: () => onMail(file),
            );
          },
          bottomPadding: 0,
        );
      },
    );
  }
}

class _Col {
  const _Col(this.label, this.minWidth);

  final String label;
  final double minWidth;
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.columns, required this.width});

  final List<_Col> columns;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.brandPrimary,
      child: SizedBox(
        width: width,
        height: 48,
        child: Row(
          children: columns
              .map(
                (_Col col) => SizedBox(
                  width: col.minWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        col.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.file,
    required this.columns,
    required this.width,
    required this.index,
    required this.busy,
    required this.onView,
    required this.onDownload,
    required this.onMail,
  });

  final RdsoDrawingFile file;
  final List<_Col> columns;
  final double width;
  final int index;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onMail;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color background = index.isEven
        ? (dark ? const Color(0xFF122844) : AppTheme.surfaceLight)
        : (dark ? const Color(0xFF0E1F36) : AppTheme.scaffoldLight);
    final TextStyle cellStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.3,
        ) ??
        const TextStyle(fontSize: 12);

    Widget cell(String text) {
      final String raw = text.trim();
      return Text(raw.isEmpty ? '—' : raw, style: cellStyle);
    }

    return ColoredBox(
      color: background,
      child: SizedBox(
        width: width,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: columns[0].minWidth, child: Padding(padding: const EdgeInsets.all(12), child: cell(file.name))),
            SizedBox(width: columns[1].minWidth, child: Padding(padding: const EdgeInsets.all(12), child: cell(file.type))),
            SizedBox(width: columns[2].minWidth, child: Padding(padding: const EdgeInsets.all(12), child: cell(formatRdsoFileSize(file.size)))),
            SizedBox(width: columns[3].minWidth, child: Padding(padding: const EdgeInsets.all(12), child: cell(file.status))),
            SizedBox(
              width: columns[4].minWidth,
              child: _FileActionsCell(
                busy: busy,
                enabled: file.hasFile,
                onView: onView,
                onDownload: onDownload,
                onMail: onMail,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileActionsCell extends StatelessWidget {
  const _FileActionsCell({
    required this.busy,
    required this.enabled,
    required this.onView,
    required this.onDownload,
    required this.onMail,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onMail;

  static const Size _kLoaderSize = Size(20, 20);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _kFileTableActionCellPadding,
        vertical: _kFileTableActionCellPadding,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: busy
            ? SizedBox(
                width: _kLoaderSize.width,
                height: _kLoaderSize.height,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _FileTableIconAction(
                    tooltip: 'View',
                    icon: Icons.visibility_rounded,
                    onPressed: enabled ? onView : null,
                  ),
                  _FileTableIconAction(
                    tooltip: 'Download',
                    icon: Icons.download_rounded,
                    onPressed: enabled ? onDownload : null,
                  ),
                  _FileTableIconAction(
                    tooltip: 'Send via mail',
                    icon: Icons.mail_outline_rounded,
                    onPressed: enabled ? onMail : null,
                  ),
                ],
              ),
      ),
    );
  }
}

class _FileTableIconAction extends StatelessWidget {
  const _FileTableIconAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        fixedSize: _kFileTableActionButtonSize,
        minimumSize: _kFileTableActionButtonSize,
        maximumSize: _kFileTableActionButtonSize,
      ),
      constraints: BoxConstraints.tightFor(
        width: _kFileTableActionButtonSize.width,
        height: _kFileTableActionButtonSize.height,
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
