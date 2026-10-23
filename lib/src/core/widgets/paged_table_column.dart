import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_table_frame.dart';

/// Header + scrollable table body + optional pagination footer.
///
/// Expects a bounded height from the parent ([Scaffold.body], [Expanded], etc.).
/// When height is unbounded, clamps to the remaining screen viewport so the inner
/// [Column] never stacks header + full-height body and overflows.
///
/// Layout: filters/header keep intrinsic height (scroll only when taller than the
/// cap), [Expanded] table fills the rest, optional footer stays pinned.
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

  /// Minimum height reserved for the table body so filters cannot eat the page.
  static const double _minBodyHeight = 160;

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
        final double? width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : null;
        final double footerReserve = footer == null ? 0 : 56;
        final double headerMaxHeight = math.max(
          120,
          viewportHeight - _minBodyHeight - footerReserve,
        );

        return SizedBox(
          height: viewportHeight,
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Cap header height. shrinkWrap ListView keeps short headers
              // intrinsic; tall filters scroll inside the cap (never a flex
              // Flexible/ListView without shrinkWrap — that leaves body size
              // MISSING and blanks Material Receipts with a navy frame).
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: headerMaxHeight),
                child: ListView(
                  primary: false,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  children: <Widget>[header],
                ),
              ),
              Expanded(child: body),
              ?footer,
            ],
          ),
        );
      },
    );
  }
}

/// Horizontally scrollable table with a fixed header row and vertically scrolling
/// [ListView.builder] body.
///
/// Parent must supply a bounded height (typically [Expanded] inside [PagedTableColumn]).
/// The horizontal child always uses [LayoutBuilder]'s `maxHeight` as its explicit height.
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
        // Force a tight height so the inner vertical ListView always lays out.
        // Loose "max height only" constraints leave ListView size MISSING.
        return SizedBox(
          height: viewportHeight,
          width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
          child: AppTableFrame(
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
            ),
          ),
        );
      },
    );
  }
}
