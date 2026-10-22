import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_table_frame.dart';

/// Header + scrollable table body + optional pagination footer.
///
/// Expects a bounded height from the parent ([Scaffold.body], [Expanded], etc.).
/// When height is unbounded, clamps to the remaining screen viewport so the inner
/// [Column] never stacks header + full-height body and overflows.
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
        final double? width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : null;

        return SizedBox(
          height: viewportHeight,
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: header,
                ),
              ),
              Expanded(child: body),
              if (footer != null) footer!,
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

        return AppTableFrame(
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
        );
      },
    );
  }
}
