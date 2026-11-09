import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../Services/app_image_cache_manager.dart';

/// Network image with disk cache on mobile/desktop.
/// On web uses HTML img element to bypass CORS (required for Firebase Hosting).
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.errorBuilder,
    this.loadingBuilder,
  });

  int? _memCacheDimension(double? logicalSize) {
    if (logicalSize == null || !logicalSize.isFinite) return null;
    return (logicalSize * 2).round().clamp(1, 2048);
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (loadingBuilder != null) {
      return loadingBuilder!(context, const SizedBox.shrink(), null);
    }
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error, StackTrace? stackTrace) {
    if (errorBuilder != null) {
      return errorBuilder!(context, error, stackTrace ?? StackTrace.empty);
    }
    return SizedBox(
      width: width,
      height: height,
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildError(context, 'empty image url', null);
    }

    // على الويب: CachedNetworkImage بيعمل fetch وبيترفض بسبب CORS على الـ host.
    // HTML img element بيتجاوز القيد ويعرض Firebase Storage و R2 بدون مشاكل.
    if (kIsWeb) {
      // loadingBuilder غير مدعوم مع webHtmlElementStrategy ويسبب crash في release.
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: AppImageCacheManager.instance,
      memCacheWidth: _memCacheDimension(width),
      memCacheHeight: _memCacheDimension(height),
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => _buildPlaceholder(context),
      errorWidget: (context, url, error) =>
          _buildError(context, error, StackTrace.empty),
    );
  }
}

ImageProvider appNetworkImageProvider(String imageUrl) {
  if (kIsWeb) {
    return NetworkImage(
      imageUrl,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
    );
  }
  return CachedNetworkImageProvider(
    imageUrl,
    cacheManager: AppImageCacheManager.instance,
  );
}
