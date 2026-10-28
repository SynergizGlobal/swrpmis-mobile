import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/structures/presentation/widgets/structures_list_view.dart';

class StructuresPage extends StatelessWidget {
  const StructuresPage({super.key});

  static const String routeName = 'works-structures';
  static const String routePath = '/module/structures';

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      appBar: AppBar(title: const Text('Structure')),
      body: const StructuresListView(),
    );
  }
}
