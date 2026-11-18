// lib/features/portal/portal_sign_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/signature_pad.dart';
import '../../core/widgets/status_badge.dart';
import '../../shared/domain/enums.dart';
import '../../shared/repositories/store_finance_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';

class PortalSignScreen extends ConsumerStatefulWidget {
  final String token;

  const PortalSignScreen({super.key, required this.token});

  @override
  ConsumerState<PortalSignScreen> createState() => _PortalSignScreenState();
}

class _PortalSignScreenState extends ConsumerState<PortalSignScreen> {
  bool _agreedToTerms = false;
  bool _agreedToInsurance = false;
  bool _agreedToFuelPolicy = false;
  bool _isSigning = false;
  bool _isSignedSuccess = false;
  Uint8List? _signatureBytes;

  @override
  Widget build(BuildContext context) {
    final contractRepo = ref.watch(contractRepositoryProvider);
    final dateFormat = DateFormat('EEE, MMM dd, yyyy HH:mm');

    // Token maps directly to contractId or mock cnt_01
    final contractId = widget.token.startsWith('cnt_') ? widget.token : 'cnt_01';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1B2E), // Twende Navy
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'twende.',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Digital Contract Signing',
              style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: FutureBuilder<TwendeContract?>(
        future: contractRepo.getContractById(contractId),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final contract = snapshot.data;
          if (contract == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_off, size: 48, color: Colors.black),
                  const SizedBox(height: 12),
                  const Text('Signing link expired or invalid.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Please contact Twende Fleet support for a new link.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Return Home'),
                  ),
                ],
              ),
            );
          }

          if (_isSignedSuccess || contract.isSigned) {
            return _buildSuccessState(context, contract);
          }

          final canSubmit = _agreedToTerms && _agreedToInsurance && _agreedToFuelPolicy && _signatureBytes != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Notice Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFB9D5FF)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Colors.black, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Official Twende Rwanda e-Signing Portal. Review the rental agreement clauses below and provide your digital signature to confirm your vehicle reservation.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF003882), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Rental Agreement Summary Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            contract.contractNumber,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0E1B2E)),
                          ),
                          StatusBadge(
                            label: contract.status.label,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hirer: ${contract.customerName}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      _buildDetailRow('Assigned Vehicle', '${contract.vehicleName} (${contract.vehiclePlate})'),
                      const SizedBox(height: 8),
                      _buildDetailRow('Pickup Schedule', dateFormat.format(contract.pickupDateTime)),
                      const SizedBox(height: 8),
                      _buildDetailRow('Scheduled Return', dateFormat.format(contract.returnDateTime)),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Value', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(MoneyUtils.format(contract.totalAmount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Deposit Held', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(MoneyUtils.format(contract.depositAmount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.teal)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Balance Due', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(
                                  MoneyUtils.format(contract.balanceDue),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: contract.balanceDue > 0 ? AppColors.error : Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Terms & Declarations
                const Text(
                  'Legal Terms & Declarations',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0E1B2E)),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: const Text(
                          'I confirm that I possess a valid national/international driver licence and meet all Rwandan traffic requirements.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _agreedToTerms,
                        onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: const Text(
                          'I accept the insurance excess deductible (RWF 250,000) in case of reported accidents or third-party liability.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _agreedToInsurance,
                        onChanged: (val) => setState(() => _agreedToInsurance = val ?? false),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: const Text(
                          'I understand the Full-to-Full fuel policy and agree that missing fuel or excess mileage (>200 km/day) will be debited from my caution deposit.',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _agreedToFuelPolicy,
                        onChanged: (val) => setState(() => _agreedToFuelPolicy = val ?? false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Digital Signature Pad Card
                const Text(
                  'Draw Signature on Glass (CON-01)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0E1B2E)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Use your finger or stylus to sign below. Once confirmed, this contract becomes locked and legally sealed.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _signatureBytes != null ? Colors.green : AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      SignaturePadWidget(
                        title: 'Hirer / Authorized Representative Signature',
                        onSigned: (bytes) {
                          setState(() => _signatureBytes = bytes);
                        },
                      ),
                      if (_signatureBytes != null) ...[
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.black),
                            SizedBox(width: 6),
                            Text('Signature captured successfully', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canSubmit ? AppColors.primary : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: canSubmit ? 2 : 0,
                    ),
                    onPressed: canSubmit && !_isSigning
                        ? () async {
                            setState(() => _isSigning = true);

                            // Submit e-signature inspection to lock and seal contract
                            final inspection = TwendeInspection(
                              id: 'insp_sign_${DateTime.now().millisecondsSinceEpoch}',
                              contractId: contract.id,
                              vehicleId: contract.vehicleId,
                              inspectionType: 'handover',
                              odometerKm: 28400,
                              fuelFraction: 1.0,
                              checklist: const {'licence_verified': true, 'terms_accepted': true},
                              damages: const [],
                              signatureData: base64Encode(_signatureBytes!),
                              inspectorName: contract.customerName,
                              createdAt: DateTime.now(),
                            );

                            await contractRepo.submitInspection(inspection);

                            setState(() {
                              _isSigning = false;
                              _isSignedSuccess = true;
                            });
                          }
                        : null,
                    child: _isSigning
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'CONFIRM & SEAL CONTRACT',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context, TwendeContract contract) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F8EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 48, color: Colors.black),
            ),
            const SizedBox(height: 20),
            const Text(
              'Rental Agreement Signed!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0E1B2E)),
            ),
            const SizedBox(height: 8),
            Text(
              'Contract ${contract.contractNumber} is locked and sealed. Your assigned ${contract.vehicleName} (${contract.vehiclePlate}) is ready for pickup at Kigali HQ.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Outstanding Balance:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    MoneyUtils.format(contract.balanceDue),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: contract.balanceDue > 0 ? AppColors.error : Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (contract.balanceDue > 0) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.payment),
                  label: const Text('PROCEED TO MOMO / CARD PAYMENT', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () => context.push('/portal/pay/${contract.id}'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0E1B2E),
                  side: const BorderSide(color: Color(0xFF0E1B2E)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.description_outlined),
                label: const Text('VIEW ALL MY DOCUMENTS', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () => context.push('/portal/documents'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
