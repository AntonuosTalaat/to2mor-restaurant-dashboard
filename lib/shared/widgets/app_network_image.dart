import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Network image tuned for lists/tables: decode cache size + light placeholder.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.broken_image_outlined,
    this.placeholderIconSize = 18,
    this.filterQuality = FilterQuality.medium,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;
  final double placeholderIconSize;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return _placeholder();
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth =
        width != null ? (width! * dpr).round().clamp(1, 2048) : null;
    final cacheHeight =
        height != null ? (height! * dpr).round().clamp(1, 2048) : null;

    Widget image = Image.network(
      trimmed,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      filterQuality: filterQuality,
      gaplessPlayback: true,
      webHtmlElementStrategy: kIsWeb
          ? WebHtmlElementStrategy.prefer
          : WebHtmlElementStrategy.never,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _placeholder(showProgress: true);
      },
      errorBuilder: (_, _, _) => _placeholder(),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _placeholder({bool showProgress = false}) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: borderRadius,
        ),
        child: Center(
          child: showProgress
              ? SizedBox(
                  width: placeholderIconSize,
                  height: placeholderIconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey.shade500,
                  ),
                )
              : Icon(
                  placeholderIcon,
                  size: placeholderIconSize,
                  color: Colors.grey.shade500,
                ),
        ),
      ),
    );
  }
}
