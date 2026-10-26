import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/presentation/widgets/ncr_observation_list_view.dart';

class NcrObservationsPage extends StatelessWidget {
  const NcrObservationsPage({super.key});

  static const String routeName = 'forms-quality-ncr-observations';
  static const String routePath = '/module/quality/ncr-observations';

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      appBar: AppBar(title: const Text('NCR / Observations')),
      body: const NcrObservationListView(),
    );
  }
}
