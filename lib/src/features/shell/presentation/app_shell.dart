import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/constants/app_constants.dart';
import 'package:swr_pmis_mobile/src/core/widgets/swr_logo.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/profile/presentation/pages/profile_page.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final AuthSession? session = ref.watch(authControllerProvider).valueOrNull;
    final String title = switch (navigationShell.currentIndex) {
      0 => AppConstants.appName,
      1 => 'Works',
      2 => 'Update Forms',
      3 => 'RFI',
      _ => 'More',
    };

    final bool onRfi = navigationShell.currentIndex == 3;

    return PopScope(
      canPop: !onRfi,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop || !onRfi) {
          return;
        }
        navigationShell.goBranch(0);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: onRfi
              ? IconButton(
                  tooltip: 'Back',
                  onPressed: () => navigationShell.goBranch(0),
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              : null,
          titleSpacing: onRfi ? 0 : 16,
          title: Row(
            children: <Widget>[
              const SwrLogo(size: 36),
              const SizedBox(width: 10),
              Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
            ],
          ),
          actions: <Widget>[_ProfileButton(session: session)],
        ),
        body: navigationShell,
        bottomNavigationBar: onRfi
            ? null
            : _MainNavBar(
                palette: palette,
                selectedIndex: navigationShell.currentIndex,
                onSelected: (int index) {
                  navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  );
                },
              ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String? letter = _initial(session);
    return IconButton(
      tooltip: 'Profile',
      onPressed: () => context.pushNamed(ProfilePage.routeName),
      icon: letter == null
          ? const Icon(Icons.account_circle_rounded)
          : CircleAvatar(
              radius: 18,
              backgroundColor: palette.avatarFill,
              child: Text(
                letter,
                style: TextStyle(
                  color: palette.avatarText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
    );
  }

  static String? _initial(AuthSession? session) {
    if (session == null) {
      return null;
    }
    final String named = session.userName.trim();
    final String source = named.isNotEmpty ? named : session.userId.trim();
    if (source.isEmpty) {
      return null;
    }
    return source.substring(0, 1).toUpperCase();
  }
}

class _MainNavBar extends StatelessWidget {
  const _MainNavBar({
    required this.palette,
    required this.selectedIndex,
    required this.onSelected,
  });

  final AppPalette palette;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const List<({IconData icon, String label})> _items =
      <({IconData icon, String label})>[
        (icon: Icons.home_rounded, label: 'Home'),
        (icon: Icons.domain_rounded, label: 'Works'),
        (icon: Icons.edit_note_rounded, label: 'Update Forms'),
        (icon: Icons.fact_check_rounded, label: 'RFI'),
        (icon: Icons.grid_view_rounded, label: 'More'),
      ];

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.navBarFill,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: palette.borderSubtle)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Row(
            children: <Widget>[
              for (int index = 0; index < _items.length; index++)
                Expanded(
                  child: _MainNavButton(
                    icon: _items[index].icon,
                    label: _items[index].label,
                    selected: index == selectedIndex,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainNavButton extends StatelessWidget {
  const _MainNavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool dark = colors.brightness == Brightness.dark;
    final Color foreground = selected ? colors.primary : palette.mutedText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    colors.primary.withValues(alpha: dark ? 0.45 : 0.22),
                    palette.navBarFill,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(
                    color: colors.primary.withValues(alpha: dark ? 0.75 : 0.5),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 22, color: foreground),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: foreground,
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
