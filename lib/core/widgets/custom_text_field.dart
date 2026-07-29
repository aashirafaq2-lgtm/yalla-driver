import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final Widget? prefix;
  final Widget? suffix;

  const CustomTextField({
    super.key,
    required this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.35),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: prefix,
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        ),
      ),
    );
  }
}
