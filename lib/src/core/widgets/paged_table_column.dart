import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_table_frame.dart';

/// Header + table body + optional pagination footer.
///
/// Host pages should use AppListScaffold (or set
/// `resizeToAvoidBottomInset: false`) so the keyboard overlays the footer
/// instead of pushing it up.
///
/// Parent must give a bounded height ([Scaffold.body], [Expanded], [TabBarView]
/// tab, etc.). Prefer those hosts — this widget intentionally does **not** use a
/// [LayoutBuilder], so it never rebuilds during [Scaffold] layout (which was
/// causing `!_debugDoingThisLayout` / FAB hit-test crashes).
///
/// Layout contract:
/// - Header takes its intrinsic height (no nested vertical scroll band).
///   Callers should use [MainAxisSize.min] on header [Column]s and keep
///   filters compact so the header fits without overflowing the viewport.
/// - Body is always [Expanded] so it receives a tight finite height.
/// - Footer stays pinned below the body.
class PagedTableColumn extends StatelessWidget {
  const PagedTableColumn({
    super.key,
    required this.header,
    required this.body,
    this.footer,
  });

  final Widget header;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        header,
        Expanded(child: body),
        ?footer,
      ],
    );
  }
}

/// Horizontally scrollable table with a fixed header row and vertically
/// scrolling [ListView.builder] body.
///
/// Must sit under a parent that supplies a finite height (typically
/// [Expanded] inside [PagedTableColumn]). Uses a single [LayoutBuilder] only
/// to read that tight height for the synced horizontal scroll viewport.
class TableScrollFrame extends StatelessWidget {
  const TableScrollFrame({
    super.key,
    required this.width,
    required this.header,
    required this.itemCount,
    required this.itemBuilder,
    this.bottomPadding = 16,
  });

  final double width;
  final Widget header;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double bottomPadding;

  static ScrollBehavior _scrollBehavior(BuildContext context) {
    return ScrollConfiguration.of(context).copyWith(
      overscroll: false,
      physics: const ClampingScrollPhysics(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ScrollBehavior behavior = _scrollBehavior(context);

    return AppTableFrame(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double height = constraints.hasBoundedHeight &&
                  constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : (MediaQuery.sizeOf(context).height * 0.45).clamp(
                  240.0,
                  MediaQuery.sizeOf(context).height,
                );

          return ScrollConfiguration(
            behavior: behavior,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              primary: false,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: width,
                height: height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    Expanded(
                      child: ListView.builder(
                        primary: false,
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: bottomPadding),
                        itemCount: itemCount,
                        itemBuilder: itemBuilder,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
