import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.leading,
    this.actionSection,
    this.padding,
    this.backgroundColor,
    this.showShadow = true,
    this.showBottomBorder = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? actionSection;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool showShadow;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    final bgColor = backgroundColor ?? theme.colorScheme.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final shadowColor = AppColors.withOpacity(
      AppColors.black,
      isDark ? 0.28 : 0.05,
    );

    final defaultPadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20,
          vertical: isMobile ? 10 : 12,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        border:
            showBottomBorder
                ? Border(bottom: BorderSide(color: borderColor))
                : null,
        boxShadow:
            showShadow
                ? [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
                : null,
      ),
      child: Padding(
        padding: defaultPadding,
        child:
            isMobile
                ? _buildMobileLayout(context)
                : _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        _buildIconBox(context),
        const SizedBox(width: 12),
        Expanded(child: _buildTitleBlock(context)),
        if (actionSection != null) ...[
          const SizedBox(width: 12),
          Flexible(child: _buildActions(actionSection!)),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    // On mobile: show sidebar menu button only — hide the page icon.
    final showPageIcon = leading == null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        if (showPageIcon) ...[
          _buildIconBox(context, compact: true),
          const SizedBox(width: 10),
        ],
        Expanded(child: _buildTitleBlock(context, compact: true)),
        if (actionSection != null) ...[
          const SizedBox(width: 8),
          Flexible(child: _buildActions(actionSection!)),
        ],
      ],
    );
  }

  Widget _buildActions(Widget actions) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: actions,
      ),
    );
  }

  Widget _buildIconBox(BuildContext context, {bool compact = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boxSize = compact ? 38.0 : 42.0;
    final iconSize = compact ? 20.0 : 22.0;

    return Container(
      width: boxSize,
      height: boxSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient:
            isDark
                ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.goldDark20, AppColors.goldDark10],
                )
                : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.withOpacity(AppColors.primary, isDark ? 0.4 : 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.withOpacity(
              AppColors.primary,
              isDark ? 0.2 : 0.15,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: isDark ? AppColors.primaryLight : AppColors.white,
      ),
    );
  }

  Widget _buildTitleBlock(BuildContext context, {bool compact = false}) {
    final theme = Theme.of(context);
    final subtitleColor = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (compact
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.titleLarge)
              ?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          subtitle,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: subtitleColor,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}
