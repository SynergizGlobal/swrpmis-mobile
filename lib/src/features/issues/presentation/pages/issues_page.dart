import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/features/issues/presentation/widgets/issues_list_view.dart';

class IssuesPage extends StatelessWidget {
  const IssuesPage({super.key});

  static const String routeName = 'forms-issues';
  static const String routePath = '/module/issues';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issues')),
      body: const IssuesListView(),
    );
  }
}
