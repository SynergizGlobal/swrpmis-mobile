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
    final TextStyle meta =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: palette.mutedText,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(color: palette.mutedText, fontWeight: FontWeight.w600);

    final Widget show = _ShowEntries(
      pageSize: size,
      style: meta,
      onChanged: onPageSizeChanged,
    );
    final Widget summary = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: meta,
    );

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.cardSurface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: <Widget>[show, summary],
              ),
              const SizedBox(height: 8),
              _PageNav(
                page: page,
                pageCount: pageCount < 1 ? 1 : pageCount,
                enabled: total > 0,
                onPageChanged: onPageChanged,
              ),
            ],
          ),
        ),
      ),
    );
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Show', style: style),
        const SizedBox(width: 6),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: pageSize,
            isDense: true,
            style: style.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
        const SizedBox(width: 4),
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
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _NavButton(
          label: 'Previous',
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
          onPressed: next ? () => onPageChanged(page + 1) : null,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return OutlinedButton(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const WidgetStatePropertyAll<Size>(Size(72, 36)),
        padding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 8),
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return accent.withValues(alpha: 0.38);
          }
          return accent;
        }),
        side: WidgetStateProperty.resolveWith<BorderSide>((
          Set<WidgetState> states,
        ) {
          final Color color = states.contains(WidgetState.disabled)
              ? accent.withValues(alpha: 0.28)
              : accent;
          return BorderSide(color: color);
        }),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
        ),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: 32,
        height: 32,
        child: selected
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: Center(
                  child: Text(
                    '$page',
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  '$page',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}
