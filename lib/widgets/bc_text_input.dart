// lib/widgets/bc_text_input.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum BcInputSize { small, normal }

class BcTextInput extends StatefulWidget {
  final String? label;
  final String? value;
  final TextEditingController? controller;
  final ValueChanged<String>? onChangeText;
  final VoidCallback? onSubmitEditing;
  final bool secureTextEntry;
  final bool error;
  final String? helperText;
  final BcInputSize size;
  final TextInputType keyboardType;
  final bool readOnly;
  final bool hideClearButton;
  final bool hideLabel;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  final int? maxLength;
  final FocusNode? focusNode;

  const BcTextInput({
    super.key,
    this.label,
    this.value,
    this.controller,
    this.onChangeText,
    this.onSubmitEditing,
    this.secureTextEntry = false,
    this.error = false,
    this.helperText,
    this.size = BcInputSize.normal,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.hideClearButton = false,
    this.hideLabel = false,
    this.backgroundColor,
    this.margin,
    this.maxLength,
    this.focusNode,
  });

  @override
  State<BcTextInput> createState() => _BcTextInputState();
}

class _BcTextInputState extends State<BcTextInput> {
  late TextEditingController _controller;
  bool _isInternalController = false;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.secureTextEntry;
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.value ?? '');
      _isInternalController = true;
    }

    _controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant BcTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value != _controller.text) {
      _controller.text = widget.value!;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = widget.size == BcInputSize.small;
    final height = isSmall ? 37.0 : 55.0;
    final fontSize = isSmall ? 14.0 : 16.0;
    final hasValue = _controller.text.isNotEmpty;
    final bg = widget.backgroundColor ?? AppColors.screenBackground;

    final borderColor = widget.error
        ? AppColors.error
        : Colors.black.withValues(alpha: 0.23);

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Input Box
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: widget.focusNode,
                        readOnly: widget.readOnly,
                        obscureText: _obscureText,
                        keyboardType: widget.keyboardType,
                        maxLength: widget.maxLength,
                        onChanged: widget.onChangeText,
                        onSubmitted: (_) => widget.onSubmitEditing?.call(),
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.label,
                          hintStyle: TextStyle(
                            color: Colors.black.withValues(alpha: 0.38),
                            fontSize: fontSize,
                          ),
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: isSmall ? 8 : 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (widget.secureTextEntry)
                      IconButton(
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36),
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    else if (!widget.readOnly &&
                        hasValue &&
                        !widget.hideClearButton)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          widget.onChangeText?.call('');
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Floating Label when text is present
              if (hasValue && !widget.hideLabel && widget.label != null)
                Positioned(
                  top: -8,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    color: bg,
                    child: Text(
                      widget.label!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: widget.error
                            ? AppColors.error
                            : Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Helper / Error Text
          if (widget.helperText != null && widget.helperText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 5, top: 4),
              child: Text(
                widget.helperText!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: widget.error
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
