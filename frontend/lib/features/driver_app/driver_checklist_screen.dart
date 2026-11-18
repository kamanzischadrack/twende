// lib/features/driver_app/driver_checklist_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/repositories/trip_repository.dart';

class DriverChecklistScreen extends ConsumerStatefulWidget {
  final String tripId;

  const DriverChecklistScreen({super.key, required this.tripId});

  @override
  ConsumerState<DriverChecklistScreen> createState() => _DriverChecklistScreenState();
}

class _DriverChecklistScreenState extends ConsumerState<DriverChecklistScreen> {
  final _sealController = TextEditingController();
  bool _weightConfirmed = false;
  bool _isSaving = false;

  final Map<String, bool> _checklist = {
    'Headlights, brake lights & turn indicators working': true,
    'Tyres inspected, tread depth and pressure OK': true,
    'Engine oil, coolant, and brake fluid levels normal': true,
    'Windshield, mirrors, and wipers clean and intact': true,
    'Load secured with safety straps and tarpaulin': true,
    'Fire extinguisher and emergency reflective triangles on board': true,
    'Cargo seal intact and matches shipping manifest': true,
  };

  @override
  void initState() {
    super.initState();
    final repo = ref.read(tripRepositoryProvider);
    repo.getTripById(widget.tripId).then((trip) {
      if (trip != null && mounted) {
        setState(() {
          _sealController.text = trip.sealNumber;
          _weightConfirmed = trip.checklistCompleted;
        });
      }
    });
  }

  @override
  void dispose() {
    _sealController.dispose();
    super.dispose();
  }

  bool get _allChecked =>
      _checklist.values.every((val) => val) &&
      _weightConfirmed &&
      _sealController.text.trim().isNotEmpty;

  Future<void> _submitChecklist() async {
    if (!_allChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check all inspection items and confirm the cargo seal number.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final repo = ref.read(tripRepositoryProvider);
    await repo.submitPreTripChecklist(
      widget.tripId,
      sealNumber: _sealController.text.trim(),
      photos: ['assets/images/mock_cargo_inspection.jpg'],
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pre-trip checklist completed! Trip status moved to In Progress.'),
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
          'Pre-Trip Walkaround (TRP-03)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
                color: const Color(0xFFFEEEE4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.black, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mandatory safety check before driving. Inspect all vehicle and cargo components thoroughly.',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Inspection Checklist',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),

            // Checklist items
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: _checklist.keys.map((item) {
                  final isChecked = _checklist[item] ?? false;
                  return CheckboxListTile(
                    value: isChecked,
                    activeColor: AppColors.primary,
                    dense: true,
                    title: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                        color: isChecked ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _checklist[item] = val ?? false;
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // Cargo Seal & Weight verification
            const Text(
              'Cargo Security & Manifest',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Container / Cargo Seal Number *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _sealController,
                    decoration: InputDecoration(
                      hintText: 'e.g. RW-SEAL-88902',
                      prefixIcon: const Icon(Icons.lock_clock, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _weightConfirmed,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'I confirm the cargo weight does not exceed the vehicle gross payload limit (TRP-03).',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onChanged: (val) => setState(() => _weightConfirmed = val ?? false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Photos Slot
            const Text(
              'Inspection Photos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),

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
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pre-trip Photo Captured',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Load tie-down & seal visual confirmed',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Colors.black, size: 22),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isSaving ? null : _submitChecklist,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Complete Pre-Trip Check & Start Trip',
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
