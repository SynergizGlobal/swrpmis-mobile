import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/features/reports/domain/entities/reports_tree.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/report_placeholder_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/providers/reports_providers.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  static const String routeName = 'reports';
  static const String routePath = '/reports';

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String? _expandedId;
  final Set<String> _expandedChildIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ReportsTree> tree = ref.watch(reportsTreeProvider);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(reportsTreeProvider);
            await ref.read(reportsTreeProvider.future);
          },
          child: tree.when(
            loading: () => const _FillScroll(
              minHeight: 240,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object error, StackTrace stackTrace) {
              return _FillScroll(
                minHeight: minHeight,
                child: _StatusMessage(
                  message: error is DioException
                      ? userFriendlyErrorMessage(error)
                      : error.toString(),
                  onRetry: () => ref.invalidate(reportsTreeProvider),
                ),
              );
            },
            data: (ReportsTree data) {
              if (data.isEmpty) {
                return _FillScroll(
                  minHeight: minHeight,
                  child: _StatusMessage(
                    message: 'No reports found.',
                    onRetry: () => ref.invalidate(reportsTreeProvider),
                  ),
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount: data.forms.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final ReportFormNode node = data.forms[index];
                  if (!node.isExpandable) {
                    return _LeafCard(
                      node: node,
                      onTap: () => _open(context, node),
                    );
                  }
                  return _SectionCard(
                    node: node,
                    expanded: _expandedId == node.formId,
                    expandedChildIds: _expandedChildIds,
                    onToggle: () {
                      setState(() {
                        _expandedId = _expandedId == node.formId
                            ? null
                            : node.formId;
                      });
                    },
                    onToggleChild: (ReportFormNode child) {
                      final String key = '${node.formId}/${child.formId}';
                      setState(() {
                        if (!_expandedChildIds.add(key)) {
                          _expandedChildIds.remove(key);
                        }
                      });
                    },
                    onOpen: (ReportFormNode leaf) => _open(context, leaf),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _open(BuildContext context, ReportFormNode node) {
    context.pushNamed(
      ReportPlaceholderPage.routeName,
      pathParameters: <String, String>{
        'formId': node.formId.isEmpty ? 'report' : node.formId,
      },
      queryParameters: <String, String>{
        'name': node.formName,
        'url': node.webFormUrl,
      },
    );
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

  final ReportFormNode node;
  final bool expanded;
  final Set<String> expandedChildIds;
  final VoidCallback onToggle;
  final ValueChanged<ReportFormNode> onToggleChild;
  final ValueChanged<ReportFormNode> onOpen;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF122844) : palette.cardSurface,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: <Widget>[
                      _IconBadge(icon: _iconForReport(node.formName)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          node.formName,
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
                for (final ReportFormNode child in node.children)
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

  final ReportFormNode node;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<ReportFormNode> onOpen;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? const Color(0xFF1A3354)
          : colors.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    Icon(
                      _iconForReport(node.formName),
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        node.formName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '${node.children.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
              for (final ReportFormNode leaf in node.children)
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

  final ReportFormNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF122844) : palette.cardSurface,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: <Widget>[
              _IconBadge(icon: _iconForReport(node.formName)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  node.formName,
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

  final ReportFormNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? const Color(0xFF1A3354)
          : colors.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(
                _iconForReport(node.formName),
                color: colors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  node.formName.isEmpty ? node.formId : node.formName,
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: colors.primary),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _FillScroll extends StatelessWidget {
  const _FillScroll({required this.child, required this.minHeight});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : minHeight;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: math.max(height, minHeight), child: child),
        );
      },
    );
  }
}

IconData _iconForReport(String name) {
  final String normalized = name.toLowerCase();
  if (normalized.contains('contract')) {
    return Icons.request_quote_rounded;
  }
  if (normalized.contains('activit')) {
    return Icons.table_chart_rounded;
  }
  if (normalized.contains('progress') || normalized.contains('fob')) {
    return Icons.insights_rounded;
  }
  if (normalized.contains('issue')) {
    return Icons.assignment_late_rounded;
  }
  if (normalized.contains('land')) {
    return Icons.handshake_rounded;
  }
  if (normalized.contains('util')) {
    return Icons.electrical_services_rounded;
  }
  if (normalized.contains('letter')) {
    return Icons.mail_outline_rounded;
  }
  return Icons.description_outlined;
}
