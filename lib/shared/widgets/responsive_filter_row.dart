import 'package:flutter/material.dart';

/// Lays out filter controls in one row on wide screens.
///
/// On compact screens, items share a single row by default ([singleRowOnCompact]).
/// Set [singleRowOnCompact] to false to stack: [fullWidthOnCompact] items alone,
/// and pack the rest two-per-row.
class ResponsiveFilterRow extends StatelessWidget {
  const ResponsiveFilterRow({
    super.key,
    required this.items,
    this.compactBreakpoint = 768,
    this.spacing = 6,
    this.runSpacing = 8,
    this.singleRowOnCompact = true,
  });

  final List<ResponsiveFilterRowItem> items;
  final double compactBreakpoint;
  final double spacing;
  final double runSpacing;
  final bool singleRowOnCompact;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < compactBreakpoint;

    if (!isCompact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            if (items[i].expandOnDesktop)
              Expanded(flex: items[i].flex, child: items[i].child)
            else
              items[i].child,
          ],
        ],
      );
    }

    if (singleRowOnCompact && items.length <= 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(flex: items[i].flex, child: items[i].child),
          ],
        ],
      );
    }

    final rows = <Widget>[];
    var i = 0;
    while (i < items.length) {
      final item = items[i];

      if (item.fullWidthOnCompact) {
        rows.add(item.child);
        i += 1;
        continue;
      }

      final next =
          (i + 1 < items.length && !items[i + 1].fullWidthOnCompact)
              ? items[i + 1]
              : null;

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: item.flex, child: item.child),
            if (next != null) ...[
              SizedBox(width: spacing),
              Expanded(flex: next.flex, child: next.child),
            ],
          ],
        ),
      );
      i += next != null ? 2 : 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) SizedBox(height: runSpacing),
          rows[r],
        ],
      ],
    );
  }
}

class ResponsiveFilterRowItem {
  const ResponsiveFilterRowItem({
    required this.child,
    this.flex = 1,
    this.expandOnDesktop = true,
    this.fullWidthOnCompact = false,
  });

  final Widget child;
  final int flex;
  final bool expandOnDesktop;

  /// Used only when [ResponsiveFilterRow.singleRowOnCompact] is false.
  final bool fullWidthOnCompact;
}
