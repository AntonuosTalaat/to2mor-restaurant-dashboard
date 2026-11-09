/*import 'package:admin_haj/features/users/domain/entities/app_user.dart';
import 'package:flutter/material.dart';

class StatusUtils {
  // ============================
  // 🔵 Status Color
  // ============================
  static Color getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Colors.green;

      case UserStatus.pending:
        return Colors.orange;

      case UserStatus.blocked:
        return Colors.red;
    }
  }

  // ============================
  // 🟢 Button Background Color
  // ============================
  static Color getButtonColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Colors.green.shade50;

      case UserStatus.pending:
        return Colors.orange.shade50;

      case UserStatus.blocked:
        return Colors.grey.shade100;
    }
  }

  // ============================
  // 🟣 Button Text Color
  // ============================
  static Color getButtonTextColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Colors.green.shade700;

      case UserStatus.pending:
        return Colors.orange.shade700;

      case UserStatus.blocked:
        return Colors.grey.shade700;
    }
  }

  // ============================
  // 📝 Arabic Text
  // ============================
  static String getStatusText(UserStatus status) {
    return status.arabicName;
  }

  // ============================
  // ⭐ User Button Text
  // ============================
  static String getUserButtonText(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return 'متاح للعمل';

      case UserStatus.pending:
        return 'قيد المراجعة';

      case UserStatus.blocked:
        return 'غير متاح';
    }
  }

  // ============================
  // 🔔 Icon
  // ============================
  static IconData getStatusIcon(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Icons.verified;

      case UserStatus.pending:
        return Icons.schedule;

      case UserStatus.blocked:
        return Icons.block;
    }
  }
}

 */
import 'dart:ui';

import 'package:flutter/material.dart';

String statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'قيد الانتظار';
    case 'accepted':
      return 'مقبول';
    case 'on_the_way':
      return 'في الطريق';
    case 'delivered':
      return 'تم التسليم';
    case 'cancelled':
      return 'ملغي';
    default:
      return status;
  }
}

Color statusColor(String status, ThemeData theme) {
  switch (status) {
    case 'pending':
      return theme.colorScheme.primary;
    case 'accepted':
      return Colors.green;
    case 'on_the_way':
      return Colors.orangeAccent;
    case 'delivered':
      return Colors.teal;
    case 'cancelled':
      return Colors.redAccent;
    default:
      return theme.colorScheme.primary;
  }
}
