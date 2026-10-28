import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/structure_form/presentation/widgets/structure_form_list_view.dart';

class StructureFormPage extends StatelessWidget {
  const StructureFormPage({super.key});

  static const String routeName = 'forms-structure-form';
  static const String routePath = '/module/structure-form';

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      appBar: AppBar(title: const Text('Structure Form')),
      body: const StructureFormListView(),
    );
  }
}
