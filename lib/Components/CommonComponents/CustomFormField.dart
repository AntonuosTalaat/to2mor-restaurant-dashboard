import 'package:flutter/material.dart';

class CustomFormField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final Widget? prefixIcon; // Make it nullable
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;

  const CustomFormField({
    super.key,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.prefixIcon, // Now optional
    this.keyboardType,
    this.textDirection,
    this.readOnly = false,
    this.onTap, this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      textDirection: textDirection,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines??1,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon, // Convert IconData to Icon widget
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }
}