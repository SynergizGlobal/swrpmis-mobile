import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/presentation/home/home_page.dart';

/// System back / swipe-back policy: pop the route stack when possible; otherwise
/// return to [HomePage.routePath]; exit only from home (or public auth screens).
abstract final class AppSystemBack {
  const AppSystemBack._();

  static bool isHomeLocation(String matchedLocation) =>
      matchedLocation == HomePage.routePath;

  static bool isPublicAuthLocation(String matchedLocation) =>
      matchedLocation == LoginPage.routePath ||
      matchedLocation == ForgotPasswordPage.routePath;

  static bool canPopScope(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      return true;
    }
    final String loc = router.state.matchedLocation;
    if (isPublicAuthLocation(loc)) {
      return true;
    }
    return isHomeLocation(loc);
  }

  static void invoke(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final String loc = router.state.matchedLocation;
    if (isPublicAuthLocation(loc)) {
      SystemNavigator.pop();
      return;
    }
    if (!isHomeLocation(loc)) {
      router.go(HomePage.routePath);
    }
  }
}

/// Wraps routed pages so Android/iOS system back follows [AppSystemBack].
class AppSystemBackScope extends StatelessWidget {
  const AppSystemBackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: AppSystemBack.canPopScope(context),
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        AppSystemBack.invoke(context);
      },
      child: child,
    );
  }
}
