import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/core/navigation/module_catalog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_action_card.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  static const String routeName = 'more';
  static const String routePath = '/more';

  @override
  Widget build(BuildContext context) {
    final List<AppModule> modules = ModuleCatalog.byGroup(ModuleGroup.more);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: <Widget>[
        ...modules.map(
          (AppModule module) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppActionCard(
              title: module.title,
              subtitle: module.subtitle,
              icon: module.icon,
              titleMaxLines: 2,
              onTap: () => context.pushNamed(module.routeName),
            ),
          ),
        ),
      ],
    );
  }
}
