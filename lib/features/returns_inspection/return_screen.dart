import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/session_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routing/twende_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/approval_banner.dart';
import '../../core/widgets/damage_diagram.dart';
import '../../core/widgets/photo_capture_grid.dart';
import '../../core/widgets/signature_pad.dart';
import '../../core/widgets/step_wizard.dart';
import '../../core/widgets/sync_status_bar.dart';
import '../../shared/domain/enums.dart';
import '../../shared/domain/reconciliation.dart';
import '../../shared/domain/validation_rules.dart';
import '../../shared/repositories/store_finance_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../widgets/app_header.dart';

class ReturnScreen extends ConsumerStatefulWidget {
  final String contractId;

  const ReturnScreen({super.key, required this.contractId});

  @override
  ConsumerState<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends ConsumerState<ReturnScreen> {
  // Baseline handover telemetry
  final int _startOdometer = 28400;
  final double _handoverFuel = 1.0;

  // Return telemetry entries
  final TextEditingController _returnOdometerController = TextEditingController(text: '28950'); // 550 km driven
  double _returnFuelFraction = 0.75; // 6/8 -> 2/8 shortage
  List<DamageMark> _newDamages = [];
  bool _isSigned = false;
  String? _signatureData;
  Map<String, String> _photos = {};

  @override
  void dispose() {
    _returnOdometerController.dispose();
    super.dispose();
  }

  ReconciliationSummary _computeReconciliation(TwendeContract contract) {
    final returnKm = int.tryParse(_returnOdometerController.text) ?? _startOdometer;
    final tenant = ref.watch(tenantConfigProvider);

    final lateReturn = ReconciliationEngine.calculateLateReturn(
      scheduledReturn: contract.returnDateTime,
      actualReturn: DateTime.now(),
      dailyRate: 120000.0,
      graceMinutes: tenant.lateReturnGraceMinutes,
    );

    final excessMileage = ReconciliationEngine.calculateExcessMileage(
      startOdometerKm: _startOdometer,
      returnOdometerKm: returnKm,
      billableDays: 3,
      dailyAllowanceKm: tenant.defaultDailyMileageAllowanceKm,
      ratePerExcessKm: 250.0,
    );

    final fuel = ReconciliationEngine.calculateFuel(
      handoverFraction: _handoverFuel,
      returnFraction: _returnFuelFraction,
      tankCapacityLitres: 65.0,
      fuelPricePerLitre: 1650.0,
      refuelAdminFee: 5000.0,
    );

    return ReconciliationEngine.reconcile(
      lateReturn: lateReturn,
      excessMileage: excessMileage,
      fuel: fuel,
      newDamageCharges: _newDamages.length * 40000.0,
      depositHeld: contract.depositAmount,
    );
  }

  Future<void> _submitReturn() async {
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
      id: 'insp_ret_${DateTime.now().millisecondsSinceEpoch}',
      contractId: widget.contractId,
      vehicleId: contract.vehicleId,
      inspectionType: 'return',
      odometerKm: int.tryParse(_returnOdometerController.text) ?? 28950,
      fuelFraction: _returnFuelFraction,
      checklist: {'All checked': true},
      damages: _newDamages.map((m) => {
        'x': m.x,
        'y': m.y,
        'severity': m.severity.name,
        'desc': m.description,
      }).toList(),
      photoUrls: _photos.entries
          .map((entry) => 'data:image/jpeg;base64,${entry.value}')
          .toList(),
      signatureData: _signatureData,
      inspectorName: 'Return Inspector (Clarisse Mukamana)',
      createdAt: DateTime.now(),
    );

    final submitted = await contractRepo.submitInspection(inspection);

    if (mounted && submitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return inspection confirmed! Reconciliation invoice generated.')),
      );
      context.go(TwendeRoutes.dashboard);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The return could not be saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractRepo = ref.watch(contractRepositoryProvider);
    final tenant = ref.watch(tenantConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(
        title: AppStrings.t('RETURN'),
      ),
      body: FutureBuilder<TwendeContract?>(
        future: contractRepo.getContractById(widget.contractId),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final contract = snapshot.data ?? TwendeContract(
            id: widget.contractId,
            contractNumber: 'CNT-2026-0039',
            customerId: 'cust_01',
            customerName: 'Jean-Paul Mugisha',
            vehicleId: 'veh_01',
            vehicleName: 'Toyota Land Cruiser Prado',
            vehiclePlate: 'RAC 452 K',
            pickupDateTime: DateTime.now().subtract(const Duration(days: 3)),
            returnDateTime: DateTime.now().subtract(const Duration(hours: 2)), // Overdue by 2h!
            status: ContractStatus.active,
            totalAmount: 360000.0,
            depositAmount: tenant.defaultDepositAmount,
            balanceDue: 0.0,
          );

          final currentOdo = int.tryParse(_returnOdometerController.text) ?? _startOdometer;
          final mileageCheck = ValidationRules.checkMileage(
            startKm: _startOdometer,
            returnKm: currentOdo,
          );

          final recon = _computeReconciliation(contract);

          return Column(
            children: [
              const SyncStatusBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: StepWizard(
                    steps: [
                    // STEP 1: Odometer & Fuel Check
                    WizardStep(
                      title: 'Readings',
                      subtitle: 'Return odometer & fuel',
                      canProceed: () => mileageCheck.isValid,
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
                              'Return Telematics Entry (BR-06)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Handover Odometer: $_startOdometer km • Handover Fuel: ${(_handoverFuel * 8).round()}/8',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _returnOdometerController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Return Odometer Reading (km) *',
                                prefixIcon: const Icon(Icons.speed, color: Colors.black),
                                border: const OutlineInputBorder(),
                                errorText: mileageCheck.isValid ? null : mileageCheck.errorMessage,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Return Fuel Level:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(
                                  '${(_returnFuelFraction * 8).round()}/8 (${(_returnFuelFraction * 100).round()}%)',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
                                ),
                              ],
                            ),
                            Slider(
                              value: _returnFuelFraction,
                              min: 0.0,
                              max: 1.0,
                              divisions: 8,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _returnFuelFraction = val),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Required photo evidence before assessing condition.
                    WizardStep(
                      title: 'Photos',
                      subtitle: 'Capture all seven required inspection views',
                      canProceed: () => requiredInspectionPhotoSlots
                          .every((slot) => _photos.containsKey(slot)),
                      blockMessage:
                          'Capture all seven required photos before continuing.',
                      content: PhotoCaptureGrid(
                        photos: _photos,
                        onChanged: (photos) =>
                            setState(() => _photos = photos),
                      ),
                    ),

                    // STEP 2: New Damage Assessment
                    WizardStep(
                      title: 'Condition',
                      subtitle: 'Walkaround & new damage',
                      content: DamageDiagramWidget(
                        marks: _newDamages,
                        onMarksChanged: (marks) => setState(() => _newDamages = marks),
                      ),
                    ),

                    // STEP 3: Automated Financial Reconciliation Preview
                    WizardStep(
                      title: 'Reconcile',
                      subtitle: 'Fees & deposit settlement',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (recon.requiresRefundApproval) ...[
                            ApprovalBanner(
                              count: 1,
                              message: recon.refundApprovalReason ?? 'Caution refund exceeds supervisor threshold.',
                            ),
                            const SizedBox(height: 12),
                          ],
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Return Reconciliation Preview',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        AppStrings.t('ESTIMATE_LABEL'),
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 8),

                                // Late return line
                                _buildChargeRow(
                                  'Late Return (${recon.lateReturn.description})',
                                  recon.lateReturn.lateFee,
                                  isHighlight: recon.lateReturn.lateFee > 0,
                                ),
                                const SizedBox(height: 4),

                                // Excess mileage line
                                _buildChargeRow(
                                  'Excess Mileage (${recon.excessMileage.description})',
                                  recon.excessMileage.fee,
                                  isHighlight: recon.excessMileage.fee > 0,
                                ),
                                const SizedBox(height: 4),

                                // Fuel shortage line
                                _buildChargeRow(
                                  'Fuel Discrepancy (${recon.fuel.description})',
                                  recon.fuel.fuelCharge,
                                  isHighlight: recon.fuel.fuelCharge > 0,
                                ),
                                const SizedBox(height: 4),

                                // Damages line
                                if (recon.newDamageCharges > 0) ...[
                                  _buildChargeRow(
                                    'New Damages (${_newDamages.length} item(s) logged)',
                                    recon.newDamageCharges,
                                    isHighlight: true,
                                  ),
                                  const SizedBox(height: 4),
                                ],

                                const Divider(height: 12),
                                _buildChargeRow('Total Extra Charges', recon.totalAdditionalCharges, isBold: true),
                                const SizedBox(height: 4),
                                _buildChargeRow('Caution Deposit Held', -recon.depositHeld, isGreen: true),
                                const Divider(height: 16),

                                if (recon.balanceDue > 0)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Customer Balance Due (To Pay)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      Text(
                                        MoneyUtils.format(recon.balanceDue),
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.error),
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Deposit Refund to Customer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      Text(
                                        MoneyUtils.format(recon.refundDue),
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.green.shade800),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // STEP 4: Final Sign-off
                    WizardStep(
                      title: 'Finalize',
                      subtitle: 'Inspector & Hirer signatures',
                      canProceed: () => _isSigned,
                      content: Column(
                        children: [
                          SignaturePadWidget(
                            title: 'Return Closure Sign-off',
                            signerRole: 'Customer & Inspector Acknowledgement',
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
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.black, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Return sign-off captured. Ready to lock contract & generate invoice.',
                                      style: TextStyle(fontSize: 12, color: Colors.green.shade900, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    ],
                    onComplete: _submitReturn,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChargeRow(String label, double amount, {bool isHighlight = false, bool isBold = false, bool isGreen = false}) {
    Color col = AppColors.textPrimary;
    if (isHighlight) col = AppColors.error;
    if (isGreen) col = Colors.green.shade800;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.w700 : FontWeight.normal))),
        Text(
          MoneyUtils.format(amount),
          style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.w700 : FontWeight.w600, color: col),
        ),
      ],
    );
  }
}
