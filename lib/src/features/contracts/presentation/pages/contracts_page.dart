import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/contracts/presentation/widgets/contracts_list_view.dart';

class ContractsPage extends StatelessWidget {
  const ContractsPage({super.key});

  static const String routeName = 'forms-contracts';
  static const String routePath = '/module/contracts';

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      appBar: AppBar(title: const Text('Contract')),
      body: const ContractsListView(),
    );
  }
}
