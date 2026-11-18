// lib/widgets/bc_error.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class BcError extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry? margin;

  const BcError({
    super.key,
    required this.message,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(top: 15),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 13,
        ),
      ),
    );
  }
}
