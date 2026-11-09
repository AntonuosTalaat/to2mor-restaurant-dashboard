import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/Providers/ResturantProvider.dart';
import 'package:restaurantdashboard/features/auth/data/models/Resturant_Model.dart';
import 'package:restaurantdashboard/features/auth/presentation/providers/AuthProvider.dart';
import 'package:restaurantdashboard/features/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileState());

  void startEditing(Restaurant restaurant) {
    emit(
      state.copyWith(
        isEditing: true,
        latitude: restaurant.latitude,
        longitude: restaurant.longitude,
        clearImage: true,
        clearMessages: true,
      ),
    );
  }

  void cancelEditing() {
    emit(const ProfileState());
  }

  void selectImage(Uint8List bytes, String fileName) {
    emit(
      state.copyWith(
        selectedImageBytes: bytes,
        selectedImageName: fileName,
        clearMessages: true,
      ),
    );
  }

  void setLocation({required double latitude, required double longitude}) {
    emit(
      state.copyWith(
        latitude: latitude,
        longitude: longitude,
        clearMessages: true,
      ),
    );
  }

  void clearMessages() {
    emit(state.copyWith(clearMessages: true));
  }

  Future<void> save({
    required AuthProvider authProvider,
    required RestaurantProvider restaurantProvider,
    required String ownerName,
    required String restaurantName,
    required String address,
    required String orderTimeFinish,
  }) async {
    final restaurant = authProvider.restaurant;
    if (restaurant == null) {
      emit(state.copyWith(lastError: 'بيانات المطعم غير متوفرة'));
      return;
    }

    emit(state.copyWith(isSaving: true, clearMessages: true));

    try {
      await authProvider.updateRestaurantInfo(
        restaurantId: restaurant.id,
        ownerName: ownerName,
        restaurantName: restaurantName,
        address: address,
        imageFile: state.selectedImageBytes,
        imageFileName: state.selectedImageName,
      );

      final lat = state.latitude;
      final lng = state.longitude;
      if (lat != null &&
          lng != null &&
          (lat != restaurant.latitude || lng != restaurant.longitude)) {
        await authProvider.updateRestaurantLocation(
          latitude: lat,
          longitude: lng,
        );
      }

      final trimmedTime = orderTimeFinish.trim();
      if (trimmedTime.isNotEmpty &&
          trimmedTime != restaurant.orderTimeFinish) {
        await restaurantProvider.updateOrderTimeFinish(trimmedTime);
        await authProvider.loadCurrentRestaurant();
      }

      emit(
        const ProfileState(
          successMessage: 'تم حفظ التغييرات بنجاح',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          lastError: 'فشل في حفظ التغييرات: $e',
        ),
      );
    }
  }
}
