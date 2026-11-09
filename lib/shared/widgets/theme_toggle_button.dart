// theme_toggle_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/cubit/theme_cubit.dart';
import '../../core/theme/cubit/theme_state.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final isDark = state.isDark;

        return GestureDetector(
          onTap: () => context.read<ThemeCubit>().toggleTheme(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 56,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark ? AppColors.primary : AppColors.lightBorder,
            ),
            child: Stack(
              children: [
                // ── Icons ────────────────────────────────
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        Icons.wb_sunny_rounded,
                        size: 14,
                        color: isDark
                            ? Colors.white.withOpacity(0.4)
                            : AppColors.gold,
                      ),
                      Icon(
                        Icons.nightlight_round,
                        size: 14,
                        color: isDark
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    ],
                  ),
                ),

                // ── Thumb ────────────────────────────────
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: isDark ? 30 : 2,
                  top: 2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
