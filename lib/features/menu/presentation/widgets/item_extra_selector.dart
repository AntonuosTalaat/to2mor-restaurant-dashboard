import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_cubit.dart';
import 'package:restaurantdashboard/features/menu/presentation/cubit/menu_state.dart';
import 'package:restaurantdashboard/features/menu/presentation/widgets/extra_card.dart';

class ItemExtrasSelector extends StatelessWidget {
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  const ItemExtrasSelector({
    super.key,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<MenuCubit, MenuState>(
      builder: (_, state) {
        final extras = state.extrasList;

        if (extras.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'لا توجد إضافات — أضفها من إدارة الإضافات',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإضافات المتاحة',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),

            Center(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    extras.map((extra) {
                      final isSelected = selectedIds.contains(extra.id);

                      return GestureDetector(
                        onTap: () {
                          final updated = List<String>.from(selectedIds);

                          if (isSelected) {
                            updated.remove(extra.id);
                          } else {
                            updated.add(extra.id);
                          }

                          onChanged(updated);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: ExtraCard.cardWidth,
                          height: ExtraCard.cardHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? theme.primaryColor
                                      : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: theme.primaryColor.withOpacity(
                                          0.15,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Stack(
                            children: [
                              const SizedBox.expand(),

                              ExtraCard(
                                extra: extra,
                                showActions: false,
                                onEdit: () {},
                                onDelete: () {},
                              ),

                              if (isSelected)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            if (selectedIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'تم اختيار ${selectedIds.length} إضافة',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
