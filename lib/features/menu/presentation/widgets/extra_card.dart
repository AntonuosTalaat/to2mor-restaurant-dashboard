import 'package:flutter/material.dart';
import 'package:restaurantdashboard/features/menu/data/models/item_extra_model.dart';
import 'package:restaurantdashboard/Components/CommonComponents/AppNetworkImage.dart';

class ExtraCard extends StatelessWidget {
  final ItemExtra extra;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showActions;
  final bool fillFixedSize;

  static const double cardWidth = 260.0;
  static const double cardHeight = 90.0;
  static const double _imgSize = 90.0;

  const ExtraCard({
    super.key,
    required this.extra,
    required this.onEdit,
    required this.onDelete,
    this.showActions = true,
    this.fillFixedSize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasImg = extra.img != null && extra.img!.isNotEmpty;
    final hasDisc = extra.hasDiscount;

    final card = Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: cs.outlineVariant.withOpacity(0.5),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child:
                      hasImg
                          ? AppNetworkImage(
                            imageUrl: extra.img!,
                            width: _imgSize,
                            height: _imgSize,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _Placeholder(cs: cs),
                          )
                          : _Placeholder(cs: cs),
                ),
                if (hasDisc)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE24B4A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${extra.discountPercent!.toStringAsFixed(0)}%−',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      extra.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          hasDisc
                              ? extra.discountedPrice.toStringAsFixed(0)
                              : extra.price.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D9E75),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'ج.م',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1D9E75),
                          ),
                        ),
                        if (hasDisc) ...[
                          const SizedBox(width: 5),
                          Text(
                            extra.price.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurfaceVariant.withOpacity(0.5),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (showActions)
                      Row(
                        children: [
                          Expanded(
                            child: _StyledBtn(
                              label: 'حذف',
                              icon: Icons.delete_outline_rounded,
                              bgColor: const Color(0xFFE24B4A),
                              onTap: onDelete,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _StyledBtn(
                              label: 'تعديل',
                              icon: Icons.edit_outlined,
                              bgColor: const Color(0xFFFAC775),
                              textColor: const Color(0xFF633806),
                              onTap: onEdit,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final expand =
            fillFixedSize &&
            constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite;
        if (expand) {
          return SizedBox.expand(child: card);
        }
        return SizedBox(width: cardWidth, height: cardHeight, child: card);
      },
    );
  }
}

// ── Placeholder ──────────────────────────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  final ColorScheme cs;
  const _Placeholder({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ExtraCard._imgSize,
      height: ExtraCard._imgSize,
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        size: 28,
        color: cs.onSurfaceVariant.withOpacity(0.4),
      ),
    );
  }
}

// ── Styled button ─────────────────────────────────────────────────────────────
class _StyledBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _StyledBtn({
    required this.label,
    required this.icon,
    required this.bgColor,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: textColor),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
