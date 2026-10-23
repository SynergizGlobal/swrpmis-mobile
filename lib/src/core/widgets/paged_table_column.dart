import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_table_frame.dart';

/// Header + table body + optional pagination footer.
///
/// Host pages should use AppListScaffold (or set
/// `resizeToAvoidBottomInset: false`) so the keyboard overlays the footer
/// instead of pushing it up.
///
/// Parent must give a bounded height ([Scaffold.body], [Expanded], [TabBarView]
/// tab, etc.). When height is unbounded, clamps to the remaining screen
/// viewport so the inner [Column] can still host an [Expanded] body.
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

  static double _resolveViewportHeight(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    if (constraints.hasBoundedHeight && constraints.maxHeight.isFinite) {
      return constraints.maxHeight;
    }
    final MediaQueryData media = MediaQuery.of(context);
    final double top = media.padding.top + kToolbarHeight;
    final double bottom = media.padding.bottom;
    return (media.size.height - top - bottom).clamp(200, media.size.height);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportHeight = _resolveViewportHeight(
          context,
          constraints,
        );
        // Always pass a finite width so header Rows with Expanded (search,
        // filter fields) never see unbounded horizontal constraints.
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return SizedBox(
          height: viewportHeight,
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              header,
              Expanded(child: SizedBox.expand(child: body)),
              ?footer,
            ],
          ),
        );
      },
    );
  }
}

/// Horizontally scrollable table with a fixed header row and vertically
/// scrolling [ListView.builder] body.
///
/// Must sit under a parent that supplies a finite height (typically
/// [Expanded] inside [PagedTableColumn]). The vertical [ListView] is always
/// inside [Expanded] under an explicit tight [SizedBox] height — never under
/// max-only / unbounded constraints.
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

  static double _resolveBodyHeight(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    if (constraints.hasBoundedHeight && constraints.maxHeight.isFinite) {
      return constraints.maxHeight;
    }
    final MediaQueryData media = MediaQuery.of(context);
    return (media.size.height * 0.45).clamp(240, media.size.height);
  }

  @override
  Widget build(BuildContext context) {
    final ScrollBehavior behavior = _scrollBehavior(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportHeight = _resolveBodyHeight(context, constraints);
        final double? frameWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : null;
        final bool tightParent =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        final Widget frame = AppTableFrame(
          child: ScrollConfiguration(
            behavior: behavior,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              primary: false,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: width,
                height: viewportHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    Expanded(
                      child: SizedBox.expand(
                        child: ListView.builder(
                          primary: false,
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.only(bottom: bottomPadding),
                          itemCount: itemCount,
                          itemBuilder: itemBuilder,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Tight height so Expanded → ListView always lays out with finite size.
        if (tightParent) {
          return SizedBox.expand(child: frame);
        }
        return SizedBox(
          height: viewportHeight,
          width: frameWidth,
          child: frame,
        );
      },
    );
  }
}
