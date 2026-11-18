import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';

const requiredInspectionPhotoSlots = [
  'Front',
  'Rear',
  'Left',
  'Right',
  'Interior',
  'Odometer',
  'Fuel gauge',
];

class PhotoCaptureGrid extends StatefulWidget {
  const PhotoCaptureGrid({
    super.key,
    required this.photos,
    required this.onChanged,
    this.requiredSlots = requiredInspectionPhotoSlots,
  });

  final Map<String, String> photos;
  final ValueChanged<Map<String, String>> onChanged;
  final List<String> requiredSlots;

  @override
  State<PhotoCaptureGrid> createState() => _PhotoCaptureGridState();
}

class _PhotoCaptureGridState extends State<PhotoCaptureGrid> {
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;

  Future<void> _capture(String slot, ImageSource source) async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 65,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (file == null || !mounted) return;

      final imageData = base64Encode(await file.readAsBytes());
      widget.onChanged({...widget.photos, slot: imageData});
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message == null || error.message!.isEmpty
                  ? 'Could not open the camera or photo library.'
                  : 'Could not capture photo: ${error.message}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _remove(String slot) {
    final nextPhotos = Map<String, String>.from(widget.photos)..remove(slot);
    widget.onChanged(nextPhotos);
  }

  @override
  Widget build(BuildContext context) {
    final capturedCount = widget.requiredSlots
        .where((slot) => widget.photos.containsKey(slot))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$capturedCount / ${widget.requiredSlots.length} required photos',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.requiredSlots.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final slot = widget.requiredSlots[index];
            final data = widget.photos[slot];
            return Semantics(
              label: '$slot photo${data == null ? ', required' : ', captured'}',
              child: InkWell(
                onTap: _isCapturing
                    ? null
                    : () => _capture(slot, ImageSource.camera),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: data == null
                          ? AppColors.cardBorder
                          : AppColors.vehicleAvailable,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (data != null)
                        Image.memory(
                          base64Decode(data),
                          fit: BoxFit.cover,
                        )
                      else
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.black,
                              size: 26,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              slot,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Tap to capture',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      if (data == null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            tooltip: 'Choose $slot photo from library',
                            onPressed: _isCapturing
                                ? null
                                : () => _capture(slot, ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      if (data != null)
                        Positioned(
                          left: 6,
                          right: 6,
                          bottom: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              child: Text(
                                slot,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (data != null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            tooltip: 'Retake $slot photo',
                            onPressed: _isCapturing
                                ? null
                                : () => _remove(slot),
                            icon: const Icon(Icons.refresh),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (_isCapturing) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}
