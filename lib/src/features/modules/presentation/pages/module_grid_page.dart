import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/navigation/module_catalog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_action_card.dart';

class ModuleGridPage extends StatelessWidget {
  const ModuleGridPage({
    super.key,
    required this.title,
    required this.group,
  });

  final String title;
  final ModuleGroup group;

  @override
  Widget build(BuildContext context) {
    final List<AppModule> modules = ModuleCatalog.byGroup(group);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: modules.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          );
        }
        final AppModule module = modules[index - 1];
        return AppActionCard(
          title: module.title,
          subtitle: module.subtitle,
          icon: module.icon,
          titleMaxLines: 2,
          onTap: () => context.pushNamed(module.routeName),
        );
      },
    );
  }
}
