import 'package:flutter/material.dart';
import 'package:restaurantdashboard/features/menu/data/models/ItemModel.dart';
import 'package:restaurantdashboard/features/menu/presentation/widgets/ItemCard.dart';

class ItemsGrid extends StatelessWidget {
  final List<ItemModel> items;
  final Function(String) onDelete;
  final Function(ItemModel) onEdit;

  const ItemsGrid({
    super.key,
    required this.items,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double maxCardWidth = 220;
        int crossAxisCount = (constraints.maxWidth / maxCardWidth).floor().clamp(1, 6);

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items.map((item) {
            return SizedBox(
              width: (constraints.maxWidth / crossAxisCount) - 16,
              child: ItemCard(
                item: item,
                onDelete: () => onDelete(item.name),
                onEdit: () => onEdit(item),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}