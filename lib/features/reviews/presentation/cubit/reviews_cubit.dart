import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/features/reviews/data/datasources/RestaurantReviewService.dart';
import 'package:restaurantdashboard/features/reviews/data/models/RestaurantReviewModel.dart';
import 'package:restaurantdashboard/features/reviews/presentation/cubit/reviews_state.dart';

class ReviewsCubit extends Cubit<ReviewsState> {
  final RestaurantReviewService _reviewService;

  ReviewsCubit(this._reviewService) : super(const ReviewsState());

  Future<void> loadRestaurantReviews(String restaurantId) async {
    emit(state.copyWith(isLoading: true, hasMoreReviews: true));

    try {
      final reviews = await _reviewService.getReviewsByRestaurantId(
        restaurantId,
      );
      emit(state.copyWith(restaurantReviews: reviews, isLoading: false));
      _applyFilters();
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> loadReviewStats(String restaurantId) async {
    emit(state.copyWith(isLoadingStats: true));

    try {
      final stats = await _reviewService.getRestaurantReviewStats(
        restaurantId,
      );
      emit(state.copyWith(reviewStats: stats, isLoadingStats: false));
    } catch (_) {
      emit(state.copyWith(isLoadingStats: false));
    }
  }

  Future<void> loadRestaurantData(String restaurantId) async {
    await Future.wait([
      loadRestaurantReviews(restaurantId),
      loadReviewStats(restaurantId),
    ]);
  }

  Future<void> searchReviews(
    String restaurantId, {
    String? customerName,
    String? orderId,
    double? minRating,
    double? maxRating,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      final reviews = await _reviewService.searchRestaurantReviews(
        restaurantId,
        customerName: customerName,
        orderId: orderId,
        minRating: minRating,
        maxRating: maxRating,
      );
      emit(state.copyWith(restaurantReviews: reviews, isLoading: false));
      _applyFilters();
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query.toLowerCase()));
    _applyFilters();
  }

  void setRatingFilter(double? rating) {
    emit(
      state.copyWith(
        selectedRating: rating,
        clearSelectedRating: rating == null,
      ),
    );
    _applyFilters();
  }

  void toggleCommentsFilter() {
    emit(state.copyWith(showOnlyWithComments: !state.showOnlyWithComments));
    _applyFilters();
  }

  void setDaysFilter(int days) {
    emit(state.copyWith(selectedDays: days));
    _applyFilters();
  }

  void _applyFilters() {
    final query = state.searchQuery;
    final selectedRating = state.selectedRating;
    final showOnlyWithComments = state.showOnlyWithComments;
    final selectedDays = state.selectedDays;

    final filtered =
        state.restaurantReviews.where((review) {
          if (query.isNotEmpty) {
            final matchesSearch =
                review.userName.toLowerCase().contains(query) ||
                review.shortOrderId.toLowerCase().contains(query) ||
                (review.restaurantComment?.toLowerCase().contains(query) ??
                    false);
            if (!matchesSearch) return false;
          }

          if (selectedRating != null &&
              review.restaurantRating.round().clamp(1, 5) !=
                  selectedRating.round()) {
            return false;
          }

          if (showOnlyWithComments) {
            if (review.restaurantComment == null ||
                review.restaurantComment!.isEmpty) {
              return false;
            }
          }

          if (selectedDays > 0) {
            final cutoffDate = DateTime.now().subtract(
              Duration(days: selectedDays),
            );
            if (review.createdAt.isBefore(cutoffDate)) return false;
          }

          return true;
        }).toList();

    emit(state.copyWith(filteredReviews: filtered));
  }

  void clearFilters() {
    emit(
      state.copyWith(
        searchQuery: '',
        clearSelectedRating: true,
        showOnlyWithComments: false,
        selectedDays: 0,
      ),
    );
    _applyFilters();
  }

  Future<void> loadReviewsByRating(String restaurantId, double rating) async {
    emit(state.copyWith(isLoading: true));

    try {
      final reviews = await _reviewService.getReviewsByRating(
        restaurantId,
        rating,
      );
      emit(state.copyWith(restaurantReviews: reviews, isLoading: false));
      _applyFilters();
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> loadRecentReviews(
    String restaurantId, {
    int days = 30,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      final reviews = await _reviewService.getRecentReviews(
        restaurantId,
        days: days,
      );
      emit(state.copyWith(restaurantReviews: reviews, isLoading: false));
      _applyFilters();
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> loadReviewsWithComments(String restaurantId) async {
    emit(state.copyWith(isLoading: true));

    try {
      final reviews = await _reviewService.getReviewsWithComments(
        restaurantId,
      );
      emit(state.copyWith(restaurantReviews: reviews, isLoading: false));
      _applyFilters();
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<bool> deleteReview(String reviewId) async {
    try {
      await _reviewService.deleteReview(reviewId);

      final updatedReviews =
          state.restaurantReviews
              .where((review) => review.id != reviewId)
              .toList();
      final updatedFiltered =
          state.filteredReviews
              .where((review) => review.id != reviewId)
              .toList();

      emit(
        state.copyWith(
          restaurantReviews: updatedReviews,
          filteredReviews: updatedFiltered,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  double getAverageRatingForPeriod(int days) {
    if (state.restaurantReviews.isEmpty) return 0.0;

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentReviews =
        state.restaurantReviews
            .where((review) => review.createdAt.isAfter(cutoffDate))
            .toList();

    if (recentReviews.isEmpty) return 0.0;

    final total = recentReviews.fold<double>(
      0.0,
      (sum, review) => sum + review.restaurantRating,
    );
    return total / recentReviews.length;
  }

  int getReviewCountForPeriod(int days) {
    if (state.restaurantReviews.isEmpty) return 0;

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return state.restaurantReviews
        .where((review) => review.createdAt.isAfter(cutoffDate))
        .length;
  }

  Map<double, List<RestaurantReview>> getReviewsGroupedByRating() {
    final grouped = <double, List<RestaurantReview>>{};

    for (final review in state.restaurantReviews) {
      final rating = review.restaurantRating;
      grouped.putIfAbsent(rating, () => []).add(review);
    }

    return grouped;
  }

  void clearReviews() {
    emit(const ReviewsState());
  }

  Future<void> refreshReviews(String restaurantId) async {
    await loadRestaurantData(restaurantId);
  }
}
