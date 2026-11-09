import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// شعار العلامة؛ الهالة والـ shimmer افتراضياً مطفأة — فعّلهما في [SplashScreen] فقط عند الحاجة.
class BrandedLogoWithShimmer extends StatefulWidget {
  const BrandedLogoWithShimmer({
    super.key,
    this.size = 140,
    this.assetPath = 'assets/images/playstore.png',
    this.haloColor = AppColors.primary,
    this.showOuterHalo = false,
    this.enableShimmer = false,
    this.clipBorderRadius,
  });

  final double size;
  final String assetPath;
  final Color haloColor;
  final bool showOuterHalo;
  final bool enableShimmer;

  /// إن وُجد يُستخدم لـ [ClipRRect] الخارجي؛ وإلا يُحسب نسبياً من [size].
  final double? clipBorderRadius;

  @override
  State<BrandedLogoWithShimmer> createState() => _BrandedLogoWithShimmerState();
}

class _BrandedLogoWithShimmerState extends State<BrandedLogoWithShimmer>
    with SingleTickerProviderStateMixin {
  AnimationController? _shimmerController;
  Animation<double>? _shimmer;

  double get _outerR =>
      widget.clipBorderRadius ?? (widget.size * 22 / 140).clamp(4.0, 999.0);
  double get _innerR => (widget.size * 28 / 140).clamp(4.0, 999.0);
  double get _haloD => widget.size * 148 / 140;
  double get _shimmerInner => widget.size * 130 / 140;

  @override
  void initState() {
    super.initState();
    if (widget.enableShimmer) {
      _shimmerController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      )..repeat();
      _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final px = (s * dpr).round().clamp(1, 4096);

    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (widget.showOuterHalo)
            Container(
              width: _haloD,
              height: _haloD,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.haloColor.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_outerR),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: s,
                    height: s,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_innerR),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 40 * (s / 140),
                          offset: Offset(0, 16 * (s / 140)),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      widget.assetPath,
                      fit: BoxFit.contain,
                      cacheWidth: px,
                      cacheHeight: px,
                      filterQuality: FilterQuality.low,
                      errorBuilder:
                          (_, _, _) => Icon(
                            Icons.spa_rounded,
                            size: s * 0.46,
                            color: AppColors.primary,
                          ),
                    ),
                  ),
                  if (widget.enableShimmer &&
                      _shimmerController != null &&
                      _shimmer != null)
                    AnimatedBuilder(
                      animation: _shimmerController!,
                      builder: (_, _) {
                        final v = _shimmer!.value;
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment(v - 1, -0.5),
                              end: Alignment(v, 0.5),
                              colors: const [
                                Colors.transparent,
                                Colors.transparent,
                                Color(0x55FFFFFF),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                            ).createShader(bounds);
                          },
                          child: Container(
                            width: _shimmerInner,
                            height: _shimmerInner,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
