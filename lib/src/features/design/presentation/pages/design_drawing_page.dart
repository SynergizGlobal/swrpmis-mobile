import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/features/design/presentation/widgets/design_uploads_list_view.dart';
import 'package:swr_pmis_mobile/src/features/design/presentation/widgets/designs_list_view.dart';

class DesignDrawingPage extends StatefulWidget {
  const DesignDrawingPage({super.key});

  static const String routeName = 'forms-design';
  static const String routePath = '/module/design';

  @override
  State<DesignDrawingPage> createState() => _DesignDrawingPageState();
}

class _DesignDrawingPageState extends State<DesignDrawingPage>
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design & Drawing'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: appBarForeground,
          unselectedLabelColor: appBarForeground.withValues(alpha: 0.72),
          indicatorColor: appBarForeground,
          dividerColor: appBarForeground.withValues(alpha: 0.22),
          tabs: const <Tab>[
            Tab(text: 'Designs'),
            Tab(text: 'Uploaded Design Data'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[
          DesignsListView(),
          DesignUploadsListView(),
        ],
      ),
    );
  }
}
