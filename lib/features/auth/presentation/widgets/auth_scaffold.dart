import 'package:flutter/material.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.showBackButton = false,
    this.onBack,
    this.maxContentWidth = 480,
    this.centerContent = true,
    this.padding,
  });

  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;
  final double maxContentWidth;
  final bool centerContent;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    final gradientColors =
        isDark
            ? [
              AppColors.goldDark20,
              AppColors.darkBackground,
              AppColors.darkSurface,
            ]
            : [
              AppColors.withOpacity(AppColors.primary, 0.12),
              AppColors.lightBackground,
              AppColors.goldLight20,
            ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              left: -70,
              child: _DecorCircle(
                size: 220,
                color: AppColors.withOpacity(
                  AppColors.primary,
                  isDark ? 0.12 : 0.1,
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              right: -90,
              child: _DecorCircle(
                size: 280,
                color: AppColors.withOpacity(
                  AppColors.primary,
                  isDark ? 0.1 : 0.08,
                ),
              ),
            ),
            SafeArea(
              child:
                  centerContent
                      ? Center(
                        child: SingleChildScrollView(
                          padding:
                              padding ??
                              const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxContentWidth,
                            ),
                            child: child,
                          ),
                        ),
                      )
                      : child,
            ),
            if (showBackButton)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                right: 12,
                child: Material(
                  color: AppColors.withOpacity(scheme.surface, 0.92),
                  borderRadius: BorderRadius.circular(12),
                  child: IconButton(
                    tooltip: 'رجوع',
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
