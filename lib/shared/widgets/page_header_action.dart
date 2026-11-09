import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'header_icon_chip.dart';

/// زر إجراء في [PageHeader] — نص على الويب، أيقونة مضغوطة على الموبايل.
class PageHeaderAction extends StatelessWidget {
  const PageHeaderAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final tip = tooltip ?? label;

    if (isMobile) {
      return HeaderIconChip(
        icon: icon,
        onPressed: onPressed,
        tooltip: tip,
      );
    }

    if (label != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label!),
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tip,
    );
  }
}

/// صف من إجراءات الهيدر مع تباعد موحّد.
class PageHeaderActionRow extends StatelessWidget {
  const PageHeaderActionRow({super.key, required this.actions});

  final List<PageHeaderAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          actions[i],
        ],
      ],
    );
  }
}
