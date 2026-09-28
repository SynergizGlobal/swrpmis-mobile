import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_pmis_mobile/src/app/theme/app_theme.dart';
import 'package:swr_pmis_mobile/src/core/navigation/module_catalog.dart';

void main() {
  test('SWR light palette uses railway navy', () {
    expect(AppTheme.brandPrimary, const Color(0xFF0B2F63));
    expect(AppTheme.brandSecondary, const Color(0xFF1E4F8A));
    expect(AppPalette.light.loginButton, const Color(0xFFC1121F));
  });

  test('module catalog covers sidebar groups', () {
    expect(ModuleCatalog.byGroup(ModuleGroup.works), isNotEmpty);
    expect(ModuleCatalog.byGroup(ModuleGroup.updateForms).length, greaterThan(5));
    expect(
      ModuleCatalog.all.map((AppModule m) => m.routePath).toSet().length,
      ModuleCatalog.all.length,
    );
  });
}
