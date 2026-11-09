import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:restaurantdashboard/Providers/ResturantProvider.dart';
import 'package:restaurantdashboard/Providers/SettingProvider.dart';
import 'package:restaurantdashboard/core/navigation/notification_deep_link.dart';
import 'package:restaurantdashboard/core/navigation/notification_deep_link_handler.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:restaurantdashboard/features/profile/presentation/screens/profile_screen.dart';
import 'package:restaurantdashboard/features/auth/presentation/providers/AuthProvider.dart';
import 'package:restaurantdashboard/features/auth/presentation/screens/LoginScreen.dart';
import 'package:restaurantdashboard/features/auth/presentation/screens/PendingApprovalScreen.dart';
import 'package:restaurantdashboard/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:restaurantdashboard/features/dashboard/presentation/screens/DashboardScreen.dart';
import 'package:restaurantdashboard/features/faqs/presentation/screens/FaqsScreen.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/cubit/mart_categories_cubit.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/screens/mart_categories_screen.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_cubit.dart';
import 'package:restaurantdashboard/features/menu/presentation/screens/CategoriesScreen.dart';
import 'package:restaurantdashboard/features/menu/presentation/screens/extras_screen.dart';
import 'package:restaurantdashboard/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:restaurantdashboard/features/notifications/presentation/widgets/notifications_bottom_sheet.dart';
import 'package:restaurantdashboard/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:restaurantdashboard/features/orders/presentation/screens/OrdersScreen.dart';
import 'package:restaurantdashboard/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:restaurantdashboard/features/reports/presentation/screens/ReportsScreen.dart';
import 'package:restaurantdashboard/features/reviews/presentation/cubit/reviews_cubit.dart';
import 'package:restaurantdashboard/features/reviews/presentation/screens/UserReviewsScreen.dart';
import 'package:restaurantdashboard/features/sidebar/doamin/navigation_item.dart';
import 'package:restaurantdashboard/features/sidebar/doamin/navigation_page_info.dart';
import 'package:restaurantdashboard/features/sidebar/presentation/cubit/navigation_cubit.dart';
import 'package:restaurantdashboard/features/sidebar/presentation/screens/app_sidebar.dart';
import 'package:restaurantdashboard/shared/widgets/header_icon_chip.dart';
import 'package:restaurantdashboard/shared/widgets/lazy_tab_scope.dart';
import 'package:restaurantdashboard/shared/widgets/page_header.dart';
import 'package:restaurantdashboard/shared/widgets/page_header_actions.dart';
import 'package:restaurantdashboard/shared/widgets/page_header_slot_controller.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PageHeaderSlotController(),
      child: BlocProvider(
        create: (_) => NavigationCubit(),
        child: const _MainScreenBody(),
      ),
    );
  }
}

class _MainScreenBody extends StatefulWidget {
  const _MainScreenBody();

  @override
  State<_MainScreenBody> createState() => _MainScreenBodyState();
}

