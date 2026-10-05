import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/features/works/domain/entities/works_tree.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/pages/execution_progress_page.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/providers/works_providers.dart';

class WorksPage extends ConsumerStatefulWidget {
  const WorksPage({super.key});

  static const String routeName = 'works';
  static const String routePath = '/works';

  @override
  ConsumerState<WorksPage> createState() => _WorksPageState();
}

class _WorksPageState extends ConsumerState<WorksPage> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<WorksTree> tree = ref.watch(worksTreeProvider);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(worksTreeProvider);
            await ref.read(worksTreeProvider.future);
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
                  onRetry: () => ref.invalidate(worksTreeProvider),
                ),
              );
            },
            data: (WorksTree data) {
              if (data.isEmpty) {
                return _FillScroll(
                  minHeight: minHeight,
                  child: _StatusMessage(
                    message: 'No project types found.',
                    onRetry: () => ref.invalidate(worksTreeProvider),
                  ),
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount: data.sections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final WorksTypeSection section = data.sections[index];
                  return _TypeSection(
                    section: section,
                    expanded: _expandedId == section.id,
                    onToggle: () {
                      setState(() {
                        _expandedId = _expandedId == section.id
                            ? null
                            : section.id;
                      });
                    },
                    onProject: (WorksProject project) {
                      context.pushNamed(
                        ExecutionProgressPage.routeName,
                        pathParameters: <String, String>{
                          'projectId': project.id,
                        },
                        queryParameters: <String, String>{'name': project.name},
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _TypeSection extends StatelessWidget {
  const _TypeSection({
    required this.section,
    required this.expanded,
    required this.onToggle,
    required this.onProject,
  });

  final WorksTypeSection section;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<WorksProject> onProject;

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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _iconForType(section.name),
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          section.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${section.projects.length}',
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
                const SizedBox(height: 4),
                if (section.projects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'No projects found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  )
                else
                  for (final WorksProject project in section.projects)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ProjectCard(
                        project: project,
                        onTap: () => onProject(project),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onTap});

  final WorksProject project;
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
                Icons.account_tree_outlined,
                color: colors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  project.name.isEmpty ? project.id : project.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
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

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
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

IconData _iconForType(String name) {
  final String normalized = name.toLowerCase();
  if (normalized.contains('doubl')) {
    return Icons.call_split_rounded;
  }
  if (normalized.contains('gauge')) {
    return Icons.straighten_rounded;
  }
  if (normalized.contains('new line')) {
    return Icons.add_road_rounded;
  }
  if (normalized.contains('special')) {
    return Icons.star_outline_rounded;
  }
  if (normalized.contains('station')) {
    return Icons.train_rounded;
  }
  return Icons.account_tree_rounded;
}
