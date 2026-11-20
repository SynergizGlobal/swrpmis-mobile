import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/forms/form_menu_tree.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/widgets/rfi_content_loader.dart';
import 'package:swr_pmis_mobile/src/features/update_forms/domain/entities/update_forms_tree.dart';
import 'package:swr_pmis_mobile/src/features/update_forms/domain/update_form_destination.dart';
import 'package:swr_pmis_mobile/src/features/update_forms/presentation/providers/update_forms_providers.dart';

class UpdateFormsPage extends ConsumerStatefulWidget {
  const UpdateFormsPage({super.key});

  static const String routeName = 'update-forms';
  static const String routePath = '/update-forms';

  @override
  ConsumerState<UpdateFormsPage> createState() => _UpdateFormsPageState();
}

class _UpdateFormsPageState extends ConsumerState<UpdateFormsPage> {
  String? _expandedId;
  final Set<String> _expandedChildIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final AsyncValue<UpdateFormsTree> tree = ref.watch(updateFormsTreeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RfiContentLoader(loading: tree.isLoading),
        Expanded(child: _body(tree)),
      ],
    );
  }

  Widget _body(AsyncValue<UpdateFormsTree> tree) {
    return tree.when(
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stackTrace) {
        return _StatusMessage(
          message: error is DioException
              ? userFriendlyErrorMessage(error)
              : error.toString(),
          onRetry: () => ref.invalidate(updateFormsTreeProvider),
        );
      },
      data: (UpdateFormsTree data) {
        if (data.isEmpty) {
          return const _StatusMessage(message: 'No update forms found.');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          itemCount: data.forms.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            final FormMenuNode node = data.forms[index];
            if (!node.isExpandable) {
              return _LeafCard(node: node, onTap: () => _open(node));
            }
            return _SectionCard(
              node: node,
              expanded: _expandedId == node.formId,
              expandedChildIds: _expandedChildIds,
              onToggle: () {
                setState(() {
                  _expandedId = _expandedId == node.formId ? null : node.formId;
                });
              },
              onToggleChild: (FormMenuNode child) {
                final String key = '${node.formId}/${child.formId}';
                setState(() {
                  if (!_expandedChildIds.add(key)) {
                    _expandedChildIds.remove(key);
                  }
                });
              },
              onOpen: _open,
            );
          },
        );
      },
    );
  }

  Future<void> _open(FormMenuNode node) async {
    final String? routeName = updateFormRouteName(node);
    if (routeName == null) {
      return;
    }
    context.pushNamed(routeName);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.node,
    required this.expanded,
    required this.expandedChildIds,
    required this.onToggle,
    required this.onToggleChild,
    required this.onOpen,
  });

  final FormMenuNode node;
  final bool expanded;
  final Set<String> expandedChildIds;
  final VoidCallback onToggle;
  final ValueChanged<FormMenuNode> onToggleChild;
  final ValueChanged<FormMenuNode> onOpen;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: palette.cardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: <Widget>[
                      _IconBadge(icon: _iconForForm(node.formName)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          node.formName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                        ),
                      ),
                      Text(
                        '${node.children.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: palette.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: palette.mutedText,
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded) ...<Widget>[
                const SizedBox(height: 6),
                _ChildrenPanel(
                  children: <Widget>[
                    for (int i = 0; i < node.children.length; i++) ...<Widget>[
                      if (i > 0) const _ChildDivider(),
                      Builder(
                        builder: (BuildContext context) {
                          final FormMenuNode child = node.children[i];
                          if (child.isExpandable) {
                            return _NestedSection(
                              node: child,
                              expanded: expandedChildIds.contains(
                                '${node.formId}/${child.formId}',
                              ),
                              onToggle: () => onToggleChild(child),
                              onOpen: onOpen,
                            );
                          }
                          return _ChildRow(
                            node: child,
                            index: i,
                            onTap: () => onOpen(child),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NestedSection extends StatelessWidget {
  const _NestedSection({
    required this.node,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
  });

  final FormMenuNode node;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<FormMenuNode> onOpen;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: palette.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    Icon(
                      _iconForForm(node.formName),
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        node.formName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: palette.mutedText,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...<Widget>[
              const SizedBox(height: 6),
              _ChildrenPanel(
                children: <Widget>[
                  for (int i = 0; i < node.children.length; i++) ...<Widget>[
                    if (i > 0) const _ChildDivider(),
                    _ChildRow(
                      node: node.children[i],
                      index: i,
                      onTap: () => onOpen(node.children[i]),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeafCard extends StatelessWidget {
  const _LeafCard({required this.node, required this.onTap});

  final FormMenuNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = _accentFor(node.formName, colors);
    return Material(
      color: palette.cardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: accent.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Row(
            children: <Widget>[
              _IconBadge(icon: _iconForForm(node.formName), accent: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  node.formName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildrenPanel extends StatelessWidget {
  const _ChildrenPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _ChildDivider extends StatelessWidget {
  const _ChildDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 44,
      endIndent: 8,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({
    required this.node,
    required this.index,
    required this.onTap,
  });

  final FormMenuNode node;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = _accentFor(node.formName, colors, index: index);
    final String label = node.formName.isEmpty ? node.formId : node.formName;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 6, 10),
          child: Row(
            children: <Widget>[
              _IconBadge(
                icon: _iconForForm(label),
                accent: accent,
                size: 34,
                iconSize: 18,
                radius: 10,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accent.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    this.accent,
    this.size = 40,
    this.iconSize = 22,
    this.radius,
  });

  final IconData icon;
  final Color? accent;
  final double size;
  final double iconSize;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final Color tone = accent ?? Theme.of(context).colorScheme.primary;
    final double r = radius ?? AppTheme.cardRadius;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: tone, size: iconSize),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurface),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

IconData _iconForForm(String name) {
  final String normalized = name.toLowerCase();
  if (normalized.contains('project')) {
    return Icons.groups_rounded;
  }
  if (normalized.contains('structure')) {
    return Icons.domain_rounded;
  }
  if (normalized.contains('work')) {
    return Icons.construction_rounded;
  }
  if (normalized.contains('contract')) {
    return Icons.draw_rounded;
  }
  if (normalized.contains('execution') ||
      normalized.contains('activit') ||
      normalized.contains('linear') ||
      normalized.contains('p6')) {
    return Icons.stairs_rounded;
  }
  if (normalized.contains('design') || normalized.contains('drawing')) {
    return Icons.architecture_rounded;
  }
  if (normalized.contains('issue')) {
    return Icons.warning_amber_rounded;
  }
  if (normalized.contains('land')) {
    return Icons.handshake_rounded;
  }
  if (normalized.contains('util')) {
    return Icons.electrical_services_rounded;
  }
  if (normalized.contains('quality') || normalized.contains('material')) {
    return Icons.inventory_2_outlined;
  }
  return Icons.edit_note_rounded;
}

Color _accentFor(String name, ColorScheme colors, {int index = 0}) {
  const List<double> hues = <double>[210, 160, 28, 280, 190, 340];
  final int seed = name.trim().isEmpty
      ? index
      : name.toLowerCase().codeUnits.fold<int>(0, (int a, int b) => a + b);
  final double hue = hues[(seed + index) % hues.length];
  return HSLColor.fromAHSL(
    1,
    hue,
    colors.brightness == Brightness.dark ? 0.42 : 0.48,
    colors.brightness == Brightness.dark ? 0.72 : 0.42,
  ).toColor();
}