class _MainScreenBodyState extends State<_MainScreenBody> {
  static const List<NavigationItem> _tabs = NavigationItem.values;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<NavigationItem, Widget> _pageCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndAccountStatus();
      _initializeOrdersCubit();
      _initializeNotifications(force: true);
    });
  }

  void _initializeNotifications({bool force = false}) {
    final restaurantId = context.read<AuthProvider>().restaurant?.id;
    if (restaurantId == null || restaurantId.isEmpty) {
      debugPrint('[MainScreen] Notifications skipped: no restaurant id');
      return;
    }
    context.read<NotificationCubit>().initialize(restaurantId, force: force);
  }

  void _checkAuthAndAccountStatus() {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isLoggedIn || authProvider.restaurant == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final accountStatus = authProvider.restaurant!.accountStatus.toLowerCase();
    if (accountStatus != 'active') {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => PendingApprovalScreen(
                accountStatus: authProvider.restaurant!.accountStatus,
              ),
        ),
      );
    }
  }

  void _initializeOrdersCubit() {
    final authProvider = context.read<AuthProvider>();
    final restaurant = authProvider.restaurant;
    if (restaurant == null) return;

    context.read<OrdersCubit>().initialize(restaurant.id);
  }

  Widget _createPage(NavigationItem item) {
    return switch (item) {
      NavigationItem.dashboard => const DashboardScreen(),
      NavigationItem.orders => const OrdersScreen(),
      NavigationItem.menu => const CategoriesScreen(),
      NavigationItem.extras => const ExtrasScreen(),
      NavigationItem.martCategories => const MartCategoriesScreen(),
      NavigationItem.reports => const ReportsScreen(),
      NavigationItem.reviews => const _ReviewsPage(),
      NavigationItem.faqs => const FaqsScreen(),
      NavigationItem.profile => const ProfileScreen(),
    };
  }

  Widget _pageFor(NavigationItem item) {
    return _pageCache.putIfAbsent(item, () => _createPage(item));
  }

  Future<void> _refreshCurrentPage(NavigationItem item) async {
    if (!mounted) return;
    final restaurantId = context.read<AuthProvider>().restaurant?.id;
    if (restaurantId == null) return;

    switch (item) {
      case NavigationItem.dashboard:
        await context.read<DashboardCubit>().load(
          restaurantProvider: context.read<RestaurantProvider>(),
          ordersCubit: context.read<OrdersCubit>(),
        );
      case NavigationItem.orders:
        await context.read<OrdersCubit>().refreshOrders();
      case NavigationItem.menu:
        await context.read<MenuCubit>().loadMenu();
      case NavigationItem.extras:
        await context.read<MenuCubit>().fetchRestaurantExtras();
      case NavigationItem.martCategories:
        await context.read<MartCategoriesCubit>().refresh();
      case NavigationItem.reports:
        await context.read<ReportsCubit>().load(
          ordersCubit: context.read<OrdersCubit>(),
          restaurantId: restaurantId,
        );
      case NavigationItem.reviews:
        await context.read<ReviewsCubit>().refreshReviews(restaurantId);
      case NavigationItem.faqs:
        await context.read<SettingsProvider>().loadSettings();
      case NavigationItem.profile:
        await context.read<AuthProvider>().loadCurrentRestaurant();
        if (!mounted) return;
        await context.read<RestaurantProvider>().fetchRestaurantData();
        if (!mounted) return;
        context.read<ProfileCubit>().cancelEditing();
    }
  }

  int _indexFor(NavigationItem item) => _tabs.indexOf(item);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading && !authProvider.hasCheckedAuth) {
          return _buildLoadingScaffold('جار التحقق من البيانات...');
        }

        if (!authProvider.isLoggedIn || authProvider.restaurant == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _checkAuthAndAccountStatus();
          });
          return _buildLoadingScaffold('جار إعادة التوجيه...');
        }

        final accountStatus =
            authProvider.restaurant!.accountStatus.toLowerCase();
        if (accountStatus != 'active') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _checkAuthAndAccountStatus();
          });
          return _buildLoadingScaffold('جار إعادة التوجيه...');
        }

        final isMobile = ResponsiveBreakpoints.of(context).isMobile;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: BlocListener<NotificationCubit, NotificationState>(
            listenWhen: (previous, current) =>
                previous.foregroundAlert?.id != current.foregroundAlert?.id &&
                current.foregroundAlert != null,
            listener: (context, state) {
              final alert = state.foregroundAlert;
              if (alert == null) return;

              final cubit = context.read<NotificationCubit>();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 6),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (alert.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(alert.body),
                      ],
                    ],
                  ),
                  action: SnackBarAction(
                    label: 'عرض',
                    onPressed: () {
                      cubit.clearForegroundAlert();
                      NotificationDeepLink.navigateFromData(alert.data);
                    },
                  ),
                ),
              );
              cubit.clearForegroundAlert();
            },
            child: NotificationDeepLinkHandler(
              child: Scaffold(
                key: _scaffoldKey,
                drawer: isMobile ? _buildMobileDrawer(context) : null,
                body: SafeArea(
                  child: Row(
                    children: [
                      if (!isMobile)
                        RepaintBoundary(
                          child: BlocSelector<
                            NavigationCubit,
                            NavigationState,
                            ({bool isExpanded, NavigationItem current})
                          >(
                            selector:
                                (state) => (
                                  isExpanded: state.isSidebarExpanded,
                                  current: state.currentItem,
                                ),
                            builder: (context, selected) {
                              return AppSidebar(
                                isExpanded: selected.isExpanded,
                                currentItem: selected.current,
                                onToggle:
                                    () =>
                                        context
                                            .read<NavigationCubit>()
                                            .toggleSidebar(),
                                onNavigate: (route) {
                                  if (route == selected.current) return;
                                  context
                                      .read<NavigationCubit>()
                                      .navigateTo(route);
                                },
                              );
                            },
                          ),
                        ),
                      Expanded(
                        child: Column(
                          children: [
                            _MainPageHeader(
                              scaffoldKey: _scaffoldKey,
                              showMenuButton: isMobile,
                              onRefresh:
                                  () => _refreshCurrentPage(
                                    context
                                        .read<NavigationCubit>()
                                        .state
                                        .currentItem,
                                  ),
                            ),
                            Expanded(
                              child: BlocSelector<
                                NavigationCubit,
                                NavigationState,
                                NavigationItem
                              >(
                                selector: (state) => state.currentItem,
                                builder: (context, activeTab) {
                                  return IndexedStack(
                                    index: _indexFor(activeTab),
                                    sizing: StackFit.expand,
                                    children:
                                        _tabs.map((tab) {
                                          return LazyTabScope<NavigationItem>(
                                            key: ValueKey(tab),
                                            tab: tab,
                                            activeTab: activeTab,
                                            child: _pageFor(tab),
                                          );
                                        }).toList(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: BlocProvider.value(
          value: context.read<NavigationCubit>(),
          child: BlocSelector<NavigationCubit, NavigationState, NavigationItem>(
            selector: (state) => state.currentItem,
            builder: (context, currentItem) {
              return AppSidebar(
                isExpanded: true,
                inDrawer: true,
                currentItem: currentItem,
                onToggle: () => Navigator.pop(context),
                onNavigate: (route) {
                  if (route != currentItem) {
                    context.read<NavigationCubit>().navigateTo(route);
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScaffold(String message) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.goldLight20, AppColors.lightBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewsPage extends StatelessWidget {
  const _ReviewsPage();

  @override
  Widget build(BuildContext context) {
    final restaurant = context.watch<AuthProvider>().restaurant;
    return RestaurantReviewsScreen(
      restaurantId: restaurant?.id ?? '',
      restaurantName: restaurant?.resturantName ?? '',
    );
  }
}

class _MainPageHeader extends StatelessWidget {
  const _MainPageHeader({
    required this.scaffoldKey,
    required this.showMenuButton,
    required this.onRefresh,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool showMenuButton;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      NavigationCubit,
      NavigationState,
      ({NavigationPageInfo pageInfo, NavigationItem item})
    >(
      selector:
          (state) => (
            pageInfo: navigationPageInfo(state.currentItem),
            item: state.currentItem,
          ),
      builder: (context, selected) {
        return BlocSelector<NotificationCubit, NotificationState, int>(
          selector: (state) => state.unreadCount,
          builder: (context, unreadCount) {
            return Consumer<PageHeaderSlotController>(
              builder: (context, slot, _) {
                return PageHeader(
                  icon: selected.pageInfo.icon,
                  title: selected.pageInfo.title,
                  subtitle: selected.pageInfo.subtitle,
                  leading:
                      showMenuButton
                          ? HeaderIconChip(
                            icon: Icons.menu_rounded,
                            onPressed:
                                () => scaffoldKey.currentState?.openDrawer(),
                            tooltip: 'القائمة',
                          )
                          : null,
                  actionSection: PageHeaderActions(
                    key: ValueKey('main_header_actions_${selected.item}'),
                    leadingActions: switch (selected.item) {
                      NavigationItem.martCategories => [
                        const _MartCategoriesExcelHeaderAction(),
                      ],
                      _ => slot.actions,
                    },
                    showVersionUpdate:
                        selected.item == NavigationItem.dashboard,
                    notificationCount: unreadCount,
                    onNotificationsTap: () =>
                        NotificationsBottomSheet.show(context),
                    onRefresh: onRefresh,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MartCategoriesExcelHeaderAction extends StatelessWidget {
  const _MartCategoriesExcelHeaderAction();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor =
        isDark
            ? AppColors.darkSurfaceAlt
            : AppColors.withOpacity(AppColors.primary, 0.08);
    final borderColor = AppColors.withOpacity(
      AppColors.primary,
      isDark ? 0.32 : 0.2,
    );

    return PopupMenuButton<String>(
      tooltip: 'Excel',
      padding: EdgeInsets.zero,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        if (value == 'import') {
          await MartCategoriesScreen.importExcel(context);
        } else if (value == 'export') {
          await MartCategoriesScreen.exportExcel(context);
        }
      },
      itemBuilder:
          (_) => [
            PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(
                    Icons.file_upload_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  const Text('Import'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(
                    Icons.file_download_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  const Text('Export'),
                ],
              ),
            ),
          ],
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Icon(
          Icons.table_view_rounded,
          size: 19,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
