import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/entities/rfi_filter_option.dart';

class RfiFilterGrid extends StatelessWidget {
  const RfiFilterGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = 8;
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final int columns = maxWidth >= 840
            ? 4
            : maxWidth >= 560
            ? 3
            : maxWidth < 220
            ? 1
            : 2;
        final double cell = columns <= 1
            ? maxWidth
            : (maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            for (final Widget child in children)
              SizedBox(
                width: cell.isFinite ? cell : maxWidth,
                height: AppTheme.fieldHeight,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class RfiFilterField extends StatelessWidget {
  const RfiFilterField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.selectedId,
    required this.onClear,
    required this.onPick,
    this.emptyLabel = 'Select',
    this.showLabel = true,
  });

  final String label;
  final String? value;
  final String emptyLabel;
  final bool showLabel;
  final List<RfiFilterOption> options;
  final String? selectedId;
  final VoidCallback? onClear;
  final ValueChanged<RfiFilterOption> onPick;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius radius = BorderRadius.circular(AppTheme.cardRadius);
    final bool hasValue = value != null && value!.trim().isNotEmpty;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Material(
      color: dark ? AppTheme.cardDark : AppTheme.surfaceLight,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: () => _pick(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 4, 7),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (showLabel) ...<Widget>[
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.mutedText,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          height: 1.2,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      value ?? emptyLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.2,
                        color: hasValue ? colors.onSurface : palette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Clear $label',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: palette.mutedText,
                  ),
                ),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 22,
                color: palette.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final RfiFilterOption? picked = await showModalBottomSheet<RfiFilterOption>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.6;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: options.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No options'),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(sheetContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      for (final RfiFilterOption option in options)
                        ListTile(
                          title: Text(
                            option.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: option.id == selectedId
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: () => Navigator.pop(sheetContext, option),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
    if (picked != null) {
      onPick(picked);
    }
  }
}
