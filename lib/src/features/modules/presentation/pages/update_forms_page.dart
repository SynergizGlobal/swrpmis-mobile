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
              if (expanded)
                for (final FormMenuNode child in node.children)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: child.isExpandable
                        ? _NestedSection(
                            node: child,
                            expanded: expandedChildIds.contains(
                              '${node.formId}/${child.formId}',
                            ),
                            onToggle: () => onToggleChild(child),
                            onOpen: onOpen,
                          )
                        : _ChildRow(node: child, onTap: () => onOpen(child)),
                  ),
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
            if (expanded)
              for (final FormMenuNode leaf in node.children)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: _ChildRow(node: leaf, onTap: () => onOpen(leaf)),
                ),
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
    return Material(
      color: palette.cardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Row(
            children: <Widget>[
              _IconBadge(icon: _iconForForm(node.formName)),
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

class _ChildRow extends StatelessWidget {
  const _ChildRow({required this.node, required this.onTap});

  final FormMenuNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: AppPalette.of(context).cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: AppTheme.cardPadding,
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
                  node.formName.isEmpty ? node.formId : node.formName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Icon(icon, color: colors.primary),
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
  if (normalized.contains('structure') || normalized.contains('work')) {
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
  return Icons.edit_note_rounded;
}
