import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/router/app_page.dart';
import 'package:swr_pmis_mobile/src/app/router/go_router_refresh.dart';
import 'package:swr_pmis_mobile/src/core/app_update/app_update_host.dart';
import 'package:swr_pmis_mobile/src/core/navigation/module_catalog.dart';
import 'package:swr_pmis_mobile/src/core/notifications/notification_route_resolver.dart';
import 'package:swr_pmis_mobile/src/core/notifications/pending_notification_location.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_dialog.dart';
import 'package:swr_pmis_mobile/src/features/auth/domain/entities/auth_session.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/presentation/home/home_page.dart';
import 'package:swr_pmis_mobile/src/features/design/presentation/pages/add_design_form_page.dart';
import 'package:swr_pmis_mobile/src/features/design/presentation/pages/design_drawing_page.dart';
import 'package:swr_pmis_mobile/src/features/utility_shifting/presentation/pages/utility_shifting_page.dart';
import 'package:swr_pmis_mobile/src/features/issues/presentation/pages/add_issue_form_page.dart';
import 'package:swr_pmis_mobile/src/features/issues/presentation/pages/issues_page.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/presentation/pages/material_receipt_form_page.dart';
import 'package:swr_pmis_mobile/src/features/material_receipts/presentation/pages/material_receipts_page.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/presentation/pages/ncr_observation_detail_page.dart';
import 'package:swr_pmis_mobile/src/features/ncr_observations/presentation/pages/ncr_observations_page.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/presentation/pages/quality_test_register_detail_page.dart';
import 'package:swr_pmis_mobile/src/features/quality_test_register/presentation/pages/quality_test_register_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_compose_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_module_page.dart';
import 'package:swr_pmis_mobile/src/features/modules/presentation/pages/module_placeholder_page.dart';
import 'package:swr_pmis_mobile/src/features/modules/presentation/pages/update_forms_page.dart';
import 'package:swr_pmis_mobile/src/features/more/presentation/pages/more_page.dart';
import 'package:swr_pmis_mobile/src/features/rdso/domain/rdso_list.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/pages/rdso_drawing_detail_page.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/pages/rdso_library_page.dart';
import 'package:swr_pmis_mobile/src/features/rdso/presentation/pages/rdso_revision_monitor_page.dart';
import 'package:swr_pmis_mobile/src/features/profile/presentation/pages/profile_page.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/report_placeholder_page.dart';
import 'package:swr_pmis_mobile/src/features/rfi/domain/rfi_user_role.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/pages/rfi_inspection_flow_page.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/pages/rfi_page.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/pages/rfi_section_page.dart';
import 'package:swr_pmis_mobile/src/features/rfi/presentation/providers/rfi_inspection_flow_provider.dart';
import 'package:swr_pmis_mobile/src/features/reports/presentation/pages/reports_page.dart';
import 'package:swr_pmis_mobile/src/features/settings/presentation/pages/privacy_policy_page.dart';
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
    navigatorKey: AppDialog.navigatorKey,
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
      if (loggedIn) {
        final PendingNotificationNav? pending = container.read(
          pendingNotificationNavProvider,
        );
        if (pending != null) {
          container.read(pendingNotificationNavProvider.notifier).state = null;
          final AuthSession? session = container
              .read(authControllerProvider)
              .valueOrNull;
          if (!NotificationRouteResolver.isIntendedForUser(
            notificationUserId: pending.userId,
            sessionUserId: session?.userId,
          )) {
            return HomePage.routePath;
          }
          return NotificationRouteResolver.resolve(
            type: pending.type,
            role: RfiUserRoleResolver.fromSession(session),
            referenceType: pending.referenceType,
            referenceId: pending.referenceId,
          );
        }
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
              return AppUpdateHost(
                child: AppShell(navigationShell: navigationShell),
              );
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
                path: ModuleCatalog.rfi.routePath,
                name: ModuleCatalog.rfi.routeName,
                builder: (BuildContext context, GoRouterState state) {
                  return const RfiPage();
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
        path: ReportsPage.routePath,
        name: ReportsPage.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return fadeSlidePage(
            key: state.pageKey,
            child: Scaffold(
              appBar: AppBar(title: const Text('Reports')),
              body: const ReportsPage(),
            ),
          );
        },
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
        path: RfiSectionPage.routePath,
        name: RfiSectionPage.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return fadeSlidePage(
            key: state.pageKey,
            child: RfiSectionPage(
              section: state.pathParameters['section'] ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: RfiInspectionFlowPage.routePath,
        name: RfiInspectionFlowPage.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          final RfiInspectionFlowArgs args = extra is RfiInspectionFlowArgs
              ? extra
              : RfiInspectionFlowArgs(
                  rfiId: int.tryParse(
                        state.uri.queryParameters['rfiId'] ?? '',
                      ) ??
                      0,
                  rfiCategory: state.uri.queryParameters['category'] ?? '',
                  offline: state.uri.queryParameters['offline'] == '1',
                );
          return fadeSlidePage(
            key: state.pageKey,
            child: RfiInspectionFlowPage(args: args),
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
      GoRoute(
        path: PrivacyPolicyPage.routePath,
        name: PrivacyPolicyPage.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return fadeSlidePage(
            key: state.pageKey,
            child: const PrivacyPolicyPage(),
          );
        },
      ),
      GoRoute(
        path: AddIssueFormPage.routePath,
        name: AddIssueFormPage.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return fadeSlidePage(
            key: state.pageKey,
            child: AddIssueFormPage(
              issueId: state.uri.queryParameters['issueId'] ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: AddDesignFormPage.routePath,
        name: AddDesignFormPage.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return fadeSlidePage(
            key: state.pageKey,
            child: AddDesignFormPage(
              designId: state.uri.queryParameters['designId'] ?? '',
              prefill: AddDesignFormPage.prefillFromExtra(state.extra),
            ),
          );
        },
      ),
      GoRoute(
        path: RdsoDrawingDetailPage.routePath,
        name: RdsoDrawingDetailPage.routeName,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          final String drawingId = state.pathParameters['drawingId'] ?? '';
          final RdsoDrawingRow drawing = extra is RdsoDrawingRow
              ? extra
              : RdsoDrawingRow(
                  id: drawingId,
                  subheadId: '',
                  subheadName: '',
                  drawingKey: drawingId,
                  name: '',
                  description: '',
                  sourceUrl: '',
                  fileSize: null,
                  fileId: null,
                  status: '',
                  department: '',
                  revision: '',
                  revisionDate: '',
                );
          return fadeSlidePage(
            key: state.pageKey,
            child: RdsoDrawingDetailPage(drawing: drawing),
          );
        },
      ),
      GoRoute(
        path: MailModulePage.routePath,
        name: MailModulePage.routeName,
        redirect: (BuildContext context, GoRouterState state) {
          if (state.uri.path == MailModulePage.routePath) {
            return MailModulePage.folderPath(MailFolder.inbox);
          }
          return null;
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'inbox',
            name: 'mail-inbox',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return fadeSlidePage(
                key: state.pageKey,
                child: const MailModulePage(folder: MailFolder.inbox),
              );
            },
          ),
          GoRoute(
            path: 'sent',
            name: 'mail-sent',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return fadeSlidePage(
                key: state.pageKey,
                child: const MailModulePage(folder: MailFolder.sent),
              );
            },
          ),
          GoRoute(
            path: 'drafts',
            name: 'mail-drafts',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return fadeSlidePage(
                key: state.pageKey,
                child: const MailModulePage(folder: MailFolder.drafts),
              );
            },
          ),
          GoRoute(
            path: 'trash',
            name: 'mail-trash',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return fadeSlidePage(
                key: state.pageKey,
                child: const MailModulePage(folder: MailFolder.trash),
              );
            },
          ),
          GoRoute(
            path: 'starred',
            name: 'mail-starred',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return fadeSlidePage(
                key: state.pageKey,
                child: const MailModulePage(folder: MailFolder.starred),
              );
            },
          ),
          GoRoute(
            path: 'important',
            name: 'mail-important',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return fadeSlidePage(
                key: state.pageKey,
                child: const MailModulePage(folder: MailFolder.important),
              );
            },
          ),
          GoRoute(
            path: 'compose',
            name: MailComposePage.routeName,
            pageBuilder: (BuildContext context, GoRouterState state) {
              final String? draftId = state.uri.queryParameters['draftId'];
              return fadeSlidePage(
                key: state.pageKey,
                child: MailComposePage(
                  draftId: int.tryParse(draftId ?? ''),
                ),
              );
            },
          ),
          GoRoute(
            path: 'label/:name',
            name: 'mail-label',
            pageBuilder: (BuildContext context, GoRouterState state) {
              final String name =
                  state.pathParameters['name'] ?? '';
              return fadeSlidePage(
                key: state.pageKey,
                child: MailModulePage(
                  folder: MailFolder.label,
                  labelName: Uri.decodeComponent(name),
                ),
              );
            },
          ),
        ],
      ),
      ...ModuleCatalog.routable.where((AppModule module) => module.id != 'mail').map((
        AppModule module,
      ) {
        return GoRoute(
          path: module.routePath,
          name: module.routeName,
          pageBuilder: (BuildContext context, GoRouterState state) {
            final Widget page = module.routeName == IssuesPage.routeName
                ? const IssuesPage()
                : module.routeName == DesignDrawingPage.routeName
                ? const DesignDrawingPage()
                : module.routeName == UtilityShiftingPage.routeName
                ? const UtilityShiftingPage()
                : module.routeName == MaterialReceiptsPage.routeName
                ? const MaterialReceiptsPage()
                : module.routeName == QualityTestRegisterPage.routeName
                ? const QualityTestRegisterPage()
                : module.routeName == NcrObservationsPage.routeName
                ? const NcrObservationsPage()
                : module.routeName == RdsoRevisionMonitorPage.routeName
                ? const RdsoRevisionMonitorPage()
                : module.routeName == RdsoLibraryPage.routeName
                ? const RdsoLibraryPage()
                : ModulePlaceholderPage(module: module);
            return fadeSlidePage(key: state.pageKey, child: page);
          },
          routes: module.routeName == MaterialReceiptsPage.routeName
              ? <RouteBase>[
                  GoRoute(
                    path: 'add',
                    name: MaterialReceiptFormPage.routeNameAdd,
                    pageBuilder: (BuildContext context, GoRouterState state) {
                      return fadeSlidePage(
                        key: state.pageKey,
                        child: const MaterialReceiptFormPage(),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'receipt/:receiptId',
                    name: MaterialReceiptFormPage.routeNameEdit,
                    pageBuilder: (BuildContext context, GoRouterState state) {
                      final String receiptId =
                          state.pathParameters['receiptId'] ?? '';
                      return fadeSlidePage(
                        key: state.pageKey,
                        child: MaterialReceiptFormPage(
                          receiptId: Uri.decodeComponent(receiptId),
                        ),
                      );
                    },
                  ),
                ]
              : module.routeName == QualityTestRegisterPage.routeName
              ? <RouteBase>[
                  GoRoute(
                    path: 'obligation/:obligationId',
                    name: QualityTestRegisterDetailPage.routeName,
                    pageBuilder: (BuildContext context, GoRouterState state) {
                      final int obligationId =
                          int.tryParse(
                            state.pathParameters['obligationId'] ?? '',
                          ) ??
                          0;
                      return fadeSlidePage(
                        key: state.pageKey,
                        child: QualityTestRegisterDetailPage(
                          obligationId: obligationId,
                        ),
                      );
                    },
                  ),
                ]
              : module.routeName == NcrObservationsPage.routeName
              ? <RouteBase>[
                  GoRoute(
                    path: 'item/:observationId',
                    name: NcrObservationDetailPage.routeName,
                    pageBuilder: (BuildContext context, GoRouterState state) {
                      final int observationId =
                          int.tryParse(
                            state.pathParameters['observationId'] ?? '',
                          ) ??
                          0;
                      return fadeSlidePage(
                        key: state.pageKey,
                        child: NcrObservationDetailPage(
                          observationId: observationId,
                        ),
                      );
                    },
                  ),
                ]
              : const <RouteBase>[],
        );
      }),
    ],
  );
});
