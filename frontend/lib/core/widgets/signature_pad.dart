import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../theme/app_colors.dart';

/// Signature capture widget for Handover / Return inspection sign-offs
class SignaturePadWidget extends StatefulWidget {
  final String title;
  final String signerRole; // e.g. "Customer Signature" or "Agent Signature"
  final ValueChanged<Uint8List?>? onSigned;
  final bool readOnly;

  const SignaturePadWidget({
    super.key,
    required this.title,
    this.signerRole = 'Customer / Authorized Driver',
    this.onSigned,
    this.readOnly = false,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  late final SignatureController _controller;
  bool _hasSigned = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    _controller.addListener(() {
      final isNotEmpty = _controller.isNotEmpty;
      if (isNotEmpty != _hasSigned) {
        setState(() => _hasSigned = isNotEmpty);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _exportSignature() async {
    if (_controller.isNotEmpty) {
      final bytes = await _controller.toPngBytes();
      widget.onSigned?.call(bytes);
    }
  }

  void _clear() {
    _controller.clear();
    widget.onSigned?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              if (!widget.readOnly && _hasSigned) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clear,
                  child: const Text('Clear / Redo', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ],
          ),
          Text(
            widget.signerRole,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Stack(
                children: [
                  Signature(
                    controller: _controller,
                    height: 150,
                    backgroundColor: Colors.transparent,
                  ),
                  if (!_hasSigned && !widget.readOnly)
                    const Center(
                      child: Text(
                        'Sign here with finger or stylus',
                        style: TextStyle(color: Colors.black26, fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ),
                  Positioned(
                    bottom: 25,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 1,
                      color: Colors.black12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.readOnly && _hasSigned) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 36),
                ),
                onPressed: _exportSignature,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Confirm Signature'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
