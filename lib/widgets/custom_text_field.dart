import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter

class CustomTextField extends StatelessWidget {
  final String labelText;
  final bool obscureText;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool readOnly;
  final int? maxLength;
  final String? hintText;
  final TextInputType? keyboardType; // New parameter
  final List<TextInputFormatter>? inputFormatters; // New parameter

  const CustomTextField({
    super.key,
    required this.labelText,
    this.obscureText = false,
    this.prefixIcon,
    this.controller,
    this.validator,
    this.readOnly = false,
    this.maxLength,
    this.hintText,
    this.keyboardType,
    this.inputFormatters, // Initialize new parameter
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      readOnly: readOnly,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters, // Pass to TextFormField
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.indigo) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        labelStyle: TextStyle(color: Colors.indigo.shade700),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
    );
  }
}
