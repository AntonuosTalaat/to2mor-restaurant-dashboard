import 'package:restaurantdashboard/config/app_config.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/core/theme/app_dimens.dart';
import 'package:restaurantdashboard/core/theme/app_shadows.dart';
import 'package:restaurantdashboard/core/theme/cubit/theme_cubit.dart';
import 'package:restaurantdashboard/core/theme/cubit/theme_state.dart';
import 'package:restaurantdashboard/features/auth/presentation/providers/AuthProvider.dart';
import 'package:restaurantdashboard/features/auth/presentation/screens/LoginScreen.dart';
import 'package:restaurantdashboard/features/sidebar/doamin/navigation_item.dart';
import 'package:restaurantdashboard/shared/widgets/branded_logo_with_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class _NavEntry {
  const _NavEntry({
    required this.icon,
    required this.title,
    required this.item,
  });

  final IconData icon;
  final String title;
  final NavigationItem item;
}

class _NavSection {
  const _NavSection({required this.title, required this.entries});

  final String title;
  final List<_NavEntry> entries;
}

const _operationsNavEntries = [
  _NavEntry(
    icon: Icons.receipt_long_rounded,
    title: 'الطلبات',
    item: NavigationItem.orders,
  ),
  _NavEntry(
    icon: Icons.restaurant_menu_rounded,
    title: 'القائمة',
    item: NavigationItem.menu,
  ),
  _NavEntry(
    icon: Icons.tune_rounded,
    title: 'الإضافات',
    item: NavigationItem.extras,
  ),
  _NavEntry(
    icon: Icons.analytics_rounded,
    title: 'التقارير',
    item: NavigationItem.reports,
  ),
];

const _martCategoriesNavEntry = _NavEntry(
  icon: Icons.store_mall_directory_outlined,
  title: 'فئات المارت',
  item: NavigationItem.martCategories,
);

