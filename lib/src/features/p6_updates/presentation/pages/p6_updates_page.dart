import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/presentation/widgets/p6_history_list_view.dart';
import 'package:swr_pmis_mobile/src/features/p6_updates/presentation/widgets/p6_new_data_view.dart';

class P6UpdatesPage extends StatefulWidget {
  const P6UpdatesPage({super.key});

  static const String routeName = 'forms-p6';
  static const String routePath = '/module/p6';

  @override
  State<P6UpdatesPage> createState() => _P6UpdatesPageState();
}

class _P6UpdatesPageState extends State<P6UpdatesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color appBarForeground =
        theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;

    return AppListScaffold(
      appBar: AppBar(
        title: const Text('Structure P6 Updates'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: appBarForeground,
          unselectedLabelColor: appBarForeground.withValues(alpha: 0.72),
          indicatorColor: appBarForeground,
          dividerColor: appBarForeground.withValues(alpha: 0.22),
          tabs: const <Tab>[
            Tab(text: 'P6 New Data'),
            Tab(text: 'P6 Data History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[
          P6NewDataView(),
          P6HistoryListView(),
        ],
      ),
    );
  }
}
