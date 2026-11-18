// lib/features/driver_app/driver_pod_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/signature_pad.dart';
import '../../shared/repositories/trip_repository.dart';

class DriverPodScreen extends ConsumerStatefulWidget {
  final String tripId;

  const DriverPodScreen({super.key, required this.tripId});

  @override
  ConsumerState<DriverPodScreen> createState() => _DriverPodScreenState();
}

class _DriverPodScreenState extends ConsumerState<DriverPodScreen> {
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _cargoConditionGood = true;
  bool _sealIntactOnArrival = true;
  Uint8List? _signatureBytes;
  bool _isSealing = false;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(tripRepositoryProvider);
    repo.getTripById(widget.tripId).then((trip) {
      if (trip != null && mounted) {
        setState(() {
          _recipientNameController.text = trip.podRecipientName ?? trip.clientName;
          _recipientPhoneController.text = trip.podRecipientPhone ?? trip.clientPhone;
        });
      }
    });
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitPod() async {
    final name = _recipientNameController.text.trim();
    final phone = _recipientPhoneController.phoneTrim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the recipient consignee name and contact phone.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_signatureBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipient signature is required on glass to confirm delivery.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSealing = true);

    final signatureData = base64Encode(_signatureBytes!);
    final repo = ref.read(tripRepositoryProvider);
    await repo.submitPod(
      widget.tripId,
      recipientName: name,
      recipientPhone: phone,
      signatureData: signatureData,
      photoUrls: ['assets/images/mock_pod_cargo.jpg'],
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSealing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proof of Delivery confirmed! Trip status updated to Delivered.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Proof of Delivery (TRP-04)',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notice card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: Colors.black, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Complete this form in the presence of the receiving party to seal delivery.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Recipient consignee details
            const Text(
              'Receiving Consignee Information *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _recipientNameController,
                    decoration: InputDecoration(
                      labelText: 'Recipient Full Name *',
                      prefixIcon: const Icon(Icons.person, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _recipientPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Recipient Phone Number *',
                      prefixIcon: const Icon(Icons.phone, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Handover conditions check
            const Text(
              'Delivery Condition Verification',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _sealIntactOnArrival,
                    activeThumbColor: AppColors.success,
                    title: const Text(
                      'Cargo seal was intact upon arrival',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    onChanged: (val) => setState(() => _sealIntactOnArrival = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _cargoConditionGood,
                    activeThumbColor: AppColors.success,
                    title: const Text(
                      'Cargo received in good condition (no damage/shortage)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    onChanged: (val) => setState(() => _cargoConditionGood = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Delivery photos
            const Text(
              'Offloaded Cargo Photos',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Photo Attached',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Offloaded items at recipient warehouse',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Colors.black, size: 22),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Recipient Signature Pad
            const Text(
              'Consignee Recipient Signature *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),

            SignaturePadWidget(
              title: 'Recipient Signature on Glass',
              signerRole: 'Consignee / Receiving Agent',
              onSigned: (bytes) {
                setState(() => _signatureBytes = bytes);
              },
            ),

            const SizedBox(height: 18),

            // Notes
            const Text(
              'Delivery Notes / Remarks',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Offloaded at Bay 3. Received by store supervisor.',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isSealing ? null : _submitPod,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSealing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm Delivery & Seal POD',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on TextEditingController {
  String phoneTrim() => text.trim();
}
