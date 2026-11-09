import 'package:flutter/material.dart';

/// Helper class لبناء خلايا الجدول بشكل متسق
class TableCellBuilders {
  /// بناء خلية ID
  static Widget buildIdCell(
    String id, {
    String prefix = '#',
    int substringLength = 8,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 10,
            vertical: isMobile ? 6 : 6,
          ),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.blue.shade50,
            borderRadius: BorderRadius.circular(isMobile ? 6 : 6),
            border: Border.all(
              color: (backgroundColor ?? Colors.blue.shade50).withOpacity(0.3),
            ),
          ),
          child: Text(
            '$prefix${id.substring(0, substringLength.clamp(0, id.length))}',
            style: TextStyle(
              fontSize: isMobile ? 13 : 13,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.blue.shade700,
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }

  /// بناء خلية معلومات المستخدم
  static Widget buildUserInfoCell({
    required String name,
    required String email,
    double maxWidth = 200,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;
        final onSurface = theme.colorScheme.onSurface;
        final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

        return Container(
          constraints: BoxConstraints(maxWidth: isMobile ? maxWidth : maxWidth),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 14,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 4 : 4),
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: isMobile ? 12 : 12,
                    color: onSurfaceVariant,
                  ),
                  SizedBox(width: isMobile ? 4 : 4),
                  Expanded(
                    child: Text(
                      email,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 12,
                        color: onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// بناء خلية Chip
  static Widget buildChipCell({
    required String label,
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    IconData? icon,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;
        final surfaceContainerHighest =
            theme.colorScheme.surfaceContainerHighest;
        final outline = theme.colorScheme.outline;
        final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 12,
            vertical: isMobile ? 6 : 6,
          ),
          decoration: BoxDecoration(
            color: backgroundColor ?? surfaceContainerHighest,
            borderRadius: BorderRadius.circular(isMobile ? 6 : 6),
            border: Border.all(
              color: borderColor ?? outline.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: isMobile ? 14 : 14,
                  color: textColor ?? onSurfaceVariant,
                ),
                SizedBox(width: isMobile ? 4 : 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 13,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// بناء خلية الإجراءات
  static Widget buildActionsCell({
    VoidCallback? onView,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    String? viewTooltip,
    String? editTooltip,
    String? deleteTooltip,
  }) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onView != null)
              IconButton(
                icon: Icon(Icons.visibility, size: isMobile ? 18 : 18),
                color: Colors.blue,
                tooltip: viewTooltip ?? 'عرض',
                onPressed: onView,
                padding: EdgeInsets.all(isMobile ? 8 : 8),
                constraints: BoxConstraints(
                  minWidth: isMobile ? 36 : 36,
                  minHeight: isMobile ? 36 : 36,
                ),
              ),
            if (onEdit != null)
              IconButton(
                icon: Icon(Icons.edit, size: isMobile ? 18 : 18),
                color: Colors.orange,
                tooltip: editTooltip ?? 'تعديل',
                onPressed: onEdit,
                padding: EdgeInsets.all(isMobile ? 8 : 8),
                constraints: BoxConstraints(
                  minWidth: isMobile ? 36 : 36,
                  minHeight: isMobile ? 36 : 36,
                ),
              ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete, size: isMobile ? 18 : 18),
                color: Colors.red,
                tooltip: deleteTooltip ?? 'حذف',
                onPressed: onDelete,
                padding: EdgeInsets.all(isMobile ? 8 : 8),
                constraints: BoxConstraints(
                  minWidth: isMobile ? 36 : 36,
                  minHeight: isMobile ? 36 : 36,
                ),
              ),
          ],
        );
      },
    );
  }

  /// بناء خلية نص بسيطة
  static Widget buildTextCell(
    String text, {
    FontWeight? fontWeight,
    Color? color,
    int? maxLines,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 768;
        final textColor = color ?? theme.colorScheme.onSurface;

        return Text(
          text,
          style: TextStyle(
            fontSize: isMobile ? 14 : 14,
            fontWeight: fontWeight ?? FontWeight.normal,
            color: textColor,
          ),
          maxLines: maxLines ?? 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
