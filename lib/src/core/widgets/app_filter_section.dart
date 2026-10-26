import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';

/// Collapsible filter panel for list screens that share dropdown / search rows.
///
/// Default is **collapsed** so the table dominates. Filter [child] stays mounted
/// while collapsed ([Visibility.maintainState]) so parent-owned controllers and
/// Riverpod filter state are preserved.
///
/// Expansion can be uncontrolled ([initiallyExpanded]) or controlled via
/// [expanded] + [onExpandedChanged]. Call [AppFilterSectionState.collapse] /
/// [expand] through a [GlobalKey] when collapsing after Search.
class AppFilterSection extends StatefulWidget {
  const AppFilterSection({
    super.key,
    required this.child,
    this.title = 'Filters',
    this.activeCount = 0,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpandedChanged,
  }) : assert(
         expanded == null || onExpandedChanged != null,
         'Controlled AppFilterSection requires onExpandedChanged',
       );

  final Widget child;
  final String title;

  /// Shown as a compact chip next to [title] when greater than zero.
  final int activeCount;

  /// Used when [expanded] is null (uncontrolled mode).
  final bool initiallyExpanded;

  /// When non-null, expansion is controlled by the parent.
  final bool? expanded;
  final ValueChanged<bool>? onExpandedChanged;

  /// Counts non-empty trimmed string filter values (ignores null / blank).
  static int countActive(Iterable<String?> values) {
    int n = 0;
    for (final String? value in values) {
      if (value != null && value.trim().isNotEmpty) {
        n++;
      }
    }
    return n;
  }

  @override
  State<AppFilterSection> createState() => AppFilterSectionState();
}

class AppFilterSectionState extends State<AppFilterSection> {
  late bool _expanded = widget.initiallyExpanded;

  bool get isExpanded => widget.expanded ?? _expanded;

  void expand() => _setExpanded(true);

  void collapse() => _setExpanded(false);

  void toggle() => _setExpanded(!isExpanded);

  void _setExpanded(bool value) {
    if (widget.expanded != null) {
      if (widget.expanded != value) {
        widget.onExpandedChanged?.call(value);
      }
      return;
    }
    if (_expanded == value) {
      return;
    }
    setState(() => _expanded = value);
    widget.onExpandedChanged?.call(value);
  }

  @override
  void didUpdateWidget(covariant AppFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded == null &&
        oldWidget.initiallyExpanded != widget.initiallyExpanded &&
        oldWidget.expanded != null) {
      _expanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool open = isExpanded;
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(AppTheme.cardRadius);
    final String semanticsLabel = open
        ? 'Collapse ${widget.title}'
        : 'Expand ${widget.title}';

    return Material(
      color: palette.cardSurface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: toggle,
            borderRadius: open
                ? BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius))
                : radius,
            child: Semantics(
              button: true,
              expanded: open,
              label: semanticsLabel,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.filter_list_rounded,
                      size: 20,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    if (widget.activeCount > 0) ...<Widget>[
                      _ActiveCountChip(count: widget.activeCount),
                      const SizedBox(width: 4),
                    ],
                    Icon(
                      open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: palette.mutedText,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Visibility(
            visible: open,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCountChip extends StatelessWidget {
  const _ActiveCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count active',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
