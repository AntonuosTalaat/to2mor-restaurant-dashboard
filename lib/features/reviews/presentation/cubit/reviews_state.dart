import 'package:restaurantdashboard/features/reviews/data/models/RestaurantReviewModel.dart';

class ReviewsState {
  final bool isLoading;
  final bool isLoadingStats;
  final bool isLoadingMore;
  final bool hasMoreReviews;
  final List<RestaurantReview> restaurantReviews;
  final List<RestaurantReview> filteredReviews;
  final Map<String, dynamic> reviewStats;
  final String searchQuery;
  final double? selectedRating;
  final bool showOnlyWithComments;
  final int selectedDays;

  const ReviewsState({
    this.isLoading = false,
    this.isLoadingStats = false,
    this.isLoadingMore = false,
    this.hasMoreReviews = true,
    this.restaurantReviews = const [],
    this.filteredReviews = const [],
    this.reviewStats = const {},
    this.searchQuery = '',
    this.selectedRating,
    this.showOnlyWithComments = false,
    this.selectedDays = 0,
  });

  List<RestaurantReview> get visibleReviews => filteredReviews;

  int get totalReviews => reviewStats['totalReviews'] ?? 0;

  double get averageRating =>
      (reviewStats['averageRating'] as num?)?.toDouble() ?? 0.0;

  Map<String, int> get ratingDistribution =>
      Map<String, int>.from(reviewStats['ratingDistribution'] ?? {});

  ReviewsState copyWith({
    bool? isLoading,
    bool? isLoadingStats,
    bool? isLoadingMore,
    bool? hasMoreReviews,
    List<RestaurantReview>? restaurantReviews,
    List<RestaurantReview>? filteredReviews,
    Map<String, dynamic>? reviewStats,
    String? searchQuery,
    double? selectedRating,
    bool? showOnlyWithComments,
    int? selectedDays,
    bool clearSelectedRating = false,
  }) {
    return ReviewsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreReviews: hasMoreReviews ?? this.hasMoreReviews,
      restaurantReviews: restaurantReviews ?? this.restaurantReviews,
      filteredReviews: filteredReviews ?? this.filteredReviews,
      reviewStats: reviewStats ?? this.reviewStats,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRating:
          clearSelectedRating
              ? null
              : (selectedRating ?? this.selectedRating),
      showOnlyWithComments:
          showOnlyWithComments ?? this.showOnlyWithComments,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }
}
