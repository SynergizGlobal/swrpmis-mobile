import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/app/router/app_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/domain/mail_list.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_compose_page.dart';
import 'package:swr_pmis_mobile/src/features/mail/presentation/pages/mail_module_page.dart';

void main() {
  testWidgets('app-like mail routes: compose push pops back', (tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/module/mail/dashboard',
      routes: <RouteBase>[
        GoRoute(
          path: MailModulePage.routePath,
          name: MailModulePage.routeName,
          redirect: (BuildContext context, GoRouterState state) {
            if (state.uri.path == MailModulePage.routePath) {
              return MailModulePage.folderPath(MailFolder.dashboard);
            }
            return null;
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'dashboard',
              pageBuilder: (context, state) => fadeSlidePage(
                key: state.pageKey,
                child: Scaffold(
                  body: Column(
                    children: [
                      const Text('DASHBOARD'),
                      FilledButton(
                        onPressed: () => context.push(MailComposePage.routePath),
                        child: const Text('Compose Mail'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GoRoute(
              path: 'compose',
              name: MailComposePage.routeName,
              pageBuilder: (context, state) {
                final draftId = state.uri.queryParameters['draftId'];
                return fadeSlidePage(
                  key: state.pageKey,
                  child: Scaffold(
                    appBar: AppBar(title: const Text('Compose Mail')),
                    body: Column(
                      children: [
                        Text('draft=$draftId'),
                        FilledButton(
                          onPressed: () => context.pop(),
                          child: const Text('SendDone'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    expect(find.text('DASHBOARD'), findsOneWidget);
    await tester.tap(find.text('Compose Mail'));
    await tester.pumpAndSettle();
    expect(find.text('Compose Mail'), findsWidgets);
    expect(find.text('SendDone'), findsOneWidget);
    await tester.tap(find.text('SendDone'));
    await tester.pumpAndSettle();
    expect(find.text('DASHBOARD'), findsOneWidget);
  });
}