List<_NavSection> _navSectionsFor({required bool isMart}) {
  final operationsEntries = [
    _operationsNavEntries[0],
    _operationsNavEntries[1],
    _operationsNavEntries[2],
    if (isMart) _martCategoriesNavEntry,
    _operationsNavEntries[3],
  ];

  return [
    const _NavSection(
      title: 'الرئيسية',
      entries: [
        _NavEntry(
          icon: Icons.dashboard_rounded,
          title: 'لوحة التحكم',
          item: NavigationItem.dashboard,
        ),
      ],
    ),
    _NavSection(title: 'العمليات', entries: operationsEntries),
    const _NavSection(
      title: 'التفاعل',
      entries: [
        _NavEntry(
          icon: Icons.rate_review_rounded,
          title: 'التقييمات',
          item: NavigationItem.reviews,
        ),
        _NavEntry(
          icon: Icons.help_outline_rounded,
          title: 'الأسئلة الشائعة',
          item: NavigationItem.faqs,
        ),
      ],
    ),
    const _NavSection(
      title: 'الحساب',
      entries: [
        _NavEntry(
          icon: Icons.storefront_rounded,
          title: 'الملف الشخصي',
          item: NavigationItem.profile,
        ),
      ],
    ),
  ];
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.currentItem,
    this.onNavigate,
    this.inDrawer = false,
  });

  final bool isExpanded;
  final VoidCallback onToggle;
  final NavigationItem currentItem;
  final ValueChanged<NavigationItem>? onNavigate;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    final showExpanded = isExpanded;
    final double sidebarWidth =
        inDrawer ? double.infinity : (showExpanded ? 280 : 72);

    return BlocSelector<ThemeCubit, ThemeState, bool>(
      selector: (state) => state.isDark,
      builder: (context, isDark) {
        final scheme = Theme.of(context).colorScheme;
        final isMart =
            context.watch<AuthProvider>().restaurant?.restaurantType == 'mart';
        final navSections = _navSectionsFor(isMart: isMart);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: sidebarWidth,
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(left: BorderSide(color: scheme.outlineVariant)),
            boxShadow: [
              BoxShadow(
                color: AppColors.withOpacity(
                  AppColors.black,
                  isDark ? 0.3 : 0.08,
                ),
                blurRadius: 12,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _SidebarHeader(
                isExpanded: showExpanded,
                isDark: isDark,
                onToggle: onToggle,
                inDrawer: inDrawer,
              ),
              const SizedBox(height: AppDimens.paddingSM),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingSM,
                  ),
                  itemCount: navSections.length,
                  itemBuilder: (context, sectionIndex) {
                    final section = navSections[sectionIndex];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sectionIndex > 0)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: showExpanded ? AppDimens.paddingSM : 4,
                              horizontal:
                                  showExpanded
                                      ? AppDimens.paddingMD
                                      : AppDimens.paddingSM,
                            ),
                            child: Divider(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.7,
                              ),
                              height: 1,
                            ),
                          ),
                        if (showExpanded)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppDimens.paddingMD,
                              sectionIndex == 0 ? 0 : 4,
                              AppDimens.paddingMD,
                              AppDimens.paddingSM,
                            ),
                            child: Text(
                              section.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        for (final entry in section.entries)
                          _SidebarNavItem(
                            entry: entry,
                            isExpanded: showExpanded,
                            isDark: isDark,
                            isSelected: currentItem == entry.item,
                            onTap: () => onNavigate?.call(entry.item),
                          ),
                      ],
                    );
                  },
                ),
              ),
              _SidebarFooter(isExpanded: showExpanded, isDark: isDark),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.isExpanded,
    required this.isDark,
    required this.onToggle,
    this.inDrawer = false,
  });

  final bool isExpanded;
  final bool isDark;
  final VoidCallback onToggle;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? AppDimens.paddingLG : AppDimens.paddingSM,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child:
          isExpanded
              ? Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors:
                            isDark
                                ? [
                                  AppColors.darkSurfaceAlt,
                                  AppColors.darkSurface,
                                ]
                                : [
                                  AppColors.lightSurfaceAlt,
                                  AppColors.lightSurface,
                                ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.withOpacity(
                          AppColors.primary,
                          isDark ? 0.35 : 0.25,
                        ),
                      ),
                      boxShadow:
                          isDark ? AppShadows.cardDark : AppShadows.cardLight,
                    ),
                    child: const BrandedLogoWithShimmer(
                      assetPath: 'assets/images/playstore.png',
                      size: 50,
                      clipBorderRadius: 11,
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingMD),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConfig.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          'لوحة التحكم',
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onToggle,
                    icon: Icon(
                      inDrawer
                          ? Icons.close_rounded
                          : Icons.keyboard_double_arrow_left_rounded,
                      size: 20,
                    ),
                    tooltip: inDrawer ? 'إغلاق القائمة' : 'طي القائمة',
                  ),
                ],
              )
              : Center(
                child: IconButton(
                  onPressed: onToggle,
                  icon: const Icon(Icons.menu_rounded, size: 24),
                  tooltip: 'فتح القائمة',
                ),
              ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.entry,
    required this.isExpanded,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  final _NavEntry entry;
  final bool isExpanded;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isSelected ? scheme.primary : scheme.onSurface;

    Widget tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? scheme.primary.withValues(alpha: isDark ? 0.2 : 0.12)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
            border:
                isSelected
                    ? Border.all(color: scheme.primary.withValues(alpha: 0.4))
                    : null,
          ),
          child: Row(
            children: [
              Icon(entry.icon, color: color, size: 20),
              if (isExpanded) ...[
                const SizedBox(width: AppDimens.paddingMD),
                Expanded(
                  child: Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!isExpanded) {
      tile = Tooltip(message: entry.title, preferBelow: false, child: tile);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: tile,
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.isExpanded, required this.isDark});

  final bool isExpanded;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final restaurant = auth.restaurant;
        final name = restaurant?.resturantName ?? 'مطعم';
        final imageUrl = restaurant?.imageUrl;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? AppDimens.paddingLG : AppDimens.paddingMD,
            vertical: AppDimens.paddingMD,
          ),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              _SidebarAvatar(imageUrl: imageUrl, isDark: isDark),
              if (isExpanded) ...[
                const SizedBox(width: AppDimens.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        'Restaurant',
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  tooltip: 'تسجيل الخروج',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.withOpacity(
                      AppColors.error,
                      0.12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('تسجيل الخروج', textDirection: TextDirection.rtl),
            content: const Text(
              'هل أنت متأكد من تسجيل الخروج؟',
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await context.read<AuthProvider>().signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}

class _SidebarAvatar extends StatelessWidget {
  const _SidebarAvatar({required this.imageUrl, required this.isDark});

  final String? imageUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: 17,
      backgroundColor: scheme.onSurface.withValues(alpha: 0.1),
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child:
          hasImage
              ? null
              : Icon(Icons.person_rounded, size: 20, color: scheme.onSurface),
    );
  }
}
