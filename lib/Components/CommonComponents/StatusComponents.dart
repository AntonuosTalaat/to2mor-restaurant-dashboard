import 'package:flutter/material.dart';

class StatusComponents {
  // Color mapping function
  static Color getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'preparing': return Colors.blue;
      case 'ready': return Colors.green;
      case 'shipped': return Colors.purple;  // ✅ Changed to purple for delivery
      case 'delivered': return Colors.green; // ✅ Added delivered status for pickup
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  // Text mapping function
  static String getStatusText(String status) {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'preparing': return 'قيد التنفيذ';
      case 'ready': return 'جاهز للاستلام';
      case 'shipped': return 'تم الشحن';        // ✅ More specific for delivery
      case 'delivered': return 'تم الاستلام';   // ✅ Added for pickup completion
      case 'cancelled': return 'ملغي';
      default: return 'غير معروف';
    }
  }

  // Enhanced status badge widget with order type context
  static Widget statusBadge(String status, {bool isPickup = false}) {
    // ✅ Use context-aware text for better clarity
    String displayText = getStatusText(status);

    // Special handling for final statuses based on order type
    if (status == 'shipped' && !isPickup) {
      displayText = 'تم الشحن';
    } else if (status == 'delivered' && isPickup) {
      displayText = 'تم الاستلام';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getStatusColor(status),
          width: 1,
        ),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Status indicator with icon
  static Widget statusIndicator(String status) {
    IconData icon;
    switch (status) {
      case 'pending':
        icon = Icons.access_time;
        break;
      case 'preparing':
        icon = Icons.restaurant;
        break;
      case 'ready':
        icon = Icons.check_circle_outline;
        break;
      case 'shipped':
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        break;
      default:
        icon = Icons.help_outline;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: getStatusColor(status), size: 16),
        const SizedBox(width: 4),
        Text(
          getStatusText(status),
          style: TextStyle(
            color: getStatusColor(status),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Status chip (Material Design chip style)
  static Widget statusChip(String status) {
    return Chip(
      backgroundColor: getStatusColor(status).withOpacity(0.1),
      label: Text(
        getStatusText(status),
        style: TextStyle(color: getStatusColor(status)),
      ),
      avatar: Icon(
        _getStatusIcon(status),
        color: getStatusColor(status),
        size: 16,
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: getStatusColor(status).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // Helper function for getting icons
  static IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.check_circle_outline;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.close;
      default:
        return Icons.help_outline;
    }
  }
}