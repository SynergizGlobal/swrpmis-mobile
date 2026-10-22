import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/core/navigation/app_system_back.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:swr_pmis_mobile/src/features/auth/presentation/pages/login_page.dart';
import 'package:swr_pmis_mobile/src/features/dashboard/presentation/home/home_page.dart';

void main() {
  test('isHomeLocation matches dashboard home route', () {
    expect(AppSystemBack.isHomeLocation(HomePage.routePath), isTrue);
    expect(AppSystemBack.isHomeLocation('/works'), isFalse);
  });

  test('isPublicAuthLocation matches login and forgot password', () {
    expect(AppSystemBack.isPublicAuthLocation(LoginPage.routePath), isTrue);
    expect(
      AppSystemBack.isPublicAuthLocation(ForgotPasswordPage.routePath),
      isTrue,
    );
    expect(AppSystemBack.isPublicAuthLocation(HomePage.routePath), isFalse);
  });
}
