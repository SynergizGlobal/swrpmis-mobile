import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/presentation/widgets/material_receipts_list_view.dart';

class MaterialReceiptsPage extends StatelessWidget {
  const MaterialReceiptsPage({super.key});

  static const String routeName = 'forms-quality';
  static const String routePath = '/module/quality';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Material Receipts')),
      body: const MaterialReceiptsListView(),
    );
  }
}
