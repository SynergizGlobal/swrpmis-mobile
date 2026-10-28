import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/contractors/presentation/widgets/contractors_list_view.dart';

class ContractorsPage extends StatelessWidget {
  const ContractorsPage({super.key});

  static const String routeName = 'forms-contractors';
  static const String routePath = '/module/contractors';

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      appBar: AppBar(title: const Text('Contractor')),
      body: const ContractorsListView(),
    );
  }
}
