import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/paging/table_page.dart';

class TablePaginationFooter extends StatelessWidget {
  const TablePaginationFooter({
    super.key,
    required this.label,
    required this.total,
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final String label;
  final int total;
  final int page;
  final int pageCount;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int size = TablePage.pageSizes.contains(pageSize)
        ? pageSize
        : TablePage.defaultPageSize;
    final TextStyle control =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ) ??
        TextStyle(color: colors.onSurface, fontWeight: FontWeight.w700);
    final TextStyle status =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: palette.mutedText,
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(color: palette.mutedText, fontWeight: FontWeight.w500);

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.cardSurface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double? width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : null;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _MetaBand(
                    width: width,
                    pageSize: size,
                    control: control,
                    status: status,
                    label: label,
                    onPageSizeChanged: onPageSizeChanged,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: width,
                    height: 1,
                    child: ColoredBox(color: colors.outline),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: width,
                    child: _PageNav(
                      page: page,
                      pageCount: pageCount < 1 ? 1 : pageCount,
                      enabled: total > 0,
                      onPageChanged: onPageChanged,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MetaBand extends StatelessWidget {
  const _MetaBand({
    required this.width,
    required this.pageSize,
    required this.control,
    required this.status,
    required this.label,
    required this.onPageSizeChanged,
  });

  final double? width;
  final int pageSize;
  final TextStyle control;
  final TextStyle status;
  final String label;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final Widget show = _ShowEntries(
      pageSize: pageSize,
      style: control,
      onChanged: onPageSizeChanged,
    );
    final Widget summary = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: status,
    );
    final double maxWidth = width ?? double.infinity;
    final double showWidth =
        _textWidth(context, 'Show', control) +
        8 +
        _textWidth(context, '$pageSize', control) +
        48 +
        8 +
        _textWidth(context, 'entries', control);
    final double summaryWidth = _textWidth(context, label, status);
    const double minGap = 32;
    final bool sideBySide =
        maxWidth.isFinite && showWidth + minGap + summaryWidth <= maxWidth;
    if (!sideBySide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[show, const SizedBox(height: 10), summary],
      );
    }
    return Row(children: <Widget>[show, const Spacer(), summary]);
  }
}

class _ShowEntries extends StatelessWidget {
  const _ShowEntries({
    required this.pageSize,
    required this.style,
    required this.onChanged,
  });

  final int pageSize;
  final TextStyle style;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Show', style: style),
        const SizedBox(width: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: pageSize,
                isDense: true,
                iconSize: 18,
                style: style,
                items: <DropdownMenuItem<int>>[
                  for (final int size in TablePage.pageSizes)
                    DropdownMenuItem<int>(value: size, child: Text('$size')),
                ],
                onChanged: (int? next) {
                  if (next != null && next != pageSize) {
                    onChanged(next);
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('entries', style: style),
      ],
    );
  }
}

class _PageNav extends StatelessWidget {
  const _PageNav({
    required this.page,
    required this.pageCount,
    required this.enabled,
    required this.onPageChanged,
  });

  final int page;
  final int pageCount;
  final bool enabled;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 420;
    final List<int?> tokens = pageNumberWindow(
      current: page,
      pageCount: pageCount,
      compact: compact,
    );
    final bool previous = enabled && page > 1;
    final bool next = enabled && page < pageCount;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _NavButton(
          label: 'Previous',
          icon: Icons.chevron_left_rounded,
          iconFirst: true,
          onPressed: previous ? () => onPageChanged(page - 1) : null,
        ),
        for (final int? token in tokens)
          if (token == null)
            Text(
              '…',
              style: TextStyle(
                color: AppPalette.of(context).mutedText,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            _PageButton(
              page: token,
              selected: token == page,
              onPressed: !enabled || token == page
                  ? null
                  : () => onPageChanged(token),
            ),
        _NavButton(
          label: 'Next',
          icon: Icons.chevron_right_rounded,
          iconFirst: false,
          onPressed: next ? () => onPageChanged(page + 1) : null,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.iconFirst,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool iconFirst;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final Widget glyph = Icon(icon, size: 20);
    final Widget text = Text(label);
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        disabledForegroundColor: accent.withValues(alpha: 0.32),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: iconFirst
            ? <Widget>[glyph, const SizedBox(width: 2), text]
            : <Widget>[text, const SizedBox(width: 2), glyph],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.selected,
    required this.onPressed,
  });

  final int page;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final Color quiet = onPressed == null
        ? palette.mutedText.withValues(alpha: 0.38)
        : palette.mutedText;
    final Widget label = Text(
      '$page',
      style: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: selected ? colors.onPrimary : quiet,
      ),
    );
    if (selected) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: label,
        ),
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: quiet,
        minimumSize: const Size(36, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        side: BorderSide(
          color: colors.outline.withValues(alpha: onPressed == null ? 0.38 : 1),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      child: label,
    );
  }
}

double _textWidth(BuildContext context, String text, TextStyle style) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final double width = painter.width;
  painter.dispose();
  return width;
}
