import 'package:flutter/material.dart';
import 'package:restaurantdashboard/config/app_config.dart';
import 'package:restaurantdashboard/shared/widgets/branded_logo_with_shimmer.dart';

class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({
    super.key,
    this.subtitle = 'إدارة المطعم والطلبات',
    this.size = 88,
    this.compact = false,
    this.alignment = CrossAxisAlignment.center,
    this.enableShimmer = false,
    this.showOuterHalo = false,
  });

  final String subtitle;
  final double size;
  final bool compact;
  final CrossAxisAlignment alignment;
  final bool enableShimmer;
  final bool showOuterHalo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textAlign =
        alignment == CrossAxisAlignment.start
            ? TextAlign.start
            : TextAlign.center;

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandedLogoWithShimmer(
          size: size,
          enableShimmer: enableShimmer,
          showOuterHalo: showOuterHalo,
        ),
        SizedBox(height: compact ? 12 : 20),
        Text(
          AppConfig.appName,
          textAlign: textAlign,
          style: (compact
                  ? theme.textTheme.headlineSmall
                  : theme.textTheme.headlineMedium)
              ?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: 0.15,
                height: 1.15,
              ),
        ),
        if (subtitle.isNotEmpty) ...[
          SizedBox(height: compact ? 6 : 10),
          Text(
            subtitle,
            textAlign: textAlign,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}
