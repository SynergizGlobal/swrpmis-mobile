import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/navigation/module_catalog.dart';

class UpdateFormsPage extends StatelessWidget {
  const UpdateFormsPage({super.key});

  static const String routeName = 'update-forms';
  static const String routePath = '/update-forms';

  @override
  Widget build(BuildContext context) {
    final List<AppModule> modules = ModuleCatalog.byGroup(
      ModuleGroup.updateForms,
    );
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 132,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: modules.length,
      itemBuilder: (BuildContext context, int index) {
        return _UpdateFormCard(module: modules[index]);
      },
    );
  }
}

class _UpdateFormCard extends StatelessWidget {
  const _UpdateFormCard({required this.module});

  final AppModule module;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return Material(
      color: palette.cardSurface,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.pushNamed(module.routeName),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.borderSubtle),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(module.icon, size: 32, color: colors.primary),
                const SizedBox(height: 10),
                Text(
                  module.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
