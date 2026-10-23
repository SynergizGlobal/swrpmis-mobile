import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/presentation/widgets/quality_test_register_list_view.dart';

class QualityTestRegisterPage extends StatelessWidget {
  const QualityTestRegisterPage({super.key});

  static const String routeName = 'forms-quality-test-register';
  static const String routePath = '/module/quality/test-register';

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      appBar: AppBar(title: const Text('Quality Test Register')),
      body: const QualityTestRegisterListView(),
    );
  }
}
