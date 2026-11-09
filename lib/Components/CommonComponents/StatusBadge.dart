import 'package:flutter/material.dart';
import 'StatusComponents.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final bool isPickup; // ✅ Added to handle order type context

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.isPickup = false, // ✅ Default to delivery
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusComponents.getStatusColor(status);

    // ✅ Get context-aware status text
    String statusText = StatusComponents.getStatusText(status);

    // ✅ Override text for final statuses based on order type
    if (status == 'shipped' && !isPickup) {
      statusText = 'تم الشحن';
    } else if (status == 'delivered' && isPickup) {
      statusText = 'تم الاستلام';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}