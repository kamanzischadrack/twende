// lib/widgets/bc_time_picker.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'bc_date_picker.dart' show BcPickerSize;
export 'bc_date_picker.dart' show BcPickerSize;

class BcTimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?>? onChange;
  final bool error;
  final String? helperText;
  final BcPickerSize size;
  final bool readOnly;
  final bool hideClearButton;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const BcTimePicker({
    super.key,
    required this.label,
    this.value,
    this.onChange,
    this.error = false,
    this.helperText,
    this.size = BcPickerSize.normal,
    this.readOnly = false,
    this.hideClearButton = false,
    this.margin,
    this.backgroundColor,
  });

  Future<void> _selectTime(BuildContext context) async {
    if (readOnly) return;

    final initial = value ?? const TimeOfDay(hour: 10, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChange?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = size == BcPickerSize.small;
    final height = isSmall ? 38.0 : 55.0;
    final fontSize = isSmall ? 13.0 : 16.0;
    final hasValue = value != null;
    final bg = backgroundColor ?? AppColors.screenBackground;

    final borderColor = error
        ? AppColors.error
        : Colors.black.withValues(alpha: 0.23);

    String formattedText = label;
    if (hasValue) {
      final hour = value!.hour.toString().padLeft(2, '0');
      final minute = value!.minute.toString().padLeft(2, '0');
      formattedText = '$hour:$minute';
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Box
              InkWell(
                onTap: readOnly ? null : () => _selectTime(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 10 : 15,
                    vertical: isSmall ? 4 : 15,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formattedText,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: hasValue
                                ? Colors.black87
                                : Colors.black.withValues(alpha: 0.38),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!readOnly && hasValue && !hideClearButton)
                        GestureDetector(
                          onTap: () => onChange?.call(null),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Floating Label when time is picked
              if (hasValue)
                Positioned(
                  top: -8,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    color: bg,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: error
                            ? AppColors.error
                            : Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Helper / Error Text
          if (helperText != null && helperText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 5, top: 4),
              child: Text(
                helperText!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: error
                      ? AppColors.error
                      : Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
