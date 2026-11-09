import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MartCategoriesFiltersBar extends StatelessWidget {
  const MartCategoriesFiltersBar({
    super.key,
    required this.searchController,
    required this.isBusy,
    required this.onSearchChanged,
    required this.onAdd,
  });

  final TextEditingController searchController;
  final bool isBusy;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final compactBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    );
    final compactFieldPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو العنوان...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: compactFieldPadding,
                border: compactBorder,
                enabledBorder: compactBorder,
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (isBusy)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 6),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          SizedBox(
            width: 100,
            height: 40,
            child: FilledButton.icon(
              onPressed: isBusy ? null : onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('إضافة'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
