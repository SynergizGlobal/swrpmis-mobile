import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';

class AppTableFrame extends StatelessWidget {
  const AppTableFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppTheme.cardRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.of(context).cardSurface,
        borderRadius: radius,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}
