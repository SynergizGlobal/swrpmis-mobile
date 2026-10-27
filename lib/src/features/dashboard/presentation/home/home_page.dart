import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_assets.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/domain/entities/home_dashboard_data.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/presentation/home/providers/home_dashboard_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const String routeName = 'home';
  static const String routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HomeDashboardData> dashboard = ref.watch(
      homeDashboardProvider,
    );
    final String viewerUserId =
        ref.watch(authControllerProvider).valueOrNull?.userId.trim() ?? '';
    final NumberFormat numberFormat = NumberFormat('#,##0.00');

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;
        final double minWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 0;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeDashboardProvider);
            await ref.read(homeDashboardProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minWidth,
                minHeight: minHeight,
              ),
              child: dashboard.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (Object error, StackTrace stackTrace) {
                  final String message = error is DioException
                      ? userFriendlyErrorMessage(error)
                      : error.toString();
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(message, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () =>
                                ref.invalidate(homeDashboardProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                data: (HomeDashboardData data) => _DashboardBody(
                  data: data,
                  numberFormat: numberFormat,
                  viewerUserId: viewerUserId,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.numberFormat,
    required this.viewerUserId,
  });

  final HomeDashboardData data;
  final NumberFormat numberFormat;
  final String viewerUserId;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        const Positioned.fill(
          child: Image(
            image: AssetImage(AppAssets.map),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  palette.mapScrim.withValues(alpha: 0.18),
                  palette.mapScrim.withValues(alpha: 0.42),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Project Management Dashboard',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: palette.success.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.wifi_rounded,
                                size: 14,
                                color: palette.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Live',
                                style: TextStyle(
                                  color: palette.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: _KpiCard(
                            icon: Icons.work_outline_rounded,
                            label: 'Total projects',
                            value: '${data.totalProjects}',
                            unit: 'projects',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _KpiCard(
                            icon: Icons.straighten_rounded,
                            label: 'Total length',
                            value: numberFormat.format(data.totalLengthKm),
                            unit: 'km',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _KpiCard(
                            icon: Icons.workspace_premium_outlined,
                            label: 'Commissioned',
                            value: numberFormat.format(data.commissionedKm),
                            unit: 'km',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _OrgChart(
                data: data,
                highlightIds: data.orgHighlightIds(viewerUserId),
                onSelect: (DashboardOrgUser user) =>
                    _showOrgUserSheet(context, user),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  void _showOrgUserSheet(BuildContext context, DashboardOrgUser user) {
    final List<DashboardProject> assigned = user.userTypeFk == 'CAO'
        ? data.projects
        : data.projects
              .where(
                (DashboardProject project) =>
                    user.projectName.isNotEmpty &&
                    project.projectName == user.projectName,
              )
              .toList(growable: false);

    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: palette.cardSurface,
      builder: (BuildContext context) {
        final TextStyle? muted = Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: palette.mutedText);
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              Text(
                user.designation,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.userName.isEmpty ? user.userId : user.userName,
                style: muted,
              ),
              const SizedBox(height: 8),
              Text(
                '${user.projectCount} ${user.projectCount == 1 ? 'Project' : 'Projects'}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              if (assigned.isEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Text('No projects assigned', style: muted),
              ] else ...<Widget>[
                const SizedBox(height: 16),
                ...assigned.map((DashboardProject project) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    iconColor: colors.primary,
                    leading: const Icon(Icons.account_tree_outlined),
                    title: Text(
                      project.projectName,
                      style: TextStyle(color: colors.onSurface),
                    ),
                    subtitle: Text(
                      <String>[
                        project.projectTypeName,
                        if (project.status.isNotEmpty) project.status,
                      ].join(' · '),
                      style: muted,
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OrgChart extends StatefulWidget {
  const _OrgChart({
    required this.data,
    required this.highlightIds,
    required this.onSelect,
  });

  final HomeDashboardData data;
  final Set<String> highlightIds;
  final ValueChanged<DashboardOrgUser> onSelect;

  @override
  State<_OrgChart> createState() => _OrgChartState();
}

class _OrgChartState extends State<_OrgChart> {
  final ScrollController _controller = ScrollController(
    keepScrollOffset: false,
  );
  String _pinnedKey = '';

  @override
  void initState() {
    super.initState();
    _schedulePin();
  }

  @override
  void didUpdateWidget(_OrgChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_userKey(oldWidget.data) != _userKey(widget.data)) {
      _schedulePin();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _userKey(HomeDashboardData data) {
    return data.orgUsers.map((DashboardOrgUser user) => user.userId).join('\n');
  }

  void _schedulePin() {
    final String key = _userKey(widget.data);
    if (_pinnedKey == key) {
      return;
    }
    _pinnedKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) => _pinRoot());
  }

  void _pinRoot() {
    if (!mounted || !_controller.hasClients) {
      return;
    }
    final double maxExtent = _controller.position.maxScrollExtent;
    if (maxExtent <= 0) {
      return;
    }
    _controller.jumpTo(maxExtent / 2);
  }

  @override
  Widget build(BuildContext context) {
    final List<OrgChartNode> forest = widget.data.orgForest;
    if (forest.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewport = constraints.maxWidth;
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            primary: false,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: viewport.isFinite ? viewport : 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  for (
                    int index = 0;
                    index < forest.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) const SizedBox(height: 16),
                    _OrgRoot(
                      node: forest[index],
                      highlightIds: widget.highlightIds,
                      onSelect: widget.onSelect,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrgRoot extends StatelessWidget {
  const _OrgRoot({
    required this.node,
    required this.highlightIds,
    required this.onSelect,
  });

  static const double columnWidth = 148;
  static const double gap = 12;

  final OrgChartNode node;
  final Set<String> highlightIds;
  final ValueChanged<DashboardOrgUser> onSelect;

  @override
  Widget build(BuildContext context) {
    final List<OrgChartNode> children = node.children;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _OrgCard(
          user: node.user,
          highlighted: _isHighlighted(node.user.userId, highlightIds),
          width: columnWidth,
          onTap: () => onSelect(node.user),
        ),
        if (children.isNotEmpty) ...<Widget>[
          _OrgRowLinks(
            count: children.length,
            columnWidth: columnWidth,
            gap: gap,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int index = 0; index < children.length; index++) ...<Widget>[
                if (index > 0) const SizedBox(width: gap),
                SizedBox(
                  width: columnWidth,
                  child: _OrgBranch(
                    node: children[index],
                    highlightIds: highlightIds,
                    onSelect: onSelect,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

bool _isHighlighted(String userId, Set<String> highlightIds) {
  return highlightIds.isEmpty || highlightIds.contains(userId);
}

class _OrgBranch extends StatelessWidget {
  const _OrgBranch({
    required this.node,
    required this.highlightIds,
    required this.onSelect,
  });

  final OrgChartNode node;
  final Set<String> highlightIds;
  final ValueChanged<DashboardOrgUser> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _OrgCard(
          user: node.user,
          highlighted: _isHighlighted(node.user.userId, highlightIds),
          onTap: () => onSelect(node.user),
        ),
        if (node.children.isNotEmpty)
          for (
            int index = 0;
            index < node.children.length;
            index++
          ) ...<Widget>[
            const _OrgStem(),
            _OrgBranch(
              node: node.children[index],
              highlightIds: highlightIds,
              onSelect: onSelect,
            ),
          ],
      ],
    );
  }
}

class _OrgRowLinks extends StatelessWidget {
  const _OrgRowLinks({
    required this.count,
    required this.columnWidth,
    required this.gap,
  });

  final int count;
  final double columnWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final double width = count * columnWidth + (count - 1) * gap;
    return SizedBox(
      width: width,
      height: 28,
      child: CustomPaint(
        painter: _OrgRowLinksPainter(
          color: _orgLineColor(context),
          count: count,
          columnWidth: columnWidth,
          gap: gap,
        ),
      ),
    );
  }
}

class _OrgRowLinksPainter extends CustomPainter {
  const _OrgRowLinksPainter({
    required this.color,
    required this.count,
    required this.columnWidth,
    required this.gap,
  });

  final Color color;
  final int count;
  final double columnWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final double barY = 12;
    final double midX = size.width / 2;
    _paintOrgLine(canvas, Offset(midX, 0), Offset(midX, barY), color);
    if (count > 1) {
      final double left = columnWidth / 2;
      final double right = size.width - columnWidth / 2;
      _paintOrgLine(canvas, Offset(left, barY), Offset(right, barY), color);
    }
    for (int index = 0; index < count; index++) {
      final double x = index * (columnWidth + gap) + columnWidth / 2;
      _paintOrgLine(canvas, Offset(x, barY), Offset(x, size.height), color);
    }
  }

  @override
  bool shouldRepaint(_OrgRowLinksPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.count != count ||
        oldDelegate.columnWidth != columnWidth ||
        oldDelegate.gap != gap;
  }
}

class _OrgStem extends StatelessWidget {
  const _OrgStem();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: CustomPaint(painter: _OrgStemPainter(_orgLineColor(context))),
    );
  }
}

class _OrgStemPainter extends CustomPainter {
  const _OrgStemPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double x = size.width / 2;
    _paintOrgLine(canvas, Offset(x, 0), Offset(x, size.height), color);
  }

  @override
  bool shouldRepaint(_OrgStemPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

Color _orgLineColor(BuildContext context) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFFF4F7FB) : const Color(0xFF1E3F66);
}

void _paintOrgLine(Canvas canvas, Offset start, Offset end, Color color) {
  final bool lightLine = color.computeLuminance() > 0.5;
  final Paint halo = Paint()
    ..color = lightLine ? const Color(0x99000000) : const Color(0x99FFFFFF)
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.butt;
  final Paint line = Paint()
    ..color = color
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.butt;
  canvas.drawLine(start, end, halo);
  canvas.drawLine(start, end, line);
}

class _OrgCard extends StatelessWidget {
  const _OrgCard({
    required this.user,
    required this.onTap,
    this.highlighted = false,
    this.width,
  });

  final DashboardOrgUser user;
  final VoidCallback onTap;
  final bool highlighted;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasProjects = user.projectCount > 0;
    final BorderRadius radius = BorderRadius.circular(AppTheme.cardRadius);
    final Color surface = highlighted
        ? (isDark ? colors.surface : Colors.white)
        : palette.cardSurface.withValues(alpha: isDark ? 0.42 : 0.55);
    return Opacity(
      opacity: highlighted ? 1 : 0.55,
      child: SizedBox(
        width: width ?? double.infinity,
        height: 96,
        child: Material(
          color: surface,
          elevation: highlighted ? 2 : 0,
          shadowColor: Colors.black26,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  width: highlighted ? 1.5 : 1,
                  color: highlighted
                      ? (hasProjects
                            ? colors.primary.withValues(
                                alpha: isDark ? 0.7 : 0.45,
                              )
                            : colors.outlineVariant)
                      : colors.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    user.designation.isEmpty ? user.userName : user.designation,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      height: 1.2,
                      color: isDark ? colors.onSurface : AppTheme.brandPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${user.projectCount} ${user.projectCount == 1 ? 'Project' : 'Projects'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      height: 120,
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: palette.kpiFill,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: palette.mutedText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: colors.onSurface,
            ),
          ),
          Text(unit, style: TextStyle(fontSize: 10, color: palette.mutedText)),
        ],
      ),
    );
  }
}
