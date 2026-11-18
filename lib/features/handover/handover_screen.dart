import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routing/twende_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/damage_diagram.dart';
import '../../core/widgets/photo_capture_grid.dart';
import '../../core/widgets/signature_pad.dart';
import '../../core/widgets/step_wizard.dart';
import '../../core/widgets/sync_status_bar.dart';
import '../../shared/repositories/store_finance_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../widgets/app_header.dart';

class HandoverScreen extends ConsumerStatefulWidget {
  final String contractId;

  const HandoverScreen({super.key, required this.contractId});

  @override
  ConsumerState<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends ConsumerState<HandoverScreen> {
  // Step 1: Preconditions
  bool _licenceVerified = false;
  bool _depositPaid = false;
  bool _identityConfirmed = false;

  // Step 2: Vehicle Checklist
  final Map<String, bool> _checklist = {
    'Exterior Body & Paint': false,
    'Interior Seats & Mats': false,
    'Tyres & Spare Wheel': false,
    'Headlights, Indicators & Brake Lights': false,
    'Air Conditioning & Entertainment': false,
    'First Aid Kit & Warning Triangle': false,
    'Jack, Wheel Spanner & Tools': false,
    'Original Insurance & Registration Card': false,
  };

  // Step 3: Odometer & Fuel
  final TextEditingController _odometerController = TextEditingController(text: '28400');
  double _fuelFraction = 1.0; // 8/8 full

  // Step 4: Damage Marks
  List<DamageMark> _damageMarks = [];

  // Step 5: Signatures
  bool _isSigned = false;
  String? _signatureData;
  Map<String, String> _photos = {};

  @override
  void dispose() {
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _submitHandover() async {
    final contractRepo = ref.read(contractRepositoryProvider);
    final contract = await contractRepo.getContractById(widget.contractId);
    if (contract == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The contract could not be found.')),
        );
      }
      return;
    }

    final inspection = TwendeInspection(
      id: 'insp_ho_${DateTime.now().millisecondsSinceEpoch}',
      contractId: widget.contractId,
      vehicleId: contract.vehicleId,
      inspectionType: 'handover',
      odometerKm: int.tryParse(_odometerController.text) ?? 28400,
      fuelFraction: _fuelFraction,
      checklist: _checklist,
      damages: _damageMarks.map((m) => {
        'x': m.x,
        'y': m.y,
        'severity': m.severity.name,
        'desc': m.description,
      }).toList(),
      photoUrls: _photos.entries
          .map((entry) => 'data:image/jpeg;base64,${entry.value}')
          .toList(),
      signatureData: _signatureData,
      inspectorName: 'Field Inspector (Aline Uwera)',
      createdAt: DateTime.now(),
    );

    final submitted = await contractRepo.submitInspection(inspection);

    if (mounted && submitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Handover inspection completed successfully! Contract is now Active.')),
      );
      context.go(TwendeRoutes.dashboard);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The handover could not be saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(
        title: AppStrings.t('HANDOVER'),
      ),
      body: Column(
        children: [
          const SyncStatusBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: StepWizard(
                steps: [
                // STEP 1: Preconditions
                WizardStep(
                  title: 'Pre-checks',
                  subtitle: 'Eligibility & Deposit verification',
                  canProceed: () => _licenceVerified && _depositPaid && _identityConfirmed,
                  content: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pre-Handover Verification (BR-04)',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'All items must be physically verified before releasing the vehicle keys.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Physical Driver Licence presented, checked & valid', style: TextStyle(fontSize: 13)),
                          value: _licenceVerified,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _licenceVerified = val ?? false),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Caution / Security Deposit receipt confirmed in system', style: TextStyle(fontSize: 13)),
                          value: _depositPaid,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _depositPaid = val ?? false),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Customer Identity photo matched with National ID / Passport', style: TextStyle(fontSize: 13)),
                          value: _identityConfirmed,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _identityConfirmed = val ?? false),
                        ),
                      ],
                    ),
                  ),
                ),

                // STEP 2: Physical Checklist
                WizardStep(
                  title: 'Checklist',
                  subtitle: 'Vehicle equipment & condition',
                  canProceed: () => _checklist.values.every((checked) => checked),
                  blockMessage: 'Complete every vehicle checklist item before continuing.',
                  content: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '360° Inspection Checklist',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Verify each item with the customer during walk-around.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        ..._checklist.keys.map((item) {
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item, style: const TextStyle(fontSize: 13)),
                            value: _checklist[item] ?? false,
                            activeColor: AppColors.primary,
                            onChanged: (val) => setState(() => _checklist[item] = val ?? false),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // STEP 3: Odometer & Fuel Level
                WizardStep(
                  title: 'Telematics',
                  subtitle: 'Odometer & Fuel status',
                  canProceed: () => int.tryParse(_odometerController.text) != null,
                  content: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Odometer & Fuel Reading',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _odometerController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Current Odometer (km) *',
                            prefixIcon: Icon(Icons.speed, color: Colors.black),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Fuel Level at Handover:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(
                              '${(_fuelFraction * 8).round()}/8 (${(_fuelFraction * 100).round()}%)',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
                            ),
                          ],
                        ),
                        Slider(
                          value: _fuelFraction,
                          min: 0.0,
                          max: 1.0,
                          divisions: 8,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _fuelFraction = val),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Empty (0/8)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text('Half (4/8)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text('Full (8/8)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // STEP 4: Damage Diagram Canvas
                WizardStep(
                  title: 'Damages',
                  subtitle: 'Mark preexisting scratches',
                  content: DamageDiagramWidget(
                    marks: _damageMarks,
                    onMarksChanged: (marks) => setState(() => _damageMarks = marks),
                  ),
                ),

                // STEP 5: Signatures & Seal
                WizardStep(
                  title: 'Photos',
                  subtitle: 'Capture all seven required inspection views',
                  canProceed: () => requiredInspectionPhotoSlots
                      .every((slot) => _photos.containsKey(slot)),
                  blockMessage: 'Capture all seven required photos before continuing.',
                  content: PhotoCaptureGrid(
                    photos: _photos,
                    onChanged: (photos) => setState(() => _photos = photos),
                  ),
                ),

                // STEP 6: Signature
                WizardStep(
                  title: 'Sign-off',
                  subtitle: 'Customer signature',
                  canProceed: () => _isSigned,
                  content: Column(
                    children: [
                      SignaturePadWidget(
                        title: 'Hirer / Customer Acknowledgement',
                        signerRole: 'I confirm that the vehicle condition, odometer, and fuel level recorded are accurate.',
                        onSigned: (bytes) {
                          setState(() {
                            _isSigned = bytes != null;
                            _signatureData =
                                bytes == null ? null : base64Encode(bytes);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_isSigned)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.black, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Signature captured and locked. Ready to dispatch.',
                                  style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                ],
                onComplete: _submitHandover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
