// lib/widgets/bc_checkbox.dart
import 'package:flutter/material.dart';

class BcCheckbox extends StatelessWidget {
  final bool checked;
  final bool indeterminate;
  final ValueChanged<bool>? onChange;

  const BcCheckbox({
    super.key,
    this.checked = false,
    this.indeterminate = false,
    this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChange?.call(!checked),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Icon(
          indeterminate
              ? Icons.indeterminate_check_box
              : checked
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
          size: 24,
          color: Colors.black,
        ),
      ),
    );
  }
}
