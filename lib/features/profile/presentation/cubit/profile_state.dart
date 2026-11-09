import 'dart:typed_data';

class ProfileState {
  const ProfileState({
    this.isEditing = false,
    this.isSaving = false,
    this.selectedImageBytes,
    this.selectedImageName,
    this.latitude,
    this.longitude,
    this.lastError,
    this.successMessage,
  });

  final bool isEditing;
  final bool isSaving;
  final Uint8List? selectedImageBytes;
  final String? selectedImageName;
  final double? latitude;
  final double? longitude;
  final String? lastError;
  final String? successMessage;

  ProfileState copyWith({
    bool? isEditing,
    bool? isSaving,
    Uint8List? selectedImageBytes,
    String? selectedImageName,
    double? latitude,
    double? longitude,
    String? lastError,
    String? successMessage,
    bool clearImage = false,
    bool clearMessages = false,
    bool clearLocation = false,
  }) {
    return ProfileState(
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
      selectedImageBytes:
          clearImage ? null : (selectedImageBytes ?? this.selectedImageBytes),
      selectedImageName:
          clearImage ? null : (selectedImageName ?? this.selectedImageName),
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      lastError: clearMessages ? null : (lastError ?? this.lastError),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}
