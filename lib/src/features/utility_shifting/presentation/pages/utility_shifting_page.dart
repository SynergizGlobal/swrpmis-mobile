import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/presentation/widgets/utility_shifting_list_view.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/presentation/widgets/utility_shifting_uploads_list_view.dart';

class UtilityShiftingPage extends StatefulWidget {
  const UtilityShiftingPage({super.key});

  static const String routeName = 'forms-utility';
  static const String routePath = '/module/utility';

  @override
  State<UtilityShiftingPage> createState() => _UtilityShiftingPageState();
}

class _UtilityShiftingPageState extends State<UtilityShiftingPage>
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
        title: const Text('Utility Shifting'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: appBarForeground,
          unselectedLabelColor: appBarForeground.withValues(alpha: 0.72),
          indicatorColor: appBarForeground,
          dividerColor: appBarForeground.withValues(alpha: 0.22),
          tabs: const <Tab>[
            Tab(text: 'Utility Shifting'),
            Tab(text: 'Uploaded Utility Shifting Data'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[
          UtilityShiftingListView(),
          UtilityShiftingUploadsListView(),
        ],
      ),
    );
  }
}
