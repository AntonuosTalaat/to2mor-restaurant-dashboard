import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String? label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? hintText;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines; // 👈 جديد

  const InputField({
    Key? key,
    this.label,
    this.obscureText = false,
    this.keyboardType,
    this.controller,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.hintText,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1, // 👈 default
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null && label!.isNotEmpty)
          Text(
            label!,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),

        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: obscureText ? 1 : maxLines, // 👈 مهم: لو obscure لازم يفضل 1
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2,
              ),
            ),
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            prefixIconColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
