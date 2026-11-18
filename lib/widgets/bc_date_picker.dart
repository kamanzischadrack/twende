// lib/widgets/bc_date_picker.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';

enum BcPickerSize { small, normal }

class BcDatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChange;
  final bool error;
  final String? helperText;
  final BcPickerSize size;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool readOnly;
  final bool hideClearButton;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  const BcDatePicker({
    super.key,
    required this.label,
    this.value,
    this.onChange,
    this.error = false,
    this.helperText,
    this.size = BcPickerSize.normal,
    this.minDate,
    this.maxDate,
    this.readOnly = false,
    this.hideClearButton = false,
    this.margin,
    this.backgroundColor,
  });

  Future<void> _selectDate(BuildContext context) async {
    if (readOnly) return;

    final initial = value ?? DateTime.now();
    final first = minDate ?? DateTime(1900);
    final last = maxDate ?? DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first)
          ? first
          : initial.isAfter(last)
              ? last
              : initial,
      firstDate: first,
      lastDate: last,
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
      try {
        formattedText = isSmall
            ? DateFormat('EEE, d MMM yyyy').format(value!)
            : DateFormat('EEEE, d MMMM yyyy').format(value!);
      } catch (_) {
        formattedText =
            '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';
      }
      if (formattedText.isNotEmpty) {
        formattedText = formattedText[0].toUpperCase() + formattedText.substring(1);
      }
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
                onTap: readOnly ? null : () => _selectDate(context),
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

              // Floating Label when date is picked
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
