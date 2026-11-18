import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../shared/domain/enums.dart';

/// Single damage mark point on vehicle diagram
class DamageMark {
  final double x; // Relative coordinate (0.0 to 1.0)
  final double y; // Relative coordinate (0.0 to 1.0)
  final DamageSeverity severity;
  final String description;
  final String? photoPath;

  const DamageMark({
    required this.x,
    required this.y,
    this.severity = DamageSeverity.minor,
    this.description = '',
    this.photoPath,
  });

  DamageMark copyWith({
    double? x,
    double? y,
    DamageSeverity? severity,
    String? description,
    String? photoPath,
  }) {
    return DamageMark(
      x: x ?? this.x,
      y: y ?? this.y,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

/// Interactive Car Damage Diagram Annotation Canvas
class DamageDiagramWidget extends StatefulWidget {
  final List<DamageMark> marks;
  final ValueChanged<List<DamageMark>>? onMarksChanged;
  final bool readOnly;

  const DamageDiagramWidget({
    super.key,
    required this.marks,
    this.onMarksChanged,
    this.readOnly = false,
  });

  @override
  State<DamageDiagramWidget> createState() => _DamageDiagramWidgetState();
}

class _DamageDiagramWidgetState extends State<DamageDiagramWidget> {
  late List<DamageMark> _currentMarks;

  @override
  void initState() {
    super.initState();
    _currentMarks = List.from(widget.marks);
  }

  @override
  void didUpdateWidget(covariant DamageDiagramWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marks != widget.marks) {
      _currentMarks = List.from(widget.marks);
    }
  }

  void _handleTap(TapUpDetails details, BoxConstraints constraints) {
    if (widget.readOnly) return;

    final localPos = details.localPosition;
    final relX = (localPos.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final relY = (localPos.dy / constraints.maxHeight).clamp(0.0, 1.0);

    _showAddDamageDialog(relX, relY);
  }

  void _showAddDamageDialog(double x, double y) {
    DamageSeverity selectedSeverity = DamageSeverity.minor;
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Record Damage / Scratch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Severity Level:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: DamageSeverity.values.map((s) {
                  final isSelected = selectedSeverity == s;
                  return ChoiceChip(
                    label: Text(s.name.toUpperCase()),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    onSelected: (val) {
                      if (val) setDialogState(() => selectedSeverity = s);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (e.g. 5cm scratch on front fender)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final newMark = DamageMark(
                  x: x,
                  y: y,
                  severity: selectedSeverity,
                  description: descController.text.trim().isEmpty ? 'Damage mark' : descController.text.trim(),
                );
                setState(() {
                  _currentMarks.add(newMark);
                });
                widget.onMarksChanged?.call(_currentMarks);
                Navigator.pop(ctx);
              },
              child: const Text('Add Mark'),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(DamageSeverity severity) {
    switch (severity) {
      case DamageSeverity.minor:
        return Colors.amber.shade700;
      case DamageSeverity.moderate:
        return Colors.orange.shade800;
      case DamageSeverity.major:
        return AppColors.error;
      case DamageSeverity.totalLoss:
        return Colors.black;
    }
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
              const Text(
                'Vehicle Inspection Diagram',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              if (!widget.readOnly && _currentMarks.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear Marks'),
                  onPressed: () {
                    setState(() => _currentMarks.clear());
                    widget.onMarksChanged?.call(_currentMarks);
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.readOnly
                ? 'Inspected damage markers are displayed below.'
                : 'Tap anywhere on the vehicle silhouette to mark a scratch, dent, or damage.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final width = constraints.maxWidth;
              final height = (width * 0.55).clamp(200.0, 320.0);

              return GestureDetector(
                onTapUp: (details) => _handleTap(details, BoxConstraints(maxWidth: width, maxHeight: height)),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(width, height),
                      painter: _CarSilhouettePainter(),
                    ),
                    ..._currentMarks.map((m) {
                      return Positioned(
                        left: (m.x * width) - 12,
                        top: (m.y * height) - 12,
                        child: Tooltip(
                          message: '${m.severity.name.toUpperCase()}: ${m.description}',
                          child: GestureDetector(
                            onTap: widget.readOnly
                                ? null
                                : () {
                                    setState(() => _currentMarks.remove(m));
                                    widget.onMarksChanged?.call(_currentMarks);
                                  },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _severityColor(m.severity),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.close, size: 12, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          if (_currentMarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const Text('Recorded Damage Items:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            ..._currentMarks.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final mark = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _severityColor(mark.severity),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '#$idx [${mark.severity.name.toUpperCase()}] ${mark.description}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Custom painter for a top-down and 4-way vehicle silhouette outline
class _CarSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF9F9FB);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)), bgPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFB0B0B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dashPaint = Paint()
      ..color = const Color(0xFFD0D0D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer car body (Top-down view)
    final bodyW = size.width * 0.45;
    final bodyH = size.height * 0.75;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: bodyW, height: bodyH),
      const Radius.circular(35),
    );
    canvas.drawRRect(bodyRect, linePaint);

    // Windshield (Front)
    final windshieldPath = Path()
      ..moveTo(cx - bodyW * 0.35, cy - bodyH * 0.18)
      ..quadraticBezierTo(cx, cy - bodyH * 0.28, cx + bodyW * 0.35, cy - bodyH * 0.18);
    canvas.drawPath(windshieldPath, linePaint);

    // Rear window
    final rearPath = Path()
      ..moveTo(cx - bodyW * 0.35, cy + bodyH * 0.22)
      ..quadraticBezierTo(cx, cy + bodyH * 0.28, cx + bodyW * 0.35, cy + bodyH * 0.22);
    canvas.drawPath(rearPath, linePaint);

    // Roof outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 2), width: bodyW * 0.65, height: bodyH * 0.38),
        const Radius.circular(10),
      ),
      dashPaint,
    );

    // Side mirrors
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - bodyW * 0.54, cy - bodyH * 0.16), width: 12, height: 20),
        const Radius.circular(4),
      ),
      linePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + bodyW * 0.54, cy - bodyH * 0.16), width: 12, height: 20),
        const Radius.circular(4),
      ),
      linePaint,
    );

    // Wheels / Tyres
    void drawTyre(double x, double y) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 14, height: 32), const Radius.circular(4)),
        Paint()..color = const Color(0xFF4A4A52),
      );
    }

    drawTyre(cx - bodyW * 0.52, cy - bodyH * 0.26); // Front Left
    drawTyre(cx + bodyW * 0.52, cy - bodyH * 0.26); // Front Right
    drawTyre(cx - bodyW * 0.52, cy + bodyH * 0.26); // Rear Left
    drawTyre(cx + bodyW * 0.52, cy + bodyH * 0.26); // Rear Right

    // Direction indicators: Front & Rear labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    void drawLabel(String text, double y) {
      textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(color: Color(0xFF888890), fontSize: 11, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(cx - (textPainter.width / 2), y));
    }

    drawLabel('▲ FRONT', cy - bodyH * 0.46);
    drawLabel('▼ REAR', cy + bodyH * 0.38);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
