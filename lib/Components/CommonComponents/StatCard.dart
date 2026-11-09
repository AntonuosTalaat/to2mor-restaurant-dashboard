import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final StatCardVariant variant;
  final double? width;
  final bool compact;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.variant = StatCardVariant.standard,
    this.width,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case StatCardVariant.standard:
        return _buildStandardCard(context);
      case StatCardVariant.transparent:
        return _buildTransparentCard(context);
      case StatCardVariant.horizontal:
        return _buildHorizontalCard(context);
    }
  }

  Widget _buildStandardCard(BuildContext context) {
    return Container(
      width: width,
      padding: compact ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 20 : 24),
          SizedBox(height: compact ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            title,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransparentCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        width: width,
        padding: compact ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: compact ? 20 : 24),
            SizedBox(height: compact ? 4 : 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: compact ? 2 : 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white70,
                fontSize: compact ? 10 : 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return Container(
      width: width,
      padding: compact ? const EdgeInsets.all(12) : const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: compact ? 20 : 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: compact ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 4 : 8),
          Text(
            title,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatCardVariant {
  standard,      // النسخة الأساسية
  transparent,   // النسخة الشفافة (للخلفيات الملونة)
  horizontal,    // النسخة الأفقية (للتصميم الأفقي)
}