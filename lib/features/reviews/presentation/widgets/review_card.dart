import 'package:flutter/material.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/reviews/data/models/RestaurantReviewModel.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.fillFixedSize = false,
  });

  final RestaurantReview review;
  final bool fillFixedSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expand =
            fillFixedSize &&
            constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite;

        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final initial =
            review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '؟';
        final rating = review.restaurantRating.clamp(0, 5);
        final comment = review.restaurantComment?.trim() ?? '';

        final card = Material(
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.withOpacity(AppColors.primary, 0.14),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.userName.isEmpty ? 'عميل' : review.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'طلب #${review.shortOrderId}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatRelative(review.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 18,
                        color: AppColors.warning,
                      );
                    }),
                    const SizedBox(width: 6),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (expand)
                  Expanded(
                    child: Text(
                      comment.isEmpty ? 'بدون تعليق' : comment,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            comment.isEmpty
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                        height: 1.35,
                      ),
                    ),
                  )
                else
                  Text(
                    comment.isEmpty ? 'بدون تعليق' : comment,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          comment.isEmpty
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
        );

        return expand ? SizedBox.expand(child: card) : card;
      },
    );
  }

  static String _formatRelative(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} د';
    if (difference.inHours < 24) return 'منذ ${difference.inHours} س';
    if (difference.inDays < 30) return 'منذ ${difference.inDays} يوم';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
