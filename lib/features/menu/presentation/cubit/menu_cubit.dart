import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/features/menu/data/datasources/menu_service.dart';
import 'package:restaurantdashboard/features/menu/data/models/ItemModel.dart';
import 'package:restaurantdashboard/features/menu/data/models/item_extra_model.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_state.dart';

class MenuCubit extends Cubit<MenuState> {
  final MenuService _menuService;

  MenuCubit(this._menuService) : super(const MenuState());

  Future<void> loadMenu() async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));
      final restaurant = await _menuService.getRestaurantData();
      emit(
        state.copyWith(
          items: restaurant?.menu ?? [],
          restaurantType: restaurant?.restaurantType ?? 'food',
          restaurantId: restaurant?.id ?? '',
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          lastError: 'Failed to load restaurant data: ${e.toString()}',
        ),
      );
      rethrow;
    }
  }

  Future<void> fetchRestaurantExtras() async {
    try {
      emit(state.copyWith(clearError: true));
      final extras = await _menuService.getRestaurantExtras();
      emit(state.copyWith(restaurantExtras: extras, clearExtras: extras == null));
    } catch (e) {
      emit(
        state.copyWith(
          clearExtras: true,
          lastError: 'Failed to load restaurant extras: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> saveRestaurantExtras(List<ItemExtra> extras) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));
      await _menuService.saveRestaurantExtras(extras);
      emit(
        state.copyWith(
          isLoading: false,
          restaurantExtras:
              state.restaurantExtras?.copyWith(extras: extras) ??
              ExtraModel(
                extras: extras,
                restaurantId: state.restaurantId,
                updatedAt: DateTime.now(),
              ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          lastError: 'Failed to save restaurant extras: ${e.toString()}',
        ),
      );
      rethrow;
    }
  }

  Future<void> saveItem({
    required ItemModel item,
    required String? oldItemName,
    dynamic imageFile,
  }) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));
      await _menuService.saveItem(
        item: item,
        oldItemName: oldItemName,
        imageFile: imageFile,
      );
      final restaurant = await _menuService.getRestaurantData();
      emit(
        state.copyWith(
          items: restaurant?.menu ?? [],
          restaurantType: restaurant?.restaurantType ?? state.restaurantType,
          restaurantId: restaurant?.id ?? state.restaurantId,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          lastError: 'Failed to save item: ${e.toString()}',
        ),
      );
      rethrow;
    }
  }

  Future<({int added, int updated, int skipped})> upsertItemsFromExcel(
    List<ItemModel> importedItems,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));
      final result = await _menuService.upsertItemsFromExcel(importedItems);
      final restaurant = await _menuService.getRestaurantData();
      emit(
        state.copyWith(
          items: restaurant?.menu ?? [],
          isLoading: false,
        ),
      );
      return result;
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          lastError: 'Failed to import items: ${e.toString()}',
        ),
      );
      rethrow;
    }
  }

  Future<void> updateItemExtras(String itemId, List<ItemExtra> extras) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));
      await _menuService.updateItemExtras(itemId, extras);
      await loadMenu();
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          lastError: 'Failed to update item extras: ${e.toString()}',
        ),
      );
      rethrow;
    }
  }

  Future<void> deleteItem(String name) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));
      await _menuService.deleteItem(name);
      await loadMenu();
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          lastError: 'Failed to delete item: ${e.toString()}',
        ),
      );
      rethrow;
    }
  }

  Future<void> toggleItemAvailability(
    String itemId,
    bool newAvailability,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));
      await _menuService.toggleItemAvailability(itemId, newAvailability);

      final updatedItems =
          state.items.map((item) {
            if (item.id == itemId) {
              return item.copyWith(isAvailable: newAvailability);
            }
            return item;
          }).toList();

      emit(state.copyWith(items: updatedItems, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, lastError: e.toString()));
      rethrow;
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
