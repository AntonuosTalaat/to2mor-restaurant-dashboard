import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Shared disk + memory cache for network images across the app.
class AppImageCacheManager {
  static const String _cacheKey = 'restaurantDashboardImages';

  static final CacheManager instance = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 300,
    ),
  );
}
