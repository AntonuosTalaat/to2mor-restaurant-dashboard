import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> cardLight = [
    BoxShadow(
      color: AppColors.lightCardShadow,
      blurRadius: 18,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> cardDark = [
    BoxShadow(
      color: AppColors.darkCardShadow,
      blurRadius: 18,
      offset: Offset(0, 10),
    ),
  ];
}

