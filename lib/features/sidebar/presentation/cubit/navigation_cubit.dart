import 'package:restaurantdashboard/features/sidebar/doamin/navigation_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NavigationState {
  final NavigationItem currentItem;
  final bool isSidebarExpanded;

  const NavigationState({
    required this.currentItem,
    required this.isSidebarExpanded,
  });

  NavigationState copyWith({
    NavigationItem? currentItem,
    bool? isSidebarExpanded,
  }) {
    return NavigationState(
      currentItem: currentItem ?? this.currentItem,
      isSidebarExpanded: isSidebarExpanded ?? this.isSidebarExpanded,
    );
  }
}

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit()
    : super(
        const NavigationState(
          currentItem: NavigationItem.dashboard,
          isSidebarExpanded: true,
        ),
      );

  void navigateTo(NavigationItem item) {
    if (state.currentItem == item) return;
    emit(state.copyWith(currentItem: item));
  }

  void toggleSidebar() {
    emit(state.copyWith(isSidebarExpanded: !state.isSidebarExpanded));
  }
}
