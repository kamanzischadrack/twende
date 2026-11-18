// lib/widgets/bc_link.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class BcLink extends StatelessWidget {
  final String label;
  final VoidCallback? onPress;
  final EdgeInsetsGeometry? margin;
  final TextStyle? textStyle;

  const BcLink({
    super.key,
    required this.label,
    this.onPress,
    this.margin,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(10),
      child: InkWell(
        onTap: onPress,
        child: Text(
          label,
          style: (textStyle ?? const TextStyle()).copyWith(
            color: AppColors.badgeBlue,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.badgeBlue,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
