import 'package:flutter/material.dart';

/// Scaffold for search / filter + table + pagination screens.
///
/// Sets [Scaffold.resizeToAvoidBottomInset] to `false` so the keyboard
/// overlays the lower UI instead of pushing the pagination footer up.
/// Form screens that need the focused field to stay above the keyboard
/// should keep using a plain [Scaffold] (default inset resize).
class AppListScaffold extends StatelessWidget {
  const AppListScaffold({
    super.key,
    this.scaffoldKey,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.drawer,
    this.endDrawer,
  });

  /// Optional key for the inner [Scaffold] (e.g. drawer open/close).
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final Widget? drawer;
  final Widget? endDrawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      resizeToAvoidBottomInset: false,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      drawer: drawer,
      endDrawer: endDrawer,
    );
  }
}
