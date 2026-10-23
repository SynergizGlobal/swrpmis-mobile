import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/widgets/rdso_revision_list_view.dart';

class RdsoRevisionMonitorPage extends StatelessWidget {
  const RdsoRevisionMonitorPage({super.key});

  static const String routeName = 'more-rdso-revision';
  static const String routePath = '/module/rdso-revision';

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      appBar: AppBar(title: const Text('Revision Monitor')),
      body: const RdsoRevisionListView(),
    );
  }
}
