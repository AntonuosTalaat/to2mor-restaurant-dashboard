import 'package:flutter/material.dart';

class ReportsState {
  final bool isLoading;
  final DateTimeRange? selectedDateRange;
  final String? lastError;

  const ReportsState({
    this.isLoading = true,
    this.selectedDateRange,
    this.lastError,
  });

  ReportsState copyWith({
    bool? isLoading,
    DateTimeRange? selectedDateRange,
    String? lastError,
    bool clearDateRange = false,
    bool clearError = false,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      selectedDateRange:
          clearDateRange
              ? null
              : (selectedDateRange ?? this.selectedDateRange),
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}
