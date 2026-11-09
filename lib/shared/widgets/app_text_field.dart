import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.enabled = true,
    this.readOnly = false,
    this.textDirection,
    this.minLines,
    this.maxLines = 1,
    this.isDense,
    this.inputFormatters,
    this.onChanged,
    this.border = const OutlineInputBorder(),
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool showPasswordToggle;
  final bool enabled;
  final bool readOnly;
  final TextDirection? textDirection;
  final int? minLines;
  final int? maxLines;
  final bool? isDense;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final InputBorder border;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscure = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final suffix = widget.showPasswordToggle
        ? IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          )
        : (widget.suffixIcon == null ? null : Icon(widget.suffixIcon));

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textDirection: widget.textDirection,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        border: widget.border,
        isDense: widget.isDense,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: suffix,
      ),
    );
  }
}

