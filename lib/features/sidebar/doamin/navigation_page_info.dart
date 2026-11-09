import 'package:flutter/material.dart';

import 'navigation_item.dart';

class NavigationPageInfo {
  const NavigationPageInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

NavigationPageInfo navigationPageInfo(NavigationItem item) {
  return switch (item) {
    NavigationItem.dashboard => const NavigationPageInfo(
      icon: Icons.dashboard_rounded,
      title: 'لوحة التحكم',
      subtitle: 'نظرة عامة على أداء المطعم',
    ),
    NavigationItem.orders => const NavigationPageInfo(
      icon: Icons.receipt_long_rounded,
      title: 'الطلبات',
      subtitle: 'عرض ومتابعة طلبات العملاء',
    ),
    NavigationItem.menu => const NavigationPageInfo(
      icon: Icons.restaurant_menu_rounded,
      title: 'القائمة',
      subtitle: 'إدارة أصناف الطعام',
    ),
    NavigationItem.extras => const NavigationPageInfo(
      icon: Icons.tune_rounded,
      title: 'الإضافات',
      subtitle: 'إدارة إضافات الأصناف',
    ),
    NavigationItem.martCategories => const NavigationPageInfo(
      icon: Icons.store_mall_directory_outlined,
      title: 'فئات المارت',
      subtitle: 'إدارة فئات المارت وترتيبها',
    ),
    NavigationItem.reports => const NavigationPageInfo(
      icon: Icons.analytics_rounded,
      title: 'التقارير',
      subtitle: 'متابعة تقارير المبيعات',
    ),
    NavigationItem.reviews => const NavigationPageInfo(
      icon: Icons.rate_review_rounded,
      title: 'التقييمات',
      subtitle: 'متابعة تقييمات العملاء',
    ),
    NavigationItem.faqs => const NavigationPageInfo(
      icon: Icons.help_outline_rounded,
      title: 'الأسئلة الشائعة',
      subtitle: 'إجابات الأسئلة المتكررة',
    ),
    NavigationItem.profile => const NavigationPageInfo(
      icon: Icons.storefront_rounded,
      title: 'الملف الشخصي',
      subtitle: 'بيانات وإعدادات المطعم',
    ),
  };
}
