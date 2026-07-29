import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class IQButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final bool isOutlined;

  const IQButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.textColor = Colors.black,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(30),
          border: isOutlined ? Border.all(color: Colors.white.withOpacity(0.5), width: 1.5) : null,
          boxShadow: !isOutlined ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isOutlined ? Colors.white : textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class IQTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isPhone;
  final Widget? suffixIcon;

  const IQTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isPhone = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6), fontWeight: FontWeight.normal),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

class IQPhoneInput extends StatelessWidget {
  final TextEditingController? controller;
  const IQPhoneInput({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network('https://flagcdn.com/w40/iq.png', width: 24),
              ),
              const SizedBox(width: 8),
              const Text('+964', style: TextStyle(fontWeight: FontWeight.bold)),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '07xx xxxx xxx',
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class IQUploadBox extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const IQUploadBox({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: Colors.black.withOpacity(0.6), fontWeight: FontWeight.normal),
          ),
        ),
      ),
    );
  }
}
