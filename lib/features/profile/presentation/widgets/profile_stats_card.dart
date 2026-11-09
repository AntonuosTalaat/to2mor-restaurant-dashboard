import 'package:flutter/material.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/auth/data/models/Resturant_Model.dart';
import 'package:restaurantdashboard/shared/widgets/compact_stats_banner.dart';

class ProfileStatsCard extends StatelessWidget {
  const ProfileStatsCard({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return CompactStatsBanner(
      items: [
        CompactStatItem(
          title: 'المحفظة',
          value: restaurant.formattedTotalEarnings,
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.success,
        ),
        CompactStatItem(
          title: 'التقييم',
          value: restaurant.averageRating.toStringAsFixed(1),
          icon: Icons.star_rounded,
          color: AppColors.warning,
        ),
        CompactStatItem(
          title: 'عدد التقييمات',
          value: '${restaurant.ratingCount}',
          icon: Icons.rate_review_outlined,
          color: AppColors.info,
        ),
        CompactStatItem(
          title: 'الحالة',
          value: restaurant.statusLabel,
          icon: Icons.storefront_outlined,
          color: restaurant.isOpen ? AppColors.success : AppColors.error,
        ),
      ],
      margin: EdgeInsets.zero,
    );
  }
}
