import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.labelAr,
    this.labelEn,
    this.onPressed,
    this.isLoading = false,
    this.height = 56,
  });

  final String labelAr;
  final String? labelEn;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final bg = disabled ? AppColors.lightBorder : AppColors.primary;
    final fg = disabled ? AppColors.lightTextSecondary : Colors.white;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Text(
                labelEn == null ? labelAr : '$labelEn / $labelAr',
                textDirection: TextDirection.rtl,
                style: AppTextStyles.buttonLabel.copyWith(color: fg),
              ),
      ),
    );
  }
}

// ── Filled ────────────────────────────────────────────────────────────────────
class _FilledButton extends StatefulWidget {
  const _FilledButton({
    required this.labelAr,
    this.labelEn,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    required this.isLoading,
    required this.height,
    required this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String labelAr;
  final String? labelEn;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<_FilledButton> createState() => _FilledButtonState();
}

class _FilledButtonState extends State<_FilledButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.foregroundColor ?? AppColors.white;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: widget.height,
        transform: Matrix4.identity()
          ..scale(_pressed ? 0.97 : 1.0, _pressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: widget.backgroundColor == null
              ? LinearGradient(
                  colors: _pressed
                      ? [AppColors.primaryDark, AppColors.primary]
                      : [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: widget.backgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null && !widget.isLoading) ...[
                IconTheme(
                  data: IconThemeData(color: fgColor, size: 22),
                  child: widget.icon!,
                ),
                const SizedBox(width: 10),
              ],
              if (widget.isLoading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  ),
                )
              else
                _ButtonLabel(
                  labelAr: widget.labelAr,
                  labelEn: widget.labelEn,
                  color: fgColor,
                ),
              if (widget.trailingIcon != null && !widget.isLoading) ...[
                const SizedBox(width: 10),
                IconTheme(
                  data: IconThemeData(color: fgColor, size: 20),
                  child: widget.trailingIcon!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Outlined ─────────────────────────────────────────────────────────────────
class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({
    required this.labelAr,
    this.labelEn,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    required this.isLoading,
    required this.height,
    required this.borderRadius,
    required this.foregroundColor,
  });

  final String labelAr;
  final String? labelEn;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: BorderSide(color: foregroundColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    IconTheme(
                      data: IconThemeData(color: foregroundColor, size: 22),
                      child: icon!,
                    ),
                    const SizedBox(width: 10),
                  ],
                  _ButtonLabel(
                    labelAr: labelAr,
                    labelEn: labelEn,
                    color: foregroundColor,
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 10),
                    IconTheme(
                      data: IconThemeData(color: foregroundColor, size: 20),
                      child: trailingIcon!,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ── Text Button ───────────────────────────────────────────────────────────────
class _TextButtonWidget extends StatelessWidget {
  const _TextButtonWidget({
    required this.labelAr,
    this.labelEn,
    this.onPressed,
    required this.isLoading,
    required this.foregroundColor,
  });

  final String labelAr;
  final String? labelEn;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: _ButtonLabel(
        labelAr: labelAr,
        labelEn: labelEn,
        color: foregroundColor,
      ),
    );
  }
}

// ── Label helper ──────────────────────────────────────────────────────────────
class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({
    required this.labelAr,
    this.labelEn,
    required this.color,
  });

  final String labelAr;
  final String? labelEn;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (labelEn != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            labelEn!,
            style: AppTextStyles.buttonLabel.copyWith(
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '/ $labelAr',
            style: AppTextStyles.buttonLabel.copyWith(
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      );
    }
    return Text(
      labelAr,
      style: AppTextStyles.buttonLabel.copyWith(
        color: color,
        fontFamily: 'Cairo',
      ),
    );
  }
}
