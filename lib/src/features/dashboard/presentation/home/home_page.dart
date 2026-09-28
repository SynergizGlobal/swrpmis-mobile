import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_assets.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_constants.dart';
import 'package:swr_pmis_mobile/src/core/navigation/module_catalog.dart';
import 'package:swr_pmis_mobile/src/core/network/user_friendly_error_message.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/domain/entities/home_dashboard_data.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/presentation/home/providers/home_dashboard_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const String routeName = 'home';
  static const String routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthSession? session = ref.watch(authControllerProvider).valueOrNull;
    final AsyncValue<HomeDashboardData> dashboard =
        ref.watch(homeDashboardProvider);
    final AppPalette palette = AppPalette.of(context);
    final NumberFormat numberFormat = NumberFormat('#,##0.00');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(homeDashboardProvider);
        await ref.read(homeDashboardProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Hi ${session?.userName.isNotEmpty == true ? session!.userName : 'there'}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                AppConstants.ministryLine,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.mutedText,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: dashboard.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object error, StackTrace stackTrace) {
                final String message = error is DioException
                    ? userFriendlyErrorMessage(error)
                    : error.toString();
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.invalidate(homeDashboardProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
              data: (HomeDashboardData data) => _DashboardBody(
                data: data,
                numberFormat: numberFormat,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.numberFormat,
  });

  final HomeDashboardData data;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Image.asset(
                    AppAssets.map,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Project Management Dashboard',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
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
                      const SizedBox(height: 16),
                      _OrgChart(
                        data: data,
                        onSelect: (DashboardOrgUser user) =>
                            _showOrgUserSheet(context, user),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Quick access',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: ModuleCatalog.all
                .where(
                  (AppModule module) => const <String>{
                    'projects',
                    'issues',
                    'rfi',
                    'documents',
                    'mail',
                    'help',
                  }.contains(module.id),
                )
                .map((AppModule module) {
              return Material(
                color: palette.cardSurface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.pushNamed(module.routeName),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(module.icon, color: Theme.of(context).colorScheme.primary),
                        const Spacer(),
                        Text(
                          module.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
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

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.designation,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.userName.isEmpty ? user.userId : user.userName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${user.projectCount} ${user.projectCount == 1 ? 'Project' : 'Projects'}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (assigned.isEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  const Text('No projects assigned'),
                ] else ...<Widget>[
                  const SizedBox(height: 16),
                  ...assigned.map((DashboardProject project) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.account_tree_outlined),
                      title: Text(project.projectName),
                      subtitle: Text(
                        <String>[
                          project.projectTypeName,
                          if (project.status.isNotEmpty) project.status,
                        ].join(' · '),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrgChart extends StatelessWidget {
  const _OrgChart({
    required this.data,
    required this.onSelect,
  });

  final HomeDashboardData data;
  final ValueChanged<DashboardOrgUser> onSelect;

  @override
  Widget build(BuildContext context) {
    if (data.orgUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<DashboardOrgUser> caoUsers = data.caoUsers;
    final List<DashboardOrgUser> hodUsers = data.hodUsers;
    final List<DashboardOrgUser> otherUsers = data.otherUsers;
    final Set<String> nestedDyhodIds = <String>{
      for (final DashboardOrgUser hod in hodUsers)
        ...data.dyhodsReportingTo(hod.userId).map(
              (DashboardOrgUser user) => user.userId,
            ),
    };
    final List<DashboardOrgUser> unassignedDyhods = data.dyhodUsers
        .where((DashboardOrgUser user) => !nestedDyhodIds.contains(user.userId))
        .toList(growable: false);

    return Column(
      children: <Widget>[
        if (caoUsers.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: caoUsers
                .map(
                  (DashboardOrgUser user) => _OrgCard(
                    user: user,
                    emphasized: true,
                    onTap: () => onSelect(user),
                  ),
                )
                .toList(),
          ),
        if (caoUsers.isNotEmpty && hodUsers.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Container(
            width: 2,
            height: 16,
            color: AppTheme.brandSecondary.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 8),
        ],
        if (hodUsers.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: hodUsers.map((DashboardOrgUser hod) {
              final List<DashboardOrgUser> dyhods =
                  data.dyhodsReportingTo(hod.userId);
              return SizedBox(
                width: 148,
                child: Column(
                  children: <Widget>[
                    _OrgCard(user: hod, onTap: () => onSelect(hod)),
                    if (dyhods.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      ...dyhods.map((DashboardOrgUser dyhod) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _OrgCard(
                            user: dyhod,
                            onTap: () => onSelect(dyhod),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        if (unassignedDyhods.isNotEmpty || otherUsers.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: <DashboardOrgUser>[
              ...unassignedDyhods,
              ...otherUsers,
            ]
                .map(
                  (DashboardOrgUser user) => _OrgCard(
                    user: user,
                    onTap: () => onSelect(user),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _OrgCard extends StatelessWidget {
  const _OrgCard({
    required this.user,
    required this.onTap,
    this.emphasized = false,
  });

  final DashboardOrgUser user;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool hasProjects = user.projectCount > 0;
    return Material(
      color: palette.cardSurface.withValues(alpha: 0.96),
      elevation: emphasized ? 3 : 1.5,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: emphasized ? 168 : 148,
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasProjects
                  ? AppTheme.brandSecondary.withValues(alpha: 0.35)
                  : palette.borderSubtle,
            ),
          ),
          child: Column(
            children: <Widget>[
              Text(
                user.designation.isEmpty ? user.userName : user.designation,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: emphasized ? 13 : 12,
                  height: 1.2,
                  color: AppTheme.brandPrimary,
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.kpiFill.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: AppTheme.brandSecondary),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            maxLines: 1,
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
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Text(
            unit,
            style: TextStyle(fontSize: 10, color: palette.mutedText),
          ),
        ],
      ),
    );
  }
}
