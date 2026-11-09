import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:restaurantdashboard/Components/CommonComponents/AppNetworkImage.dart';
import 'package:restaurantdashboard/core/theme/app_colors.dart';
import 'package:restaurantdashboard/features/auth/data/models/Resturant_Model.dart';

class ProfileImageSection extends StatelessWidget {
  const ProfileImageSection({
    super.key,
    required this.restaurant,
    required this.isEditing,
    this.selectedImageBytes,
    this.onPickImage,
  });

  final Restaurant restaurant;
  final bool isEditing;
  final Uint8List? selectedImageBytes;
  final VoidCallback? onPickImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: ClipOval(
                child:
                    selectedImageBytes != null
                        ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                        : restaurant.imageUrl.isNotEmpty
                        ? AppNetworkImage(
                          imageUrl: restaurant.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => ColoredBox(
                                color: scheme.surfaceContainerHighest,
                                child: const Icon(
                                  Icons.restaurant_rounded,
                                  size: 36,
                                ),
                              ),
                        )
                        : ColoredBox(
                          color: scheme.surfaceContainerHighest,
                          child: const Icon(Icons.restaurant_rounded, size: 36),
                        ),
              ),
            ),
            if (isEditing)
              Positioned(
                bottom: 0,
                left: 0,
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onPickImage,
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                restaurant.resturantName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                restaurant.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (isEditing) ...[
                const SizedBox(height: 6),
                Text(
                  'اضغط على الكاميرا لتغيير صورة المطعم',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
