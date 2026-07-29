import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final bool isOutlined;

  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.lightImpact(),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: isOutlined
            ? OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: isLoading ? null : onPressed,
                child: _buildChild(),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor ?? Colors.white,
                  foregroundColor: textColor ?? Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.1),
                ),
                onPressed: isLoading ? null : onPressed,
                child: _buildChild(),
              ),
      ),
    );
  }

  Widget _buildChild() {
    return isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: textColor ?? Colors.black,
              strokeWidth: 2,
            ),
          )
        : Text(
            label,
            style: TextStyle(
              color: textColor ?? Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          );
  }
}
