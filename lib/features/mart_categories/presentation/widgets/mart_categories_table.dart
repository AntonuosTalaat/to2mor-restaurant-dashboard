import 'package:restaurantdashboard/features/mart_categories/data/models/mart_category_model.dart';
import 'package:restaurantdashboard/features/mart_categories/presentation/widgets/mart_category_card.dart';
import 'package:flutter/material.dart';

/// Fixed-size cards; how many fit per row/column depends on screen width.
class MartCategoriesTable extends StatelessWidget {
  const MartCategoriesTable({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  static const double _spacing = 8;

  final List<MartCategoryModel> items;
  final ValueChanged<MartCategoryModel> onEdit;
  final ValueChanged<MartCategoryModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('لا توجد فئات مارت'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(_spacing),
      child: Wrap(
        spacing: _spacing,
        runSpacing: _spacing,
        children: [
          for (final item in items)
            SizedBox(
              width: MartCategoryCard.cardWidth,
              height: MartCategoryCard.cardHeight,
              child: MartCategoryCard(
                key: ValueKey('${item.id}:${item.imageUrl}'),
                item: item,
                onEdit: () => onEdit(item),
                onDelete: () => onDelete(item),
              ),
            ),
        ],
      ),
    );
  }
}
