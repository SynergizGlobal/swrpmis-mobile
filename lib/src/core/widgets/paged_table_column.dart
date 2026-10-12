import 'package:flutter/material.dart';
import 'package:swr_pmis_mobile/src/core/widgets/app_table_frame.dart';

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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool bounded =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final double? width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : null;
        final Widget column = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: width, child: header),
            if (bounded)
              Expanded(
                child: SizedBox(
                  width: width,
                  height: double.infinity,
                  child: body,
                ),
              )
            else
              SizedBox(width: width, child: body),
            if (footer != null) SizedBox(width: width, child: footer),
          ],
        );
        if (!bounded) {
          return column;
        }
        return SizedBox(
          width: width,
          height: constraints.maxHeight,
          child: column,
        );
      },
    );
  }
}

class TableScrollFrame extends StatelessWidget {
  const TableScrollFrame({
    super.key,
    required this.width,
    required this.slivers,
  });

  final double width;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    final ScrollBehavior clamp = ScrollConfiguration.of(
      context,
    ).copyWith(overscroll: false, physics: const ClampingScrollPhysics());
    final Widget table = AppTableFrame(
      child: ScrollConfiguration(
        behavior: clamp,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: width,
            child: CustomScrollView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              slivers: slivers,
            ),
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.hasBoundedHeight || !constraints.maxHeight.isFinite) {
          return table;
        }
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Align(alignment: Alignment.topLeft, child: table),
        );
      },
    );
  }
}
