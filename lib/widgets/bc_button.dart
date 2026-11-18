// lib/widgets/bc_button.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum BcButtonSize { small, normal }

class BcButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPress;
  final BcButtonSize size;
  final Color? color;
  final bool isSecondary;
  final bool isLoading;
  final EdgeInsetsGeometry? margin;
  final double? width;

  const BcButton({
    super.key,
    required this.label,
    this.onPress,
    this.size = BcButtonSize.normal,
    this.color,
    this.isSecondary = false,
    this.isLoading = false,
    this.margin,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = size == BcButtonSize.small;
    final buttonHeight = isSmall ? 38.0 : 55.0;
    final fontSize = isSmall ? 14.0 : 17.0;

    final bgColor = isSecondary
        ? AppColors.greyButton
        : (color ?? AppColors.primary);

    return Container(
      width: width,
      constraints: const BoxConstraints(maxWidth: 480),
      margin: margin,
      child: SizedBox(
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPress,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            disabledBackgroundColor: bgColor.withValues(alpha: 0.6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
