import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_list_scaffold.dart';
import 'package:swr_pmis_mobile/src/features/projects/presentation/widgets/projects_list_view.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  static const String routeName = 'works-projects';
  static const String routePath = '/module/projects';

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      appBar: AppBar(title: const Text('Project')),
      body: const ProjectsListView(),
    );
  }
}
