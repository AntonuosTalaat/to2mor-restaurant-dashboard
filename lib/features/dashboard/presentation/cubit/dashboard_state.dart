class DashboardState {
  final String selectedPeriod;
  final String restaurantId;
  final bool isLoading;
  final String? lastError;

  const DashboardState({
    this.selectedPeriod = 'اليوم',
    this.restaurantId = '',
    this.isLoading = true,
    this.lastError,
  });

  DashboardState copyWith({
    String? selectedPeriod,
    String? restaurantId,
    bool? isLoading,
    String? lastError,
    bool clearError = false,
  }) {
    return DashboardState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      restaurantId: restaurantId ?? this.restaurantId,
      isLoading: isLoading ?? this.isLoading,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}
