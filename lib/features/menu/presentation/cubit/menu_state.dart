import 'package:restaurantdashboard/features/menu/data/models/ItemModel.dart';
import 'package:restaurantdashboard/features/menu/data/models/item_extra_model.dart';

class MenuState {
  final List<ItemModel> items;
  final ExtraModel? restaurantExtras;
  final String restaurantType;
  final String restaurantId;
  final bool isLoading;
  final String? lastError;

  const MenuState({
    this.items = const [],
    this.restaurantExtras,
    this.restaurantType = 'food',
    this.restaurantId = '',
    this.isLoading = false,
    this.lastError,
  });

  List<ItemExtra> get extrasList =>
      List.unmodifiable(restaurantExtras?.extras ?? []);

  MenuState copyWith({
    List<ItemModel>? items,
    ExtraModel? restaurantExtras,
    String? restaurantType,
    String? restaurantId,
    bool? isLoading,
    String? lastError,
    bool clearError = false,
    bool clearExtras = false,
  }) {
    return MenuState(
      items: items ?? this.items,
      restaurantExtras:
          clearExtras ? null : (restaurantExtras ?? this.restaurantExtras),
      restaurantType: restaurantType ?? this.restaurantType,
      restaurantId: restaurantId ?? this.restaurantId,
      isLoading: isLoading ?? this.isLoading,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}
