
import 'package:restaurantdashboard/features/mart_categories/data/models/mart_category_model.dart';

class MartCategoriesState {
  const MartCategoriesState({
    this.items = const [],
    this.isLoading = false,
    this.isBusy = false,
    this.error,
  });

  final List<MartCategoryModel> items;
  final bool isLoading;
  final bool isBusy;
  final String? error;

  MartCategoriesState copyWith({
    List<MartCategoryModel>? items,
    bool? isLoading,
    bool? isBusy,
    String? error,
    bool clearError = false,
  }) {
    return MartCategoriesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
