import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/router/app_page.dart';
import 'package:swr_pmis_mobile/src/app/router/go_router_refresh.dart';
import 'package:swr_pmis_mobile/src/core/navigation/module_catalog.dart';
import 'package:swr_pmis_mobile/src/core/widgets/global_dialog.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/presentation/home/home_page.dart';
import 'package:swr_pmis_mobile/src/features/modules/presentation/pages/module_placeholder_page.dart';
import 'package:swr_pmis_mobile/src/features/modules/presentation/pages/update_forms_page.dart';
import 'package:swr_pmis_mobile/src/features/more/presentation/pages/more_page.dart';
import 'package:swr_pmis_mobile/src/features/profile/presentation/pages/profile_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/report_placeholder_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/reports_page.dart';
import 'package:swr_pmis_mobile/src/features/settings/presentation/pages/settings_page.dart';
import 'package:swr_pmis_mobile/src/features/shell/presentation/app_shell.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/pages/execution_progress_page.dart';
import 'package:swr_pmis_mobile/src/features/works/presentation/pages/works_page.dart';

final goRouterRefreshProvider = Provider<GoRouterRefresh>((ref) {
  final GoRouterRefresh notifier = GoRouterRefresh();
  ref.listen<AsyncValue<AuthSession?>>(authControllerProvider, (
    AsyncValue<AuthSession?>? previous,
    AsyncValue<AuthSession?> next,
  ) {
    notifier.notifyAuthChanged();
  });
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final GoRouterRefresh refresh = ref.watch(goRouterRefreshProvider);
  return GoRouter(
    navigatorKey: GlobalDialog.navigatorKey,
    initialLocation: LoginPage.routePath,
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final ProviderContainer container = ProviderScope.containerOf(context);
      final bool loggedIn =
          container.read(authControllerProvider).valueOrNull != null;
      final String loc = state.matchedLocation;
      final bool isPublic =
          loc == LoginPage.routePath || loc == ForgotPasswordPage.routePath;
      if (!loggedIn && !isPublic) {
        return LoginPage.routePath;
      }
      if (loggedIn && loc == LoginPage.routePath) {
        return HomePage.routePath;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: LoginPage.routePath,
        name: LoginPage.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return fadeSlidePage(key: state.pageKey, child: const LoginPage());
        },
      ),
      GoRoute(
        path: ForgotPasswordPage.routePath,
        name: ForgotPasswordPage.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return fadeSlidePage(
            key: state.pageKey,
            child: const ForgotPasswordPage(),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return AppShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: HomePage.routePath,
                name: HomePage.routeName,
                builder: (BuildContext context, GoRouterState state) {
                  return const HomePage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: WorksPage.routePath,
                name: WorksPage.routeName,
                builder: (BuildContext context, GoRouterState state) {
                  return const WorksPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: UpdateFormsPage.routePath,
                name: UpdateFormsPage.routeName,
                builder: (BuildContext context, GoRouterState state) {
                  return const UpdateFormsPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: ReportsPage.routePath,
                name: ReportsPage.routeName,
                builder: (BuildContext context, GoRouterState state) {
                  return const ReportsPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: MorePage.routePath,
                name: MorePage.routeName,
                builder: (BuildContext context, GoRouterState state) {
                  return const MorePage();
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: ReportPlaceholderPage.routePath,
        name: ReportPlaceholderPage.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String formId = state.pathParameters['formId'] ?? '';
          final String name = state.uri.queryParameters['name'] ?? '';
          final String url = state.uri.queryParameters['url'] ?? '';
          return fadeSlidePage(
            key: state.pageKey,
            child: ReportPlaceholderPage(
              formId: formId,
              formName: name,
              webFormUrl: url,
            ),
          );
        },
      ),
      GoRoute(
        path: ExecutionProgressPage.routePath,
        name: ExecutionProgressPage.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String projectId = state.pathParameters['projectId'] ?? '';
          final String name = state.uri.queryParameters['name'] ?? '';
          return fadeSlidePage(
            key: state.pageKey,
            child: ExecutionProgressPage(
              projectId: projectId,
              fallbackName: name,
            ),
          );
        },
      ),
      GoRoute(
        path: ProfilePage.routePath,
        name: ProfilePage.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return fadeSlidePage(key: state.pageKey, child: const ProfilePage());
        },
      ),
      GoRoute(
        path: SettingsPage.routePath,
        name: SettingsPage.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return fadeSlidePage(key: state.pageKey, child: const SettingsPage());
        },
      ),
      ...ModuleCatalog.all.map((AppModule module) {
        return GoRoute(
          path: module.routePath,
          name: module.routeName,
          pageBuilder: (BuildContext context, GoRouterState state) {
            return fadeSlidePage(
              key: state.pageKey,
              child: ModulePlaceholderPage(module: module),
            );
          },
        );
      }),
    ],
  );
});
