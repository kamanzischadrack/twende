// lib/widgets/bc_switch.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class BcSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onValueChange;
  final String? label;
  final Widget? child;
  final bool disabled;
  final EdgeInsetsGeometry? margin;
  final TextStyle? textStyle;

  const BcSwitch({
    super.key,
    required this.value,
    this.onValueChange,
    this.label,
    this.child,
    this.disabled = false,
    this.margin,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: disabled ? null : () => onValueChange?.call(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: value,
                onChanged: disabled ? null : onValueChange,
                activeThumbColor: AppColors.primary,
                activeTrackColor: const Color(0xFFF7B68F),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFF9D9D9D),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 8),
              if (label != null)
                Flexible(
                  child: Text(
                    label!,
                    style: textStyle ??
                        const TextStyle(
                          color: Color.fromRGBO(0, 0, 0, 0.7),
                          fontSize: 12,
                        ),
                  ),
                ),
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );
  }
}
