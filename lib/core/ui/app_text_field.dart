import 'package:flutter/material.dart';

/// Standard text input field for MVP screens.
/// Uses [ThemeData.inputDecorationTheme] for base styling.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
